import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../providers/browser_provider.dart';
import '../theme/kodair_theme.dart';
import '../utils/native_cursor.dart';

/// Pointer lock hook JS — injected at DOCUMENT_START so it runs before
/// any page scripts can cache the original requestPointerLock.
const String _pointerLockJS = '''
(function() {
  var _lockedElement = null;

  var origRequest = Element.prototype.requestPointerLock;
  Element.prototype.requestPointerLock = function() {
    _lockedElement = this;
    console.log('__PTRLOCK:true');
    Object.defineProperty(document, 'pointerLockElement', {
      get: function() { return _lockedElement; },
      configurable: true
    });
    document.dispatchEvent(new Event('pointerlockchange'));
    if (origRequest) {
      try { origRequest.call(this); } catch(e) {}
    }
    return Promise.resolve();
  };

  var origExit = document.exitPointerLock;
  document.exitPointerLock = function() {
    _lockedElement = null;
    console.log('__PTRLOCK:false');
    Object.defineProperty(document, 'pointerLockElement', {
      get: function() { return null; },
      configurable: true
    });
    document.dispatchEvent(new Event('pointerlockchange'));
    if (origExit) {
      try { origExit.call(document); } catch(e) {}
    }
  };
})();
''';

/// Content viewer using InAppWebView with scroll fix and pointer lock
/// workaround for Windows.
class ContentView extends StatefulWidget {
  final TabState tabState;
  
  const ContentView({super.key, required this.tabState});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  InAppWebViewController? _webViewController;
  String? _lastUrl;
  bool _isLoading = true;
  bool _isPointerLocked = false;
  
  WebViewEnvironment? _webViewEnvironment;
  bool _isEnvLoading = true;
  bool _currentTorState = false;

  @override
  void initState() {
    super.initState();
    // Initialize without context first, we will update in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final browser = context.watch<BrowserProvider>();
    if (_isEnvLoading && _webViewEnvironment == null) {
      _initEnvironment(browser.isTorEnabled);
    } else if (_currentTorState != browser.isTorEnabled) {
      _initEnvironment(browser.isTorEnabled);
    }
  }

  Future<void> _initEnvironment(bool useTor) async {
    // If we're changing environments, clear the old controller
    _webViewController = null;
    if (mounted) setState(() => _isEnvLoading = true);
    
    WebViewEnvironment? env;
    
    // WebViewEnvironment is primarily for Desktop platforms (WebView2 / WebKit)
    // On mobile/web, InAppWebView manages its own environment automatically.
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      if (useTor) {
        // Create isolated Tor environment with proxy
        env = await WebViewEnvironment.create(
          settings: WebViewEnvironmentSettings(
            userDataFolder: 'Browser_Tor_Data',
            additionalBrowserArguments: '--proxy-server="socks5://127.0.0.1:9050"',
          ),
        );
      } else {
        // Default environment
        env = await WebViewEnvironment.create(
          settings: WebViewEnvironmentSettings(userDataFolder: 'Browser_Default_Data'),
        );
      }
    }

    if (mounted) {
      setState(() {
        _webViewEnvironment = env;
        _isEnvLoading = false;
        _currentTorState = useTor;
      });
    }
  }

  @override
  void dispose() {
    // Always restore cursor on dispose
    if (_isPointerLocked) {
      NativeCursor.show();
    }
    super.dispose();
  }

  void _setPointerLock(bool locked) {
    if (_isPointerLocked == locked) return;
    _isPointerLocked = locked;
    if (locked) {
      NativeCursor.hide();
    } else {
      NativeCursor.show();
    }
    if (mounted) setState(() {});
  }

  void _forwardScroll(double dx, double dy) {
    if (_webViewController == null) return;
    _webViewController!.evaluateJavascript(source: '''
(function() {
  window.scrollBy({left: $dx, top: $dy, behavior: 'auto'});
  document.documentElement.scrollTop += $dy;
  document.documentElement.scrollLeft += $dx;
  document.body.scrollTop += $dy;
  document.body.scrollLeft += $dx;
  var cx = window.innerWidth / 2;
  var cy = window.innerHeight / 2;
  var el = document.elementFromPoint(cx, cy);
  while (el) {
    var style = window.getComputedStyle(el);
    var overflowY = style.overflowY;
    if ((overflowY === 'auto' || overflowY === 'scroll') && el.scrollHeight > el.clientHeight) {
      el.scrollTop += $dy;
      break;
    }
    el = el.parentElement;
  }
})();
''');
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final browser = context.watch<BrowserProvider>();

    // Navigate when URL changes
    if (_webViewController != null && _lastUrl != widget.tabState.currentAppUrl) {
      _lastUrl = widget.tabState.currentAppUrl;
      if (_isPointerLocked) {
        _setPointerLock(false);
      }
      _webViewController!.loadUrl(
        urlRequest: URLRequest(url: WebUri(widget.tabState.currentAppUrl)),
      );
    }

    return Stack(
      children: [
        Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent && !_isPointerLocked) {
              _forwardScroll(event.scrollDelta.dx, event.scrollDelta.dy);
            }
          },
            child: GestureDetector(
              onVerticalDragUpdate: (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux) && !_isPointerLocked)
                  ? (details) {
                      _forwardScroll(0, -details.delta.dy * 2);
                    }
                  : null,
              behavior: HitTestBehavior.translucent,
              child: _isEnvLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(KodairTheme.torPurple),
                      ),
                    )
                  : InAppWebView(
                      key: ValueKey(_currentTorState),
                      webViewEnvironment: _webViewEnvironment,
                      initialUrlRequest: URLRequest(
                        url: WebUri(widget.tabState.currentAppUrl),
                      ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  allowsInlineMediaPlayback: true,
                  mediaPlaybackRequiresUserGesture: widget.tabState.currentAppUrl.contains('youtube.com/shorts') ? false : context.read<BrowserProvider>().isAutoplayBlocked,
                  allowsBackForwardNavigationGestures: true,
                  transparentBackground: true,
                  supportZoom: true,
                  useWideViewPort: true,
                  verticalScrollBarEnabled: true,
                  horizontalScrollBarEnabled: true,
                ),
                // Inject pointer lock hook BEFORE any page scripts run
                initialUserScripts: UnmodifiableListView([
                  UserScript(
                    source: _pointerLockJS,
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                  ),
                ]),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  widget.tabState.webViewController = controller;
                  _lastUrl = widget.tabState.currentAppUrl;
                },
                onLoadStart: (controller, url) {
                  if (mounted) setState(() => _isLoading = true);
                  
                  if (url != null) {
                    bool shouldBlock = context.read<BrowserProvider>().isAutoplayBlocked;
                    if (url.toString().contains('youtube.com/shorts')) {
                      shouldBlock = false;
                    }
                    controller.setSettings(settings: InAppWebViewSettings(
                      mediaPlaybackRequiresUserGesture: shouldBlock,
                    ));
                  }
                },
                onLoadStop: (controller, url) async {
                  if (!_isEnvLoading && mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                    final browser = context.read<BrowserProvider>();
                    browser.activeTab.updateHistory(url.toString(), '');

                    // Inline Auto-Play Block for YouTube
                    if (url.toString().contains('youtube.com')) {
                      controller.evaluateJavascript(source: '''
                        setInterval(() => {
                          if (!window.location.href.includes('/watch')) {
                            document.querySelectorAll('video').forEach(v => v.pause());
                          }
                        }, 500);
                      ''');
                    }

                    // Inject OpenWidget on the Welcome page
                    final urlStr = url?.toString() ?? '';
                    if (urlStr.contains('Welcome')) {
                      await controller.evaluateJavascript(source: '''
(function() {
  if (window.OpenWidget) return;
  window.__ow = window.__ow || {};
  window.__ow.organizationId = "d22ade09-9a15-40b4-b6e3-1efe8fe15e61";
  window.__ow.integration_name = "manual_settings";
  window.__ow.product_name = "openwidget";
  var s = document.createElement("script");
  s.async = true;
  s.type = "text/javascript";
  s.src = "https://cdn.openwidget.com/openwidget.js";
  document.head.appendChild(s);
})();
''');
                    }
                  }
                },
                onReceivedError: (controller, request, error) {
                  if (mounted) setState(() => _isLoading = false);
                },
                onPermissionRequest: (controller, request) async {
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
                // Detect pointer lock signals from JS
                onConsoleMessage: (controller, consoleMessage) {
                  final msg = consoleMessage.message;
                  if (msg == '__PTRLOCK:true') {
                    _setPointerLock(true);
                  } else if (msg == '__PTRLOCK:false') {
                    _setPointerLock(false);
                  }
                },
              ),
            ),
          ),

        // ===== LOADING INDICATOR =====
        if (_isLoading)
          const IgnorePointer(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90D9)),
                strokeWidth: 2,
              ),
            ),
          ),

        // ===== TOR BADGE =====
        if (browser.isTorEnabled)
          Positioned(
            top: 8,
            right: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: KodairTheme.torPurple.withAlpha(200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.security, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Tor',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

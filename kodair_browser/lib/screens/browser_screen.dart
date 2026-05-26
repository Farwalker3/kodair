import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../providers/browser_provider.dart';
import '../providers/sidebar_provider.dart';
import '../providers/edition_provider.dart';
import '../theme/kodair_theme.dart';
import '../widgets/kod_bar.dart';
import '../widgets/content_view.dart';
import '../widgets/info_panel.dart';
import '../widgets/settings_panel.dart';
import '../widgets/accounts_panel.dart';
import '../widgets/trails_manager.dart';
import '../widgets/search_overlay.dart';
import '../widgets/download_overlay.dart';
import '../widgets/mobile_bottom_bar.dart';
import '../widgets/ai_agent_panel.dart';
import '../widgets/extension_toolbar.dart';
import '../widgets/share_panel.dart';

class BrowserScreen extends StatelessWidget {
  const BrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final browser = context.watch<BrowserProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final sidebarWidth = browser.isSidebarCollapsed ? 0.0 : 95.0;
    final panelWidth = isMobile
        ? screenWidth - sidebarWidth
        : (screenWidth - sidebarWidth) * 0.35;

    return Scaffold(
      body: Stack(
        children: [
          // ===== ANIMATED GRADIENT BACKGROUND (full screen) =====
          // IgnorePointer ensures mouse events pass through to WebView
          const IgnorePointer(child: _AnimatedGradientBg()),
          const IgnorePointer(child: _FloatingCircles()),

          // ===== MAIN LAYOUT =====
          SafeArea(
            bottom: false,
            top: !isMobile,
            child: Column(
              children: [
                // Mobile Top Status Bar Header (Edge-To-Edge safe)
                if (isMobile) ...[
                  Container(
                    color: KodairTheme.appBarBg,
                    width: double.infinity,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(browser.currentAppName.isEmpty ? 'Kodair WebOS' : browser.currentAppName, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                            Expanded(child: Text('  ${browser.currentAppUrl.replaceAll('https://', '').replaceAll('http://', '')}', style: const TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (browser.extensionToolbarItems.isNotEmpty)
                    Container(
                      color: KodairTheme.sizeBarBg,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: const ExtensionToolbar(compact: true),
                    ),
                ],

                // Custom window title bar with ALL controls (hidden on mobile)
                _buildCustomTitleBar(context, browser),

                // Sidebar + Content
                Expanded(
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: browser.isSidebarCollapsed ? 0 : 95,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(),
                        child: const KodBar(),
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: browser.activeTabIndex,
                          children: <Widget>[
                            for (final tab in browser.tabs)
                              ContentView(tabState: tab),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom WebOS Bar (Mobile Only)
                if (isMobile)
                  Offstage(
                    offstage: isLandscape,
                    child: const MobileBottomBar(),
                  ),
              ],
            ),
          ),

          // ===== OVERLAY PANELS =====
          if (browser.isInfoPanelOpen)
            isMobile
                ? Positioned.fill(
                    child: Container(
                      color: KodairTheme.sizeBarBg,
                      child: SafeArea(
                        child: Stack(
                          children: [
                            const InfoPanel(),
                            Positioned(top: 8, right: 8, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => browser.togglePanel(PanelType.info))),
                          ],
                        ),
                      ),
                    ),
                  )
                : Positioned(
                    left: sidebarWidth,
                    top: kIsWeb || (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) ? 0 : 32,
                    bottom: 0,
                    width: panelWidth,
                    child: const InfoPanel(),
                  ),
          if (browser.isSettingsPanelOpen)
            isMobile
                ? Positioned.fill(
                    child: Container(
                      color: KodairTheme.sizeBarBg,
                      child: SafeArea(
                        child: Stack(
                          children: [
                            const SettingsPanel(),
                            Positioned(top: 8, right: 8, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => browser.togglePanel(PanelType.settings))),
                          ],
                        ),
                      ),
                    ),
                  )
                : Positioned(
                    left: sidebarWidth,
                    top: kIsWeb || (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) ? 0 : 32,
                    bottom: 0,
                    width: panelWidth,
                    child: const SettingsPanel(),
                  ),
          if (browser.isAccountsPanelOpen)
            isMobile
                ? Positioned.fill(
                    child: Container(
                      color: KodairTheme.sizeBarBg,
                      child: SafeArea(
                        child: Stack(
                          children: [
                            const AccountsPanel(),
                            Positioned(top: 8, right: 8, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => browser.togglePanel(PanelType.accounts))),
                          ],
                        ),
                      ),
                    ),
                  )
                : Positioned(
                    left: sidebarWidth,
                    top: kIsWeb || (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) ? 0 : 32,
                    bottom: 0,
                    width: panelWidth,
                    child: const AccountsPanel(),
                  ),
          if (browser.isAiAgentPanelOpen)
            isMobile
                ? Positioned.fill(
                    child: Container(
                      color: const Color(0xF0101020),
                      child: SafeArea(
                        child: Stack(
                          children: [
                            const AiAgentPanel(),
                            Positioned(top: 8, right: 8, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => browser.togglePanel(PanelType.aiAgent))),
                          ],
                        ),
                      ),
                    ),
                  )
                : Positioned(
                    left: sidebarWidth,
                    top: kIsWeb || (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) ? 0 : 32,
                    bottom: 0,
                    width: panelWidth,
                    child: const AiAgentPanel(),
                  ),
          if (browser.isSharePanelOpen)
            isMobile
                ? Positioned.fill(
                    child: Container(
                      color: const Color(0xF0101020),
                      child: SafeArea(
                        child: Stack(
                          children: [
                            const SharePanel(),
                            Positioned(top: 8, right: 8, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => browser.togglePanel(PanelType.share))),
                          ],
                        ),
                      ),
                    ),
                  )
                : Positioned(
                    left: sidebarWidth,
                    top: kIsWeb || (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) ? 0 : 32,
                    bottom: 0,
                    width: panelWidth,
                    child: const SharePanel(),
                  ),
          if (browser.isTrailsOpen)
            isMobile
                ? Positioned.fill(
                    child: Container(
                      color: KodairTheme.sizeBarBg,
                      child: SafeArea(
                        child: Stack(
                          children: [
                            const TrailsManager(),
                          ],
                        ),
                      ),
                    ),
                  )
                : Positioned(
                    left: sidebarWidth,
                    top: kIsWeb || (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) ? 0 : 32,
                    bottom: 0,
                    width: panelWidth,
                    child: const TrailsManager(),
                  ),

          // ===== SEARCH OVERLAY =====
          if (browser.isSearchOpen) const SearchOverlay(),
          if (browser.isAliasVaultOverlayOpen) const _AliasVaultOverlay(),
          const DownloadOverlay(),
          const ExtensionPopupOverlay(),
        ],
      ),
    );
  }

  /// Custom title bar with ALL navigation controls merged in, PLUS TABS!
  Widget _buildCustomTitleBar(BuildContext context, BrowserProvider browser) {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      return const SizedBox.shrink(); // Hide desktop custom title bar on mobile
    }

    return Container(
      height: 32,
      color: KodairTheme.sizeBarBg,
      child: Row(
        children: [
          _TitleBarBtn(
            icon: browser.isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
            hoverColor: KodairTheme.primaryBlue,
            onTap: () => browser.toggleSidebar(),
            tooltip: browser.isSidebarCollapsed ? 'Show Sidebar' : 'Hide Sidebar',
          ),

          // --- LEFT: Navigation controls ---
          _TitleBarBtn(icon: Icons.close, hoverColor: KodairTheme.closeRed, onTap: () => browser.goHome(), tooltip: 'Home'),
          _TitleBarBtn(icon: Icons.refresh, hoverColor: KodairTheme.refreshYellow, onTap: () => browser.navigateToApp(browser.currentAppUrl), tooltip: 'Refresh'),
          _TitleBarBtn(icon: Icons.fullscreen, hoverColor: KodairTheme.fullscreenGreen, onTap: () => appWindow.maximizeOrRestore(), tooltip: 'Fullscreen'),
          _TitleBarBtn(icon: Icons.arrow_back, hoverColor: KodairTheme.backBlue, onTap: browser.canGoBack ? () => browser.goBack() : null, tooltip: 'Back'),
          _TitleBarBtn(icon: Icons.arrow_forward, hoverColor: KodairTheme.forwardCyan, onTap: browser.canGoForward ? () => browser.goForward() : null, tooltip: 'Forward'),

          const SizedBox(width: 8),

          // --- CENTER: TABS ---
          Expanded(
            child: MoveWindow(
              child: Row(
                children: [
                  // Scrollable Tab List
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: browser.tabs.length,
                      itemBuilder: (context, index) {
                        return _buildTab(context, browser, index);
                      },
                    ),
                  ),
                  
                  // Add Tab Button
                  if (browser.tabs.length < 3)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Tooltip(
                        message: 'New Tab',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => browser.addTab('https://kodair.us/Welcome/Welcome.html', 'Welcome'),
                            hoverColor: Colors.white12,
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.add, size: 16, color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(
            width: 260,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ExtensionToolbar(compact: false),
            ),
          ),

          // --- RIGHT: Window management buttons ---
          MinimizeWindowButton(
            colors: WindowButtonColors(
              iconNormal: Colors.white70,
              mouseOver: Colors.white24,
              mouseDown: Colors.white12,
            ),
          ),
          MaximizeWindowButton(
            colors: WindowButtonColors(
              iconNormal: Colors.white70,
              mouseOver: Colors.white24,
              mouseDown: Colors.white12,
            ),
          ),
          CloseWindowButton(
            colors: WindowButtonColors(
              iconNormal: Colors.white70,
              mouseOver: const Color(0xFFD32F2F),
              mouseDown: const Color(0xFFB71C1C),
              iconMouseOver: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, BrowserProvider browser, int index) {
    final tab = browser.tabs[index];
    final isActive = index == browser.activeTabIndex;

    return _EditableTab(
      key: ObjectKey(tab),
      tab: tab,
      isActive: isActive,
      onActivate: () => browser.setActiveTab(index),
      onSubmit: (value) {
        final target = _tabTargetForInput(value);
        browser.setActiveTab(index);
        browser.navigateToApp(target, name: value.trim());
      },
      onSecondaryTapDown: (details) => _showTabContextMenu(context, details.globalPosition, browser, index),
      showCloseButton: browser.tabs.length > 1,
      onClose: () => browser.closeTab(index),
    );
  }

  void _showTabContextMenu(BuildContext context, Offset position, BrowserProvider browser, int tabIndex) {
    final tab = browser.tabs[tabIndex];
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: KodairTheme.appBarBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem(
          onTap: () {
            // Save tab as a custom app in the sidebar via SidebarProvider
            context.read<SidebarProvider>().addApp(
              name: tab.currentAppName,
              url: tab.currentAppUrl,
            );
          },
          child: const Row(
            children: [
              Icon(Icons.save_alt, size: 18, color: Colors.white70),
              SizedBox(width: 8),
              Text('Save Tab as App', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        if (browser.tabs.length > 1)
          const PopupMenuDivider(height: 1),
        if (browser.tabs.length > 1)
          PopupMenuItem(
            onTap: () => browser.closeTab(tabIndex),
            child: const Row(
              children: [
                Icon(Icons.close, size: 18, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Close Tab', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }
}

String _tabTargetForInput(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return 'https://kodair.us/Welcome/Welcome.html';

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) {
    return trimmed;
  }

  if (!trimmed.contains(RegExp(r'\s')) && trimmed.contains('.')) {
    return 'https://$trimmed';
  }

  return 'https://www.google.com/search?q=${Uri.encodeComponent(trimmed)}';
}

class _EditableTab extends StatefulWidget {
  final TabState tab;
  final bool isActive;
  final VoidCallback onActivate;
  final ValueChanged<String> onSubmit;
  final GestureTapDownCallback onSecondaryTapDown;
  final bool showCloseButton;
  final VoidCallback onClose;

  const _EditableTab({
    super.key,
    required this.tab,
    required this.isActive,
    required this.onActivate,
    required this.onSubmit,
    required this.onSecondaryTapDown,
    required this.showCloseButton,
    required this.onClose,
  });

  @override
  State<_EditableTab> createState() => _EditableTabState();
}

class _EditableTabState extends State<_EditableTab> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tab.currentAppName);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _EditableTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.tab.currentAppName != widget.tab.currentAppName && _controller.text != widget.tab.currentAppName) {
      _controller.text = widget.tab.currentAppName;
    }
    if (!widget.isActive && _editing) {
      _editing = false;
      _focusNode.unfocus();
      _controller.text = widget.tab.currentAppName;
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _editing) {
      setState(() {
        _editing = false;
        _controller.text = widget.tab.currentAppName;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _beginEditing() {
    widget.onActivate();
    setState(() {
      _editing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      _focusNode.requestFocus();
    });
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() {
        _editing = false;
        _controller.text = widget.tab.currentAppName;
      });
      _focusNode.unfocus();
      return;
    }

    widget.onSubmit(value);
    setState(() {
      _editing = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isActive ? Colors.white.withAlpha(100) : Colors.white.withAlpha(20);
    final backgroundColor = _editing
        ? Colors.white.withAlpha(50)
        : widget.isActive
            ? Colors.white.withAlpha(40)
            : Colors.white.withAlpha(10);

    return GestureDetector(
      onTap: _beginEditing,
      onSecondaryTapDown: widget.onSecondaryTapDown,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 140,
        margin: const EdgeInsets.only(right: 2, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: widget.isActive || _editing ? 1 : 0),
          boxShadow: _editing
              ? [BoxShadow(color: Colors.blue.withAlpha(60), blurRadius: 8, spreadRadius: 1)]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: _editing
                  ? TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      onSubmitted: (_) => _submit(),
                      textInputAction: TextInputAction.go,
                      keyboardType: TextInputType.url,
                      cursorColor: Colors.white,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Search or enter address',
                        hintStyle: TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    )
                  : Text(
                      widget.tab.currentAppName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                        color: widget.isActive ? Colors.white : Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            if (widget.showCloseButton)
              InkWell(
                onTap: widget.onClose,
                hoverColor: Colors.red.withAlpha(150),
                borderRadius: BorderRadius.circular(10),
                child: const Icon(Icons.close, size: 12, color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }
}


/// AliasVault overlay shown when a password field is detected.
class _AliasVaultOverlay extends StatefulWidget {
  const _AliasVaultOverlay();

  @override
  State<_AliasVaultOverlay> createState() => _AliasVaultOverlayState();
}

class _AliasVaultOverlayState extends State<_AliasVaultOverlay> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    final browser = context.watch<BrowserProvider>();
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(160),
        child: SafeArea(
          child: Center(
            child: Container(
              width: isMobile ? double.infinity : 980,
              height: isMobile ? double.infinity : 720,
              margin: isMobile ? EdgeInsets.zero : const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withAlpha(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 24, offset: const Offset(0, 12)),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(18),
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(url: WebUri(browser.aliasVaultUrl)),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        domStorageEnabled: true,
                        allowsInlineMediaPlayback: true,
                        allowsBackForwardNavigationGestures: true,
                        transparentBackground: false,
                        supportZoom: true,
                        useWideViewPort: true,
                      ),
                      onLoadStart: (_, __) {
                        if (mounted) setState(() => _isLoading = true);
                      },
                      onLoadStop: (_, __) {
                        if (mounted) setState(() => _isLoading = false);
                      },
                      onReceivedError: (_, __, ___) {
                        if (mounted) setState(() => _isLoading = false);
                      },
                      onPermissionRequest: (controller, request) async {
                        return PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.GRANT,
                        );
                      },
                    ),
                  ),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(KodairTheme.primaryBlue),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Tooltip(
                      message: 'Close AliasVault',
                      child: IconButton(
                        onPressed: browser.closeAliasVaultOverlay,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    right: 56,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AliasVault',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (browser.aliasVaultSourceUrl != null)
                          Text(
                            browser.aliasVaultSourceUrl!,
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hover button for the title bar
class _TitleBarBtn extends StatefulWidget {
  final IconData icon;
  final Color hoverColor;
  final VoidCallback? onTap;
  final String? tooltip;

  const _TitleBarBtn({
    required this.icon,
    required this.hoverColor,
    this.onTap,
    this.tooltip,
  });

  @override
  State<_TitleBarBtn> createState() => _TitleBarBtnState();
}

class _TitleBarBtnState extends State<_TitleBarBtn> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip ?? '',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hovering
                  ? widget.hoverColor
                  : KodairTheme.sizeActionBg.withAlpha(80),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: 14,
                color: _hovering ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ===== ANIMATED GRADIENT BACKGROUND =====
class _AnimatedGradientBg extends StatefulWidget {
  const _AnimatedGradientBg();

  @override
  State<_AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<_AnimatedGradientBg>
    with TickerProviderStateMixin {
  late AnimationController _bg1, _bg2, _bg3;

  @override
  void initState() {
    super.initState();
    _bg1 = AnimationController(
        duration: const Duration(seconds: 7), vsync: this)
      ..repeat(reverse: true);
    _bg2 = AnimationController(
        duration: const Duration(seconds: 4), vsync: this)
      ..repeat(reverse: true);
    _bg3 = AnimationController(
        duration: const Duration(seconds: 5), vsync: this)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bg1.dispose();
    _bg2.dispose();
    _bg3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editionConfig = context.watch<EditionProvider>().config;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [editionConfig.backgroundTop, editionConfig.backgroundBottom],
        ),
      ),
      child: Stack(
        children: [
          _bgLayer(_bg1, -60),
          _bgLayer(_bg2, -45),
          _bgLayer(_bg3, -75),
        ],
      ),
    );
  }

  Widget _bgLayer(AnimationController ctrl, double angleDeg) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final eConfig = context.watch<EditionProvider>().config;
        final offset =
            Tween<double>(begin: -0.25, end: 0.25).animate(ctrl).value;
        return Positioned.fill(
          child: Transform.translate(
            offset:
                Offset(MediaQuery.of(context).size.width * offset, 0),
            child: Opacity(
              opacity: 0.15,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [eConfig.backgroundTop.withAlpha(180), eConfig.backgroundBottom.withAlpha(180)],
                    transform:
                        GradientRotation(angleDeg * 3.14159 / 180),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===== FLOATING CIRCLES =====
class _FloatingCircles extends StatefulWidget {
  const _FloatingCircles();

  @override
  State<_FloatingCircles> createState() => _FloatingCirclesState();
}

class _FloatingCirclesState extends State<_FloatingCircles>
    with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;

  static const _data = [
    (left: 0.25, size: 80.0, dur: 25, delay: 0),
    (left: 0.10, size: 20.0, dur: 12, delay: 2),
    (left: 0.70, size: 20.0, dur: 25, delay: 4),
    (left: 0.40, size: 60.0, dur: 18, delay: 0),
    (left: 0.65, size: 20.0, dur: 25, delay: 0),
    (left: 0.75, size: 110.0, dur: 25, delay: 3),
    (left: 0.35, size: 150.0, dur: 25, delay: 7),
    (left: 0.50, size: 25.0, dur: 45, delay: 15),
    (left: 0.20, size: 15.0, dur: 35, delay: 2),
    (left: 0.85, size: 150.0, dur: 11, delay: 0),
  ];

  @override
  void initState() {
    super.initState();
    _ctrls = _data
        .map((d) => AnimationController(
            duration: Duration(seconds: d.dur), vsync: this))
        .toList();
    for (int i = 0; i < _data.length; i++) {
      Future.delayed(Duration(seconds: _data[i].delay), () {
        if (mounted) _ctrls[i].repeat();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    return Stack(
      children: List.generate(_data.length, (i) {
        final d = _data[i];
        return AnimatedBuilder(
          animation: _ctrls[i],
          builder: (_, child) {
            final t = _ctrls[i].value;
            final y = 1.1 - t * 1.4; // bottom to top
            return Positioned(
              left: w * d.left - d.size / 2,
              top: h * y,
              child: Opacity(
                opacity: ((1.0 - t) * 0.3).clamp(0.0, 0.3),
                child: Transform.rotate(
                  angle: t * 12.566,
                  child: Container(
                    width: d.size,
                    height: d.size,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius:
                          BorderRadius.circular(d.size * t * 0.5),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}


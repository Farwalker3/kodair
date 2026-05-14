import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/browser_extension_item.dart';
import '../services/native_extension_service.dart';
import '../services/tor_service.dart';

enum PanelType { info, settings, accounts, aiAgent }

enum BrowserEngine { standard, geckoview, webview2 }

String browserEngineLabel(BrowserEngine engine) {
  switch (engine) {
    case BrowserEngine.standard:
      return "Standard";
    case BrowserEngine.geckoview:
      return "GeckoView";
    case BrowserEngine.webview2:
      return "WebView2";
  }
}

class TabState extends ChangeNotifier {
  String currentAppUrl;
  String currentAppName;
  List<String> history;
  int historyIndex;

  InAppWebViewController? webViewController;

  TabState({
    this.currentAppUrl = 'https://kodair.us/Welcome/Welcome.html',
    this.currentAppName = 'Welcome',
    List<String>? initialHistory,
  })  : history = initialHistory ?? ['https://kodair.us/Welcome/Welcome.html'],
        historyIndex = 0;

  Map<String, dynamic> toJson() => {
        'currentAppUrl': currentAppUrl,
        'currentAppName': currentAppName,
        'history': history,
        'historyIndex': historyIndex,
      };

  factory TabState.fromJson(Map<String, dynamic> json) {
    return TabState(
      currentAppUrl: json['currentAppUrl'] as String? ?? 'https://kodair.us/Welcome/Welcome.html',
      currentAppName: json['currentAppName'] as String? ?? 'Welcome',
      initialHistory: (json['history'] as List<dynamic>?)?.cast<String>(),
    )..historyIndex = json['historyIndex'] as int? ?? 0;
  }

  bool get canGoBack => historyIndex > 0;
  bool get canGoForward => historyIndex < history.length - 1;

  void navigate(String url, String name) {
    if (historyIndex < history.length - 1) {
      history = history.sublist(0, historyIndex + 1);
    }
    currentAppUrl = url;
    currentAppName = name;
    history.add(url);
    historyIndex = history.length - 1;
    notifyListeners();
  }

  void updateHistory(String url, String name) {
    if (currentAppUrl == url) return;
    if (historyIndex < history.length - 1) {
      history = history.sublist(0, historyIndex + 1);
    }
    currentAppUrl = url;
    if (name.isNotEmpty) currentAppName = name;
    if (history.isEmpty || history.last != url) {
      history.add(url);
      historyIndex = history.length - 1;
    }
  }

  void goBack() {
    if (canGoBack) {
      historyIndex--;
      currentAppUrl = history[historyIndex];
      notifyListeners();
    }
  }

  void goForward() {
    if (canGoForward) {
      historyIndex++;
      currentAppUrl = history[historyIndex];
      notifyListeners();
    }
  }
}

class BrowserProvider extends ChangeNotifier {
  // Tab Management
  final List<TabState> _tabs = [];
  int _activeTabIndex = 0;

  BrowserProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tabsJson = prefs.getString('saved_tabs');
      if (tabsJson != null) {
        final List<dynamic> decoded = jsonDecode(tabsJson);
        final loadedTabs = decoded.map((t) => TabState.fromJson(t as Map<String, dynamic>)).toList();
        if (loadedTabs.isNotEmpty) {
          _tabs.addAll(loadedTabs);
          _activeTabIndex = prefs.getInt('active_tab_index') ?? 0;
          if (_activeTabIndex >= _tabs.length) _activeTabIndex = _tabs.length - 1;
        }
      }
      _isSidebarCollapsed = prefs.getBool('isSidebarCollapsed') ?? false;
      _isTorEnabled = prefs.getBool('tor_enabled') ?? false;
      _isGhosteryEnabled = prefs.getBool('isGhosteryEnabled') ?? false;
      _isAliasVaultEnabled = prefs.getBool('isAliasVaultEnabled') ?? false;
      _isProEngineEnabled = prefs.getBool('isProEngineEnabled') ?? false;
      final storedEngine = prefs.getString('browserEngine');
      if (storedEngine != null) {
        try {
          _activeEngine = BrowserEngine.values.byName(storedEngine);
        } catch (_) {
          _activeEngine = BrowserEngine.standard;
        }
      }
      if (_activeEngine != BrowserEngine.standard) {
        _isProEngineEnabled = true;
      }
      final nativeExtensionsJson = prefs.getString('nativeExtensions');
      if (nativeExtensionsJson != null) {
        final decodedExtensions = jsonDecode(nativeExtensionsJson) as List<dynamic>;
        _nativeExtensions.addAll(
          decodedExtensions
              .map((entry) => BrowserExtensionItem.fromJson(Map<String, dynamic>.from(entry as Map)))
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('Error loading tabs: $e');
    }

    if (_tabs.isEmpty) {
      _tabs.add(TabState());
    }

    for (var tab in _tabs) {
      tab.addListener(_onTabUpdated);
    }
    notifyListeners();
  }

  void _onTabUpdated() {
    notifyListeners();
    _saveState();
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedTabs = jsonEncode(_tabs.map((t) => t.toJson()).toList());
      await prefs.setString('saved_tabs', encodedTabs);
      await prefs.setInt('active_tab_index', _activeTabIndex);
      await prefs.setBool('isTorEnabled', _isTorEnabled);
      await prefs.setBool('isAutoplayBlocked', _isAutoplayBlocked);
      await prefs.setBool('isSidebarCollapsed', _isSidebarCollapsed);
      await prefs.setBool('isGhosteryEnabled', _isGhosteryEnabled);
      await prefs.setBool('isAliasVaultEnabled', _isAliasVaultEnabled);
      await prefs.setBool('isProEngineEnabled', _isProEngineEnabled);
      await prefs.setString('browserEngine', _activeEngine.name);
      await prefs.setString('nativeExtensions', jsonEncode(_nativeExtensions.map((item) => item.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving tabs: $e');
    }
  }

  List<TabState> get tabs => _tabs;
  int get activeTabIndex => _activeTabIndex;
  TabState get activeTab => _tabs.isEmpty ? TabState() : _tabs[_activeTabIndex];

  // Global State
  bool _isInfoPanelOpen = false;
  bool _isSettingsPanelOpen = false;
  bool _isAccountsPanelOpen = false;
  bool _isAiAgentPanelOpen = false;
  bool _isSearchOpen = false;
  bool _isTrailsOpen = false;
  bool _isTorEnabled = false;
  bool _isAutoplayBlocked = true;
  bool _isSidebarCollapsed = false;
  bool _isGhosteryEnabled = false;
  bool _isAliasVaultEnabled = false;
  bool _isProEngineEnabled = false;
  BrowserEngine _activeEngine = BrowserEngine.standard;
  bool _isAliasVaultOverlayOpen = false;
  String _aliasVaultUrl = 'https://app.aliasvault.net';
  String? _aliasVaultSourceUrl;
  bool _torRequiresRestart = false;
  final List<BrowserExtensionItem> _nativeExtensions = [];
  String? _activeExtensionPopupId;

  // Getters for active tab wrappers
  String get currentAppUrl => activeTab.currentAppUrl;
  String get currentAppName => activeTab.currentAppName;
  bool get canGoBack => activeTab.canGoBack;
  bool get canGoForward => activeTab.canGoForward;

  // Global Getters
  bool get isInfoPanelOpen => _isInfoPanelOpen;
  bool get isSettingsPanelOpen => _isSettingsPanelOpen;
  bool get isAccountsPanelOpen => _isAccountsPanelOpen;
  bool get isAccountsOpen => isAccountsPanelOpen;
  bool get isAiAgentPanelOpen => _isAiAgentPanelOpen;
  bool get isSearchOpen => _isSearchOpen;
  bool get isTrailsOpen => _isTrailsOpen;
  bool get isTorEnabled => _isTorEnabled;
  bool get isAutoplayBlocked => _isAutoplayBlocked;
  bool get isSidebarCollapsed => _isSidebarCollapsed;
  bool get isGhosteryEnabled => _isGhosteryEnabled;
  bool get isAliasVaultEnabled => _isAliasVaultEnabled;
  bool get isProEngineEnabled => _isProEngineEnabled;
  BrowserEngine get activeEngine => _activeEngine;
  String get activeEngineLabel => browserEngineLabel(_activeEngine);
  bool get isAliasVaultOverlayOpen => _isAliasVaultOverlayOpen;
  String get aliasVaultUrl => _aliasVaultUrl;
  String? get aliasVaultSourceUrl => _aliasVaultSourceUrl;
  bool get torRequiresRestart => _torRequiresRestart;
  String? get activeExtensionPopupId => _activeExtensionPopupId;

  BrowserExtensionItem? get activeExtensionPopup {
    final activeId = _activeExtensionPopupId;
    if (activeId == null) return null;
    for (final item in extensionToolbarItems) {
      if (item.id == activeId) return item;
    }
    return null;
  }

  List<BrowserExtensionItem> get extensionToolbarItems {
    final items = <BrowserExtensionItem>[
      BrowserExtensionItem(
        id: 'ghostery',
        name: 'Ghostery',
        icon: Icons.shield_outlined,
        enabled: _isGhosteryEnabled,
        isBuiltIn: true,
        description: 'Ghostery content controls and ad blocking are wired into the native browser surface.',
        nativeEngine: 'geckoview/webview2',
      ),
      BrowserExtensionItem(
        id: 'aliasvault',
        name: 'AliasVault',
        icon: Icons.key_outlined,
        enabled: _isAliasVaultEnabled,
        isBuiltIn: true,
        description: 'AliasVault detection opens a native credential flow when password fields appear.',
        nativeEngine: 'geckoview/webview2',
      ),
    ];

    items.addAll(_nativeExtensions);
    return List.unmodifiable(items);
  }

  void toggleTrails() {
    _isTrailsOpen = !_isTrailsOpen;
    if (_isTrailsOpen) {
      _isSearchOpen = false;
      _isAccountsPanelOpen = false;
      _isInfoPanelOpen = false;
      _isSettingsPanelOpen = false;
      _isSidebarCollapsed = true;
    }
    notifyListeners();
  }

  /// Add a new tab (Max 3)
  void addTab(String url, String name) {
    if (_tabs.length >= 3) return; // Enforce max 3 tabs
    
    final newTab = TabState(
      currentAppUrl: url,
      currentAppName: name,
      initialHistory: [url],
    );
    _tabs.add(newTab);
    _activeTabIndex = _tabs.length - 1; // Auto-switch to new tab
    
    // Listen to changes in the new tab so the UI updates
    newTab.addListener(_onTabUpdated);
    _closeAllPanels();
    _onTabUpdated();
  }

  /// Close a specific tab by index
  void closeTab(int index) {
    if (_tabs.length <= 1) return; // Keep at least 1 tab open
    
    final closingTab = _tabs[index];
    closingTab.removeListener(_onTabUpdated);
    
    _tabs.removeAt(index);
    if (_activeTabIndex >= _tabs.length) {
      _activeTabIndex = _tabs.length - 1;
    }
    _onTabUpdated();
  }

  /// Switch the active tab
  void setActiveTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _activeTabIndex = index;
      _closeAllPanels();
      _onTabUpdated();
    }
  }

  /// Navigate active tab to a new app/url
  void navigateToApp(String url, {String name = ''}) {
    activeTab.navigate(url, name);
    _closeAllPanels();
    notifyListeners();
  }

  /// Go back in active tab
  void goBack() {
    activeTab.goBack();
  }

  /// Go forward in active tab
  void goForward() {
    activeTab.goForward();
  }

  /// Go home in active tab
  void goHome() {
    navigateToApp('https://kodair.us/Welcome/Welcome.html', name: 'Welcome');
  }

  /// Force UI rebuild (used by plugins/context menus when global registry changes)
  void forceRebuild() {
    notifyListeners();
  }

  /// Toggle a panel open/close
  void togglePanel(PanelType panel) {
    switch (panel) {
      case PanelType.info:
        _isInfoPanelOpen = !_isInfoPanelOpen;
        _isSettingsPanelOpen = false;
        _isAccountsPanelOpen = false;
        _isAiAgentPanelOpen = false;
        break;
      case PanelType.settings:
        _isSettingsPanelOpen = !_isSettingsPanelOpen;
        _isInfoPanelOpen = false;
        _isAccountsPanelOpen = false;
        _isAiAgentPanelOpen = false;
        break;
      case PanelType.accounts:
        _isAccountsPanelOpen = !_isAccountsPanelOpen;
        _isInfoPanelOpen = false;
        _isSettingsPanelOpen = false;
        _isAiAgentPanelOpen = false;
        break;
      case PanelType.aiAgent:
        _isAiAgentPanelOpen = !_isAiAgentPanelOpen;
        _isInfoPanelOpen = false;
        _isSettingsPanelOpen = false;
        _isAccountsPanelOpen = false;
        break;
    }
    notifyListeners();
  }

  /// Toggle search overlay
  void openSearch() {
    _isSearchOpen = true;
    notifyListeners();
  }

  void toggleSearch() {
    _isSearchOpen = !_isSearchOpen;
    notifyListeners();
  }

  void toggleGhostery() async {
    _isGhosteryEnabled = !_isGhosteryEnabled;
    await _saveState();
    notifyListeners();
  }

  void toggleProEngine() {
    _isProEngineEnabled = !_isProEngineEnabled;
    if (_isProEngineEnabled) {
      if (_activeEngine == BrowserEngine.standard) {
        _activeEngine = BrowserEngine.geckoview;
      }
    } else {
      _activeEngine = BrowserEngine.standard;
    }
    _saveState();
    notifyListeners();
  }

  void setBrowserEngine(BrowserEngine engine) {
    _activeEngine = engine;
    _isProEngineEnabled = engine != BrowserEngine.standard;
    _saveState();
    notifyListeners();
  }

  void toggleAliasVaultBridge() async {
    _isAliasVaultEnabled = !_isAliasVaultEnabled;
    if (!_isAliasVaultEnabled) {
      _isAliasVaultOverlayOpen = false;
      _aliasVaultSourceUrl = null;
    }
    await _saveState();
    notifyListeners();
  }

  void registerNativeExtension(BrowserExtensionItem extension) {
    final index = _nativeExtensions.indexWhere((item) => item.id == extension.id);
    if (index >= 0) {
      _nativeExtensions[index] = extension;
    } else {
      _nativeExtensions.add(extension);
    }
    _saveState();
    notifyListeners();
  }

  void setNativeExtensionEnabled(String id, bool enabled) {
    final index = _nativeExtensions.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _nativeExtensions[index] = _nativeExtensions[index].copyWith(enabled: enabled);
    _saveState();
    notifyListeners();
  }

  void removeNativeExtension(String id) {
    _nativeExtensions.removeWhere((item) => item.id == id);
    if (_activeExtensionPopupId == id) {
      _activeExtensionPopupId = null;
    }
    _saveState();
    notifyListeners();
  }

  void openExtensionPopup(String id) {
    _activeExtensionPopupId = id;
    NativeExtensionService.instance.openExtensionPopup(id, pageUrl: currentAppUrl);
    notifyListeners();
  }

  void closeExtensionPopup() {
    final activeId = _activeExtensionPopupId;
    _activeExtensionPopupId = null;
    if (activeId != null) {
      NativeExtensionService.instance.closeExtensionPopup(activeId);
    }
    notifyListeners();
  }

  void openAliasVaultOverlay({String? sourceUrl}) {
    _aliasVaultSourceUrl = sourceUrl;
    _isAliasVaultOverlayOpen = true;
    notifyListeners();
  }

  void closeAliasVaultOverlay() {
    _isAliasVaultOverlayOpen = false;
    _aliasVaultSourceUrl = null;
    notifyListeners();
  }

  /// Toggle Tor proxy — requires app restart to take effect.
  void toggleTor() {
    _isTorEnabled = !_isTorEnabled;
    _torRequiresRestart = true;
    TorService.saveTorPreference(_isTorEnabled);
    notifyListeners();
  }

  /// Toggle sidebar collapse (all platforms)
  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    _saveState();
    notifyListeners();
  }

  // OpenWidget chat panel
  bool _isOpenWidgetOpen = false;
  bool get isOpenWidgetOpen => _isOpenWidgetOpen;

  void toggleOpenWidget() {
    _isOpenWidgetOpen = !_isOpenWidgetOpen;
    notifyListeners();
  }

  void toggleAutoplayBlocker() async {
    _isAutoplayBlocked = !_isAutoplayBlocked;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAutoplayBlocked', _isAutoplayBlocked);
    notifyListeners();
  }

  void _closeAllPanels() {
    _isInfoPanelOpen = false;
    _isSettingsPanelOpen = false;
    _isAccountsPanelOpen = false;
    _isAiAgentPanelOpen = false;
    _isSearchOpen = false;
    _isAliasVaultOverlayOpen = false;
    _aliasVaultSourceUrl = null;
    _activeExtensionPopupId = null;
  }
}

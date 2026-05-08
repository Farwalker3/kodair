import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

enum PanelType { info, settings, accounts, aiAgent }

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

  // Getters for active tab wrappers
  String get currentAppUrl => activeTab.currentAppUrl;
  String get currentAppName => activeTab.currentAppName;
  bool get canGoBack => activeTab.canGoBack;
  bool get canGoForward => activeTab.canGoForward;

  // Global Getters
  bool get isInfoPanelOpen => _isInfoPanelOpen;
  bool get isSettingsPanelOpen => _isSettingsPanelOpen;
  bool get isAccountsPanelOpen => _isAccountsPanelOpen;
  bool get isAiAgentPanelOpen => _isAiAgentPanelOpen;
  bool get isSearchOpen => _isSearchOpen;
  bool get isTrailsOpen => _isTrailsOpen;
  bool get isTorEnabled => _isTorEnabled;
  bool get isAutoplayBlocked => _isAutoplayBlocked;
  bool get isSidebarCollapsed => _isSidebarCollapsed;

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
  void toggleSearch() {
    _isSearchOpen = !_isSearchOpen;
    notifyListeners();
  }

  /// Toggle Tor proxy
  void toggleTor() {
    _isTorEnabled = !_isTorEnabled;
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
  }
}

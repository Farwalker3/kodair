import 'package:flutter/material.dart';

enum PanelType { info, settings, accounts }

class TabState extends ChangeNotifier {
  String currentAppUrl;
  String currentAppName;
  List<String> history;
  int historyIndex;

  TabState({
    this.currentAppUrl = 'https://kodair.us/Welcome/Welcome.html',
    this.currentAppName = 'Welcome',
    List<String>? initialHistory,
  })  : history = initialHistory ?? ['https://kodair.us/Welcome/Welcome.html'],
        historyIndex = 0;

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
  final List<TabState> _tabs = [TabState()];
  int _activeTabIndex = 0;

  List<TabState> get tabs => _tabs;
  int get activeTabIndex => _activeTabIndex;
  TabState get activeTab => _tabs[_activeTabIndex];

  // Global State
  bool _isInfoPanelOpen = false;
  bool _isSettingsPanelOpen = false;
  bool _isAccountsPanelOpen = false;
  bool _isSearchOpen = false;
  bool _isTorEnabled = false;
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
  bool get isSearchOpen => _isSearchOpen;
  bool get isTorEnabled => _isTorEnabled;
  bool get isSidebarCollapsed => _isSidebarCollapsed;

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
    newTab.addListener(notifyListeners);
    _closeAllPanels();
    notifyListeners();
  }

  /// Close a specific tab by index
  void closeTab(int index) {
    if (_tabs.length <= 1) return; // Keep at least 1 tab open
    
    final closingTab = _tabs[index];
    closingTab.removeListener(notifyListeners);
    
    _tabs.removeAt(index);
    if (_activeTabIndex >= _tabs.length) {
      _activeTabIndex = _tabs.length - 1;
    }
    notifyListeners();
  }

  /// Switch the active tab
  void setActiveTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _activeTabIndex = index;
      _closeAllPanels();
      notifyListeners();
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
        break;
      case PanelType.settings:
        _isSettingsPanelOpen = !_isSettingsPanelOpen;
        _isInfoPanelOpen = false;
        _isAccountsPanelOpen = false;
        break;
      case PanelType.accounts:
        _isAccountsPanelOpen = !_isAccountsPanelOpen;
        _isInfoPanelOpen = false;
        _isSettingsPanelOpen = false;
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

  /// Toggle sidebar collapse (for mobile)
  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  // OpenWidget chat panel
  bool _isOpenWidgetOpen = false;
  bool get isOpenWidgetOpen => _isOpenWidgetOpen;

  void toggleOpenWidget() {
    _isOpenWidgetOpen = !_isOpenWidgetOpen;
    notifyListeners();
  }

  void _closeAllPanels() {
    _isInfoPanelOpen = false;
    _isSettingsPanelOpen = false;
    _isAccountsPanelOpen = false;
    _isSearchOpen = false;
  }
}

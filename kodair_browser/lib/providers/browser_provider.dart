import 'package:flutter/material.dart';

enum PanelType { info, settings, accounts }

class BrowserProvider extends ChangeNotifier {
  String _currentAppUrl = 'https://kodair.us/Welcome/Welcome.html';
  String _currentAppName = 'Welcome';
  bool _isInfoPanelOpen = false;
  bool _isSettingsPanelOpen = false;
  bool _isAccountsPanelOpen = false;
  bool _isSearchOpen = false;
  bool _isTorEnabled = false;
  bool _isSidebarCollapsed = false;
  List<String> _history = ['https://kodair.us/Welcome/Welcome.html'];
  int _historyIndex = 0;

  // Getters
  String get currentAppUrl => _currentAppUrl;
  String get currentAppName => _currentAppName;
  bool get isInfoPanelOpen => _isInfoPanelOpen;
  bool get isSettingsPanelOpen => _isSettingsPanelOpen;
  bool get isAccountsPanelOpen => _isAccountsPanelOpen;
  bool get isSearchOpen => _isSearchOpen;
  bool get isTorEnabled => _isTorEnabled;
  bool get isSidebarCollapsed => _isSidebarCollapsed;
  bool get canGoBack => _historyIndex > 0;
  bool get canGoForward => _historyIndex < _history.length - 1;

  /// Navigate to a new app/url
  void navigateToApp(String url, {String name = ''}) {
    // If we're navigating from middle of history, truncate forward
    if (_historyIndex < _history.length - 1) {
      _history = _history.sublist(0, _historyIndex + 1);
    }
    _currentAppUrl = url;
    _currentAppName = name;
    _history.add(url);
    _historyIndex = _history.length - 1;
    _closeAllPanels();
    notifyListeners();
  }

  /// Go back in history
  void goBack() {
    if (canGoBack) {
      _historyIndex--;
      _currentAppUrl = _history[_historyIndex];
      notifyListeners();
    }
  }

  /// Go forward in history
  void goForward() {
    if (canGoForward) {
      _historyIndex++;
      _currentAppUrl = _history[_historyIndex];
      notifyListeners();
    }
  }

  /// Go home (Welcome page)
  void goHome() {
    navigateToApp('https://kodair.us/Welcome/Welcome.html', name: 'Welcome');
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/kodair_app.dart';
import '../data/app_registry.dart';

/// Manages the user's sidebar app list with full CRUD, reorder, and persistence.
class SidebarProvider extends ChangeNotifier {
  List<KodairApp> _apps = [];
  bool _loaded = false;
  static const _storageKey = 'sidebar_apps_v2';
  static const _uuid = Uuid();

  SidebarProvider() {
    _loadApps();
  }

  List<KodairApp> get apps => _apps;
  List<KodairApp> get visibleApps => _apps.where((a) => !a.isWidget).toList();
  List<KodairApp> get widgets => _apps.where((a) => a.isWidget).toList();
  bool get isLoaded => _loaded;

  /// Load from SharedPreferences, or initialize with defaults on first run.
  Future<void> _loadApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final List<dynamic> decoded = jsonDecode(json);
        _apps = decoded.map((e) => KodairApp.fromJson(e as Map<String, dynamic>)).toList();
        _apps.sort((a, b) => a.position.compareTo(b.position));
      } else {
        // First run — clone defaults
        _apps = defaultKodairApps;
      }
    } catch (e) {
      debugPrint('SidebarProvider load error: $e');
      _apps = defaultKodairApps;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_apps.map((a) => a.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('SidebarProvider save error: $e');
    }
  }

  /// Add a custom app to the sidebar.
  void addApp({required String name, required String url, IconData? iconData}) {
    final app = KodairApp(
      id: 'custom_${_uuid.v4()}',
      name: name,
      url: url,
      iconData: iconData ?? Icons.web,
      isCustom: true,
      position: _apps.length,
    );
    _apps.add(app);
    _saveApps();
    notifyListeners();
  }

  /// Remove an app by ID.
  void removeApp(String id) {
    _apps.removeWhere((a) => a.id == id);
    _reindex();
    _saveApps();
    notifyListeners();
  }

  /// Edit an existing app's name, URL, or icon.
  void editApp(String id, {String? name, String? url, IconData? iconData}) {
    final idx = _apps.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    _apps[idx] = _apps[idx].copyWith(
      name: name,
      url: url,
      iconData: iconData,
    );
    _saveApps();
    notifyListeners();
  }

  /// Reorder an app from oldIndex to newIndex (drag-and-drop).
  void moveApp(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    if (newIndex > oldIndex) newIndex--;
    final app = _apps.removeAt(oldIndex);
    _apps.insert(newIndex, app);
    _reindex();
    _saveApps();
    notifyListeners();
  }

  /// Reset to factory defaults. Requires explicit caller-side confirmation.
  void resetToDefaults() {
    _apps = defaultKodairApps;
    _saveApps();
    notifyListeners();
  }

  void _reindex() {
    for (int i = 0; i < _apps.length; i++) {
      _apps[i].position = i;
    }
  }
}

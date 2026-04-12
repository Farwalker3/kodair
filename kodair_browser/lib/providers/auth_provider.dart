import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _iisuTokenPayload;
  bool _isAuthenticated = false;

  String? get iisuTokenPayload => _iisuTokenPayload;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _loadAuth();
  }

  Future<void> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _iisuTokenPayload = prefs.getString('iisu_auth_payload');
    _isAuthenticated = _iisuTokenPayload != null;
    notifyListeners();
  }

  Future<void> setToken(String payload) async {
    _iisuTokenPayload = payload;
    _isAuthenticated = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('iisu_auth_payload', payload);
    notifyListeners();
  }

  Future<void> logout() async {
    _iisuTokenPayload = null;
    _isAuthenticated = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('iisu_auth_payload');
    notifyListeners();
  }
}

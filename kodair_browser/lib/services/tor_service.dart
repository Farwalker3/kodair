import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the Tor SOCKS5 proxy connection.
/// Looks for a running Tor service and provides proxy configuration.
class TorService {
  static const int torSocksPort = 9050;  // Standard Tor SOCKS port
  static const int torBrowserPort = 9150; // Tor Browser SOCKS port
  static const _prefKey = 'tor_enabled';

  static TorService? _instance;
  static TorService get instance => _instance ??= TorService._();
  TorService._();

  Process? _torProcess;
  int _activePort = 0;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  int get activePort => _activePort;
  String get proxyAddress => 'socks5://127.0.0.1:$_activePort';

  /// Check if Tor should be enabled (persisted from last session).
  static Future<bool> shouldEnableTor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Save the Tor preference.
  static Future<void> saveTorPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  /// Try to connect to an existing Tor service.
  Future<bool> connect() async {
    // Try standard Tor port first (9050), then Tor Browser port (9150)
    for (final port in [torSocksPort, torBrowserPort]) {
      if (await _checkPort(port)) {
        _activePort = port;
        _isConnected = true;
        debugPrint('TorService: Connected to Tor on port $port');
        return true;
      }
    }

    // Try starting our own Tor process
    final started = await _startTorProcess();
    if (started) {
      _isConnected = true;
      return true;
    }

    _isConnected = false;
    return false;
  }

  /// Check if a SOCKS5 proxy is listening on the given port.
  Future<bool> _checkPort(int port) async {
    try {
      final socket = await Socket.connect('127.0.0.1', port, timeout: const Duration(seconds: 2));
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Try to find and start Tor binary.
  Future<bool> _startTorProcess() async {
    final torPaths = [
      // Common Tor installations on Windows
      r'C:\Program Files\Tor\tor.exe',
      r'C:\Program Files (x86)\Tor\tor.exe',
      r'C:\Users\' + (Platform.environment['USERNAME'] ?? '') + r'\Desktop\Tor Browser\Browser\TorBrowser\Tor\tor.exe',
      r'C:\Users\' + (Platform.environment['USERNAME'] ?? '') + r'\AppData\Local\Tor Browser\Browser\TorBrowser\Tor\tor.exe',
      'tor', // System PATH
    ];

    for (final torPath in torPaths) {
      try {
        debugPrint('TorService: Trying $torPath');
        _torProcess = await Process.start(torPath, [], mode: ProcessStartMode.detached);
        
        // Wait for Tor to establish connection
        for (int i = 0; i < 30; i++) {
          await Future.delayed(const Duration(seconds: 1));
          if (await _checkPort(torSocksPort)) {
            _activePort = torSocksPort;
            debugPrint('TorService: Started Tor successfully');
            return true;
          }
        }
        // Tor didn't start in time
        _torProcess?.kill();
        _torProcess = null;
      } catch (e) {
        debugPrint('TorService: Failed to start $torPath: $e');
        continue;
      }
    }

    return false;
  }

  /// Disconnect and stop the Tor process if we started it.
  Future<void> disconnect() async {
    _torProcess?.kill();
    _torProcess = null;
    _isConnected = false;
    _activePort = 0;
  }

  /// Get instructions for the user to install Tor.
  static String get installInstructions => '''To use TOR mode, you need the Tor service running:

Option 1: Install Tor Browser
  → Download from https://www.torproject.org
  → Open Tor Browser and leave it running
  → Kodair will connect through it

Option 2: Install Tor Expert Bundle
  → Download from https://www.torproject.org/download/tor/
  → Extract and run tor.exe
  → Kodair will connect automatically''';
}

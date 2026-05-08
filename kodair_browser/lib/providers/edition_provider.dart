import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The available Kodair browser editions, each with distinct theming and personality.
enum KodairEdition {
  classic,
  education,
  tor,
  web3,
  gamer,
}

/// Per-edition visual configuration.
class EditionConfig {
  final String displayName;
  final String tagline;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color sidebarTop;
  final Color sidebarBottom;
  final Color backgroundTop;
  final Color backgroundBottom;

  const EditionConfig({
    required this.displayName,
    required this.tagline,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.sidebarTop,
    required this.sidebarBottom,
    required this.backgroundTop,
    required this.backgroundBottom,
  });
}

/// Manages the active browser edition with persistence.
class EditionProvider extends ChangeNotifier {
  KodairEdition _edition = KodairEdition.classic;
  static const _storageKey = 'kodair_edition';

  EditionProvider() {
    _load();
  }

  KodairEdition get edition => _edition;
  EditionConfig get config => editions[_edition]!;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null) {
        _edition = KodairEdition.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => KodairEdition.classic,
        );
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setEdition(KodairEdition edition) async {
    if (_edition == edition) return;
    _edition = edition;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, edition.name);
  }

  /// All edition configurations.
  static const Map<KodairEdition, EditionConfig> editions = {
    KodairEdition.classic: EditionConfig(
      displayName: 'Classic',
      tagline: 'Your Place For Everything',
      icon: Icons.language,
      primaryColor: Color(0xFF6688FF),
      secondaryColor: Color(0xFF66FF88),
      accentColor: Color(0xFF6688FF),
      sidebarTop: Color(0xFF66FF88),
      sidebarBottom: Color(0xFF6688FF),
      backgroundTop: Color(0xFF6688FF),
      backgroundBottom: Color(0xFF66FF88),
    ),
    KodairEdition.education: EditionConfig(
      displayName: 'Education',
      tagline: 'Learn Without Limits',
      icon: Icons.school,
      primaryColor: Color(0xFFFF9800),
      secondaryColor: Color(0xFFFFF3E0),
      accentColor: Color(0xFFFF6D00),
      sidebarTop: Color(0xFFFFCC80),
      sidebarBottom: Color(0xFFFF9800),
      backgroundTop: Color(0xFFFF9800),
      backgroundBottom: Color(0xFFFFF3E0),
    ),
    KodairEdition.tor: EditionConfig(
      displayName: 'TOR',
      tagline: 'Browse in the Shadows',
      icon: Icons.security,
      primaryColor: Color(0xFF7D4698),
      secondaryColor: Color(0xFF1A1A2E),
      accentColor: Color(0xFF9C27B0),
      sidebarTop: Color(0xFF1A1A2E),
      sidebarBottom: Color(0xFF7D4698),
      backgroundTop: Color(0xFF0D0D1A),
      backgroundBottom: Color(0xFF2D1B4E),
    ),
    KodairEdition.web3: EditionConfig(
      displayName: 'Web3',
      tagline: 'Decentralized & Sovereign',
      icon: Icons.hub,
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFF0A0A1A),
      accentColor: Color(0xFF00BCD4),
      sidebarTop: Color(0xFF0A0A1A),
      sidebarBottom: Color(0xFF00E5FF),
      backgroundTop: Color(0xFF001F3F),
      backgroundBottom: Color(0xFF00E5FF),
    ),
    KodairEdition.gamer: EditionConfig(
      displayName: 'Gamer',
      tagline: 'Level Up Your Browsing',
      icon: Icons.sports_esports,
      primaryColor: Color(0xFFFF1744),
      secondaryColor: Color(0xFF121212),
      accentColor: Color(0xFFFF5252),
      sidebarTop: Color(0xFF121212),
      sidebarBottom: Color(0xFFFF1744),
      backgroundTop: Color(0xFF1A0000),
      backgroundBottom: Color(0xFFFF1744),
    ),
  };
}

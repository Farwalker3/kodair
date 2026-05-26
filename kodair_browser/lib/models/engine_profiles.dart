import 'package:flutter/material.dart';

/// Represents a browser engine that Kodair can emulate/present as.
///
/// On Flutter, all rendering goes through the platform's native WebView
/// (WebView2 on Windows, Android WebView on Android). The "engine" controls
/// the User-Agent string and compatible extension stores, so websites see
/// Kodair as that browser.
class EngineProfile {
  final String id;
  final String displayName;     // Plain name: "Chrome", "Firefox", etc.
  final String engineName;      // Technical: "Blink", "Gecko", etc.
  final String description;
  final String userAgent;
  final IconData icon;
  final Color accentColor;
  final List<ExtensionStore> extensionStores;
  final bool isLegacy;          // Discontinued engines

  const EngineProfile({
    required this.id,
    required this.displayName,
    required this.engineName,
    required this.description,
    required this.userAgent,
    required this.icon,
    required this.accentColor,
    this.extensionStores = const [],
    this.isLegacy = false,
  });
}

/// An extension store compatible with a given engine.
class ExtensionStore {
  final String name;
  final String url;
  final IconData icon;

  const ExtensionStore({
    required this.name,
    required this.url,
    required this.icon,
  });
}

/// All available engine profiles.
class EngineProfiles {
  EngineProfiles._();

  // ── Active engines ──────────────────────────────────────────────

  static const chrome = EngineProfile(
    id: 'chrome',
    displayName: 'Chrome',
    engineName: 'Blink / Chromium',
    description: 'Google Chrome — the world\'s most popular browser engine. '
        'Powers Chrome, Edge, Opera, Vivaldi, and Brave.',
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36',
    icon: Icons.public,
    accentColor: Color(0xFF4285F4),
    extensionStores: [
      ExtensionStore(
        name: 'Chrome Web Store',
        url: 'https://chromewebstore.google.com',
        icon: Icons.extension,
      ),
      ExtensionStore(
        name: 'Edge Add-ons',
        url: 'https://microsoftedge.microsoft.com/addons',
        icon: Icons.add_box_outlined,
      ),
    ],
  );

  static const firefox = EngineProfile(
    id: 'firefox',
    displayName: 'Firefox',
    engineName: 'Gecko',
    description: 'Mozilla Firefox — privacy-focused, open-source engine. '
        'Independent from Chromium.',
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) '
        'Gecko/20100101 Firefox/138.0',
    icon: Icons.local_fire_department,
    accentColor: Color(0xFFFF7139),
    extensionStores: [
      ExtensionStore(
        name: 'Firefox Add-ons',
        url: 'https://addons.mozilla.org',
        icon: Icons.extension,
      ),
    ],
  );

  static const safari = EngineProfile(
    id: 'safari',
    displayName: 'Safari',
    engineName: 'WebKit',
    description: 'Apple Safari — powers all iOS browsers and macOS Safari. '
        'Known for energy efficiency.',
    userAgent:
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 '
        '(KHTML, like Gecko) Version/18.4 Safari/605.1.15',
    icon: Icons.explore,
    accentColor: Color(0xFF006CFF),
  );

  static const tor = EngineProfile(
    id: 'tor',
    displayName: 'Tor',
    engineName: 'Gecko + Tor Network',
    description: 'Tor Browser — maximum privacy via onion routing. '
        'Access .onion sites. Requires Tor service running.',
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; rv:128.0) Gecko/20100101 Firefox/128.0',
    icon: Icons.security,
    accentColor: Color(0xFF7D4698),
    extensionStores: [
      ExtensionStore(
        name: 'Firefox Add-ons',
        url: 'https://addons.mozilla.org',
        icon: Icons.extension,
      ),
    ],
  );

  static const edge = EngineProfile(
    id: 'edge',
    displayName: 'Edge',
    engineName: 'Blink / WebView2',
    description: 'Microsoft Edge — Chromium-based with Microsoft integrations. '
        'Default Windows browser.',
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0',
    icon: Icons.window,
    accentColor: Color(0xFF0078D7),
    extensionStores: [
      ExtensionStore(
        name: 'Edge Add-ons',
        url: 'https://microsoftedge.microsoft.com/addons',
        icon: Icons.add_box_outlined,
      ),
      ExtensionStore(
        name: 'Chrome Web Store',
        url: 'https://chromewebstore.google.com',
        icon: Icons.extension,
      ),
    ],
  );

  static const servo = EngineProfile(
    id: 'servo',
    displayName: 'Servo',
    engineName: 'Servo (Rust)',
    description: 'Servo — experimental engine written in Rust. '
        'Memory safe, GPU-accelerated. Passes 1.8M+ web tests.',
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Servo/0.1',
    icon: Icons.science,
    accentColor: Color(0xFFE44D26),
  );

  // ── Niche / alternative engines ─────────────────────────────────

  static const paleMoon = EngineProfile(
    id: 'palemoon',
    displayName: 'Pale Moon',
    engineName: 'Goanna',
    description: 'Pale Moon — Gecko fork focused on customization and '
        'classic browser UI. Independent rendering engine.',
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:33.5) '
        'Gecko/20100101 Goanna/6.8 Firefox/68.0 PaleMoon/33.5.0',
    icon: Icons.dark_mode,
    accentColor: Color(0xFF1B3B6F),
    extensionStores: [
      ExtensionStore(
        name: 'Pale Moon Add-ons',
        url: 'https://addons.palemoon.org',
        icon: Icons.extension,
      ),
    ],
  );

  static const netsurf = EngineProfile(
    id: 'netsurf',
    displayName: 'NetSurf',
    engineName: 'NetSurf',
    description: 'NetSurf — ultra-lightweight C engine. Minimal footprint, '
        'ideal for embedded and low-resource systems.',
    userAgent:
        'NetSurf/3.11 (Windows; x86_64)',
    icon: Icons.memory,
    accentColor: Color(0xFF2E7D32),
  );

  static const ladybird = EngineProfile(
    id: 'ladybird',
    displayName: 'Ladybird',
    engineName: 'LibWeb',
    description: 'Ladybird — independent engine from the SerenityOS project. '
        'Built from scratch, transitioning to Rust. Alpha in 2026.',
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; x64) LibWeb+LibJS/1.0 Ladybird/1.0',
    icon: Icons.bug_report,
    accentColor: Color(0xFFE91E63),
  );

  // ── Legacy / discontinued engines ──────────────────────────────

  static const operaClassic = EngineProfile(
    id: 'opera_classic',
    displayName: 'Opera Classic',
    engineName: 'Presto',
    description: 'Opera Classic (pre-2013) — the Presto engine, known for '
        'pioneering tabbed browsing, speed dial, and mouse gestures.',
    userAgent:
        'Opera/9.80 (Windows NT 10.0; U; Edition Campaign 21) '
        'Presto/2.12.388 Version/12.18',
    icon: Icons.theater_comedy,
    accentColor: Color(0xFFFF1B2D),
    isLegacy: true,
  );

  static const legacyEdge = EngineProfile(
    id: 'legacy_edge',
    displayName: 'Edge Legacy',
    engineName: 'EdgeHTML',
    description: 'Microsoft Edge Legacy — the original Edge engine before '
        'switching to Chromium in 2020. Discontinued.',
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36 Edge/18.19041',
    icon: Icons.web_asset,
    accentColor: Color(0xFF0078D4),
    isLegacy: true,
  );

  static const dillo = EngineProfile(
    id: 'dillo',
    displayName: 'Dillo',
    engineName: 'Dillo',
    description: 'Dillo — extremely minimal C browser. Under 1 MB. '
        'For the most constrained environments.',
    userAgent: 'Dillo/3.1',
    icon: Icons.compress,
    accentColor: Color(0xFF795548),
    isLegacy: true,
  );

  static const flow = EngineProfile(
    id: 'flow',
    displayName: 'Flow',
    engineName: 'Ekioh Flow',
    description: 'Flow by Ekioh — GPU-first engine designed for smart TVs '
        'and embedded devices. Multi-threaded rendering.',
    userAgent:
        'Mozilla/5.0 (Smart TV; Linux) Flow/1.0',
    icon: Icons.tv,
    accentColor: Color(0xFF00BCD4),
    isLegacy: true,
  );

  static const khtml = EngineProfile(
    id: 'khtml',
    displayName: 'Konqueror',
    engineName: 'KHTML',
    description: 'Konqueror / KHTML — the KDE engine that became the ancestor '
        'of both WebKit and Blink. Discontinued in 2023.',
    userAgent:
        'Mozilla/5.0 (compatible; Konqueror/4.14; Linux) KHTML/4.14.3 '
        '(like Gecko)',
    icon: Icons.history_edu,
    accentColor: Color(0xFF607D8B),
    isLegacy: true,
  );

  // ── All profiles in display order ──────────────────────────────

  static const List<EngineProfile> all = [
    // Top browsers first (most familiar)
    chrome,
    firefox,
    safari,
    tor,
    edge,
    // Modern alternatives
    servo,
    paleMoon,
    ladybird,
    netsurf,
    // Legacy
    operaClassic,
    legacyEdge,
    dillo,
    flow,
    khtml,
  ];

  /// Find a profile by its id.
  static EngineProfile byId(String id) {
    return all.firstWhere(
      (p) => p.id == id,
      orElse: () => chrome,
    );
  }

  /// Active (non-legacy) profiles only.
  static List<EngineProfile> get active =>
      all.where((p) => !p.isLegacy).toList();

  /// Legacy profiles only.
  static List<EngineProfile> get legacy =>
      all.where((p) => p.isLegacy).toList();
}

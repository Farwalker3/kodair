import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart' show BrowserProvider, BrowserEngine, PanelType, browserEngineLabel;
import '../models/engine_profiles.dart';
import '../providers/edition_provider.dart';
import '../providers/sidebar_provider.dart';
import '../services/update_service.dart';
import '../theme/kodair_theme.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final browser = context.watch<BrowserProvider>();

    return Container(
      decoration: BoxDecoration(
        color: KodairTheme.panelBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSectionCard(
            'Settings',
            'Adjust Browser Settings',
          ),
          _buildEditionSelector(context),
          _buildEngineToggle(context, browser),
          _buildTorToggle(context, browser),
          _buildAutoplayToggle(context, browser),
          _buildGhosteryToggle(context, browser),
          _buildAliasVaultToggle(context, browser),
          _buildFullscreenCard(context),
          _buildResetCard(context),
          _buildAboutCard(context),
        ],
      ),
    );
  }

  Widget _buildAutoplayToggle(BuildContext context, BrowserProvider browser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: KodairTheme.searchInputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: browser.isAutoplayBlocked
                  ? KodairTheme.primaryBlue
                  : const Color(0xFFCCCCCC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              'Autoplay Blocker',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: browser.isAutoplayBlocked ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SwitchListTile(
            title: const Text('Block Autoplay', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Prevents media from auto-playing', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: browser.isAutoplayBlocked,
            activeColor: KodairTheme.primaryBlue,
            onChanged: (val) => browser.toggleAutoplayBlocker(),
          ),
        ],
      ),
    );
  }

  Widget _buildGhosteryToggle(BuildContext context, BrowserProvider browser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: KodairTheme.searchInputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: browser.isGhosteryEnabled ? const Color(0xFF7C3AED) : const Color(0xFFCCCCCC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              'Ghostery Ad Blocking',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: browser.isGhosteryEnabled ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SwitchListTile(
            title: const Text('Block Common Ads', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Hides common ad and tracker elements from pages.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: browser.isGhosteryEnabled,
            activeColor: const Color(0xFF7C3AED),
            onChanged: (_) => browser.toggleGhostery(),
          ),
        ],
      ),
    );
  }

  Widget _buildAliasVaultToggle(BuildContext context, BrowserProvider browser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: KodairTheme.searchInputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: browser.isAliasVaultEnabled ? const Color(0xFF0EA5E9) : const Color(0xFFCCCCCC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              'AliasVault Password Bridge',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: browser.isAliasVaultEnabled ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SwitchListTile(
            title: const Text('Open AliasVault on password fields', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Detects password forms and opens app.aliasvault.net in an overlay.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: browser.isAliasVaultEnabled,
            activeColor: const Color(0xFF0EA5E9),
            onChanged: (_) => browser.toggleAliasVaultBridge(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: KodairTheme.searchInputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFCCCCCC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineToggle(BuildContext context, BrowserProvider browser) {
    final activeProfile = browser.activeEngineProfile;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: KodairTheme.searchInputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header with active engine
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: activeProfile.accentColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Column(
              children: [
                Icon(activeProfile.icon, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(
                  'Engine: ${activeProfile.displayName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  activeProfile.engineName,
                  style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(180)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Active engines section
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Active Engines', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withAlpha(180))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: EngineProfiles.active.map((profile) {
                final isActive = activeProfile.id == profile.id;
                return _engineChip(context, profile, isActive);
              }).toList(),
            ),
          ),

          // Legacy engines section
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Legacy Engines', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withAlpha(120))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: EngineProfiles.legacy.map((profile) {
                final isActive = activeProfile.id == profile.id;
                return _engineChip(context, profile, isActive);
              }).toList(),
            ),
          ),

          // Extension store shortcut
          if (activeProfile.extensionStores.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Column(
                children: activeProfile.extensionStores.map((store) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<BrowserProvider>().navigateToApp(store.url, name: store.name);
                          context.read<BrowserProvider>().togglePanel(PanelType.settings);
                        },
                        icon: Icon(store.icon, size: 16),
                        label: Text(store.name, style: const TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: activeProfile.accentColor,
                          side: BorderSide(color: activeProfile.accentColor.withAlpha(80)),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _engineChip(BuildContext context, EngineProfile profile, bool isActive) {
    return GestureDetector(
      onTap: () {
        final engine = BrowserEngine.values.firstWhere(
          (e) => e.name == profile.id,
          orElse: () => BrowserEngine.chrome,
        );
        context.read<BrowserProvider>().setBrowserEngine(engine);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? profile.accentColor.withAlpha(50) : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? profile.accentColor : Colors.white.withAlpha(20),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(profile.icon, size: 14, color: isActive ? profile.accentColor : Colors.white54),
            const SizedBox(width: 6),
            Text(
              profile.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? profile.accentColor : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTorToggle(BuildContext context, BrowserProvider browser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: KodairTheme.searchInputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: browser.isTorEnabled
                  ? KodairTheme.torPurple
                  : const Color(0xFFCCCCCC),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              'Tor Private Browsing',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: browser.isTorEnabled ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(
                  Icons.security,
                  size: 32,
                  color: browser.isTorEnabled
                      ? KodairTheme.torPurple
                      : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  browser.isTorEnabled
                      ? 'Tor is ACTIVE — access .onion sites directly.'
                      : 'Enable Tor to route traffic through the Tor network.',
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text(
                    browser.isTorEnabled ? 'Tor Enabled' : 'Tor Disabled',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  value: browser.isTorEnabled,
                  activeTrackColor: KodairTheme.torPurple,
                  onChanged: (_) => browser.toggleTor(),
                  dense: true,
                ),
                if (browser.torRequiresRestart)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFF9800)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Color(0xFFFF9800), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Restart Kodair for Tor to take effect.',
                            style: TextStyle(fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Requires Tor Browser running in the background.\nDownload from torproject.org',
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: KodairTheme.searchInputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFCCCCCC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Text(
              'Browser Options',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.fullscreen, size: 20),
                  title: const Text(
                    'Enter Fullscreen',
                    style: TextStyle(fontSize: 12),
                  ),
                  dense: true,
                  onTap: () {
                    // Platform-specific fullscreen handling
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, size: 20),
                  title: const Text(
                    'Clear Browsing Data',
                    style: TextStyle(fontSize: 12),
                  ),
                  dense: true,
                  onTap: () {
                    // Clear webview cache
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: KodairTheme.searchInputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFCCCCCC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Text(
              'About Kodair Browser',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text(
                  'Kodair Browser v1.0',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your Place For Everything',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                SizedBox(height: 8),
                Text(
                  'A cross-platform browser with apps instead of tabs.\nPowered by Flutter.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => UpdateService.showUpdateDialog(context, showNoUpdate: true),
                    icon: const Icon(Icons.system_update_alt, size: 16),
                    label: const Text('Check for Updates'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: KodairTheme.appBarBg,
                      foregroundColor: Colors.white,
                      surfaceTintColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditionSelector(BuildContext context) {
    final editionProv = context.watch<EditionProvider>();
    final active = editionProv.edition;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: KodairTheme.searchInputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: editionProv.config.primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Text(
              'Browser Edition',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: EditionProvider.editions.entries.map((entry) {
                  final edition = entry.key;
                  final config = entry.value;
                  final isActive = edition == active;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => editionProv.setEdition(edition),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [config.sidebarTop, config.sidebarBottom],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: isActive
                              ? Border.all(color: Colors.white, width: 2.5)
                              : Border.all(color: Colors.transparent, width: 2.5),
                          boxShadow: isActive
                              ? [BoxShadow(color: config.primaryColor.withAlpha(120), blurRadius: 8)]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(config.icon, size: 22, color: Colors.white),
                            const SizedBox(height: 4),
                            Text(
                              config.displayName,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: Text(
              editionProv.config.tagline,
              style: TextStyle(
                color: editionProv.config.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: KodairTheme.searchInputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFD32F2F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Text(
              'Danger Zone',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text(
                  'Reset sidebar apps to factory defaults.\nThis cannot be undone.',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showResetConfirmation(context),
                  icon: const Icon(Icons.warning_amber, size: 16),
                  label: const Text('Reset to Defaults'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Multi-confirm reset: Dialog 1 → Dialog 2 (type RESET).
  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KodairTheme.darkBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Reset All Sidebar Apps?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'This will remove all custom apps and restore factory defaults. Are you sure?',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showFinalResetConfirmation(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            child: const Text('Yes, Continue'),
          ),
        ],
      ),
    );
  }

  void _showFinalResetConfirmation(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KodairTheme.darkBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Final Confirmation', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Type RESET below to confirm.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'RESET',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim() == 'RESET') {
                context.read<SidebarProvider>().resetToDefaults();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sidebar reset to factory defaults.'),
                    backgroundColor: Color(0xFFD32F2F),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
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
          _buildTorToggle(context, browser),
          _buildFullscreenCard(context),
          _buildAboutCard(),
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
                      ? 'Tor is ACTIVE — traffic is routed through the Tor network'
                      : 'Enable Tor to route traffic through the Tor network for private browsing',
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

  Widget _buildAboutCard() {
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
          const Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

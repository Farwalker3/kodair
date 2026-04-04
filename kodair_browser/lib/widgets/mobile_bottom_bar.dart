import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../theme/kodair_theme.dart';

class MobileBottomBar extends StatelessWidget {
  const MobileBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final browser = context.watch<BrowserProvider>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 56 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: KodairTheme.appBarBg,
        boxShadow: [
          BoxShadow(color: Colors.black26, offset: Offset(0, -2), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
            onPressed: browser.canGoBack ? () => browser.goBack() : null,
          ),
          
          // 2. Apps / Sidebar Toggle
          IconButton(
            icon: Icon(
              browser.isSidebarCollapsed ? Icons.apps : Icons.close_fullscreen,
              size: 24,
              color: Colors.white,
            ),
            onPressed: () => browser.toggleSidebar(),
          ),

          // 3. Search Field / Toggle
          IconButton(
            icon: const Icon(Icons.search, size: 24, color: Colors.white),
            onPressed: () => browser.toggleSearch(),
          ),

          // 4. Tabs Manager
          _buildTabsButton(context, browser),

          // 5. Utilities/Modes Menu
          IconButton(
            icon: const Icon(Icons.more_horiz, size: 24, color: Colors.white),
            onPressed: () => _showMoreSheet(context, browser),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsButton(BuildContext context, BrowserProvider browser) {
    return InkWell(
      onTap: () => _showTabsSheet(context, browser),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${browser.tabs.length}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  void _showTabsSheet(BuildContext context, BrowserProvider browser) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2124), // Keep solid, no opacity
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _TabsSheet(browser: browser),
    );
  }

  void _showMoreSheet(BuildContext context, BrowserProvider browser) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2124), // Keep solid
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ModesSheet(browser: browser),
    );
  }
}

class _TabsSheet extends StatelessWidget {
  final BrowserProvider browser;
  const _TabsSheet({required this.browser});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Open Tabs', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add, color: KodairTheme.forwardCyan),
                onPressed: () {
                  if (browser.tabs.length < 3) {
                    browser.addTab('https://kodair.us/Welcome/Welcome.html', 'New Tab');
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 3 tabs allowed on mobile.')));
                  }
                },
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          ...List.generate(browser.tabs.length, (index) {
            final tab = browser.tabs[index];
            final isActive = index == browser.activeTabIndex;
            return ListTile(
              title: Text(tab.currentAppName.isEmpty ? 'Kodair Tab' : tab.currentAppName, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(tab.currentAppUrl, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: KodairTheme.closeRed),
                onPressed: () {
                  browser.closeTab(index);
                  if (browser.tabs.isEmpty) Navigator.pop(context);
                },
              ),
              selected: isActive,
              selectedTileColor: Colors.white10,
              onTap: () {
                browser.setActiveTab(index);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ModesSheet extends StatelessWidget {
  final BrowserProvider browser;
  const _ModesSheet({required this.browser});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Browser Modes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          
          ListTile(
            leading: const Icon(Icons.article, color: Colors.amber),
            title: const Text('Reading Mode', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Distraction-free article reading', style: TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              browser.activeTab.webViewController?.evaluateJavascript(source: '''
                document.querySelectorAll('header, footer, nav, aside, .ads, iframe, script').forEach(e => e.style.display = 'none');
                document.body.style.maxWidth = '800px';
                document.body.style.margin = '0 auto';
                document.body.style.padding = '20px';
                document.body.style.fontSize = '18px';
                document.body.style.lineHeight = '1.6';
              ''');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.smart_display, color: Colors.redAccent),
            title: const Text('YouTube Client Mode', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Launch dedicated mobile client', style: TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              browser.navigateToApp('https://m.youtube.com', name: 'YouTube');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.zoom_in, color: KodairTheme.refreshYellow),
            title: const Text('Zoom In', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Native hardware zoom increment', style: TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () {
              browser.activeTab.webViewController?.zoomBy(zoomFactor: 1.15); // Native 15% increase
            },
          ),

          ListTile(
            leading: const Icon(Icons.zoom_out, color: KodairTheme.refreshYellow),
            title: const Text('Zoom Out', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Native hardware zoom decrement', style: TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () {
              browser.activeTab.webViewController?.zoomBy(zoomFactor: 0.85); // Native 15% decrease
            },
          ),

          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Browser Settings', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              browser.togglePanel(PanelType.settings);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

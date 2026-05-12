import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/browser_provider.dart';
import '../providers/sidebar_provider.dart';
import '../providers/edition_provider.dart';
import '../models/kodair_app.dart';
import '../theme/kodair_theme.dart';

class KodBar extends StatelessWidget {
  const KodBar({super.key});

  @override
  Widget build(BuildContext context) {
    final browser = context.watch<BrowserProvider>();
    final editionConfig = context.watch<EditionProvider>().config;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: 95,
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [editionConfig.sidebarTop, editionConfig.sidebarBottom],
        ),
      ),
      child: Column(
        children: [
          _buildTopControlsRow(context, browser),
          // Search button
          _buildSearchButton(context, browser),
          // Scrollable app buttons — 2 PER ROW
          Expanded(child: _buildAppBar(context, browser)),
          // Boot bar with date/time
          _buildBootBar(context, browser),
        ],
      ),
    );
  }

  Widget _buildTopControlsRow(BuildContext context, BrowserProvider browser) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
      color: KodairTheme.sizeBarBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _miniBtn(
            icon: browser.isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
            tooltip: browser.isSidebarCollapsed ? 'Show Sidebar' : 'Hide Sidebar',
            onTap: () => browser.toggleSidebar(),
          ),
          const SizedBox(width: 3),
          _miniBtn(
            icon: Icons.account_circle,
            tooltip: 'Account',
            onTap: () => browser.togglePanel(PanelType.accounts),
          ),
          const SizedBox(width: 3),
          _miniBtn(
            icon: Icons.settings,
            tooltip: 'Settings',
            onTap: () => browser.togglePanel(PanelType.settings),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context, BrowserProvider browser) {
    return InkWell(
      onTap: () => browser.toggleSearch(),
      child: Container(
        height: 35,
        width: double.infinity,
        color: KodairTheme.sizeBarBg,
        child: const Center(
          child: Icon(Icons.search, size: 24, color: KodairTheme.appButtonText),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, BrowserProvider browser) {
    return Container(
      color: KodairTheme.appBarBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          children: [
            // Weather widget (full width)
            _WeatherWidget(browser: browser),
            const SizedBox(height: 2),
            // Kostream widget (full width, animated)
            _KostreamWidget(browser: browser),
            const SizedBox(height: 4),
            // All buttons in a single 2-per-row grid (apps + utility)
            _buildAppGrid(context, browser),
          ],
        ),
      ),
    );
  }

  Widget _buildAppGrid(BuildContext context, BrowserProvider browser) {
    final sidebar = context.watch<SidebarProvider>();
    final apps = sidebar.apps.where((a) => !a.isWidget).toList();
    
    // Create unified list of all buttons (apps + utility)
    final List<Widget> allButtons = apps.map((app) => _appButton(context, app, browser, sidebar)).toList();
    
    // Add custom app button
    allButtons.add(_addAppBtn(context, sidebar));
    allButtons.add(_utilBtn(Icons.vpn_key, 'AliasVault',
        () => browser.openAliasVaultOverlay(sourceUrl: browser.currentAppUrl)));
    
    // Add utility buttons at the end
    allButtons.add(_utilBtn(Icons.smart_toy, 'AI Agent',
        () => browser.togglePanel(PanelType.aiAgent)));
    allButtons.add(_utilBtn(Icons.route, 'Trails',
        () => browser.toggleTrails()));
    allButtons.add(_utilBtn(Icons.info, 'About',
        () => browser.togglePanel(PanelType.info)));
    
    // Build 2-per-row layout
    final List<Widget> rows = [];
    for (int i = 0; i < allButtons.length; i += 2) {
      final first = allButtons[i];
      final second = (i + 1 < allButtons.length) ? allButtons[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              first,
              if (second != null) ...[const SizedBox(width: 5), second],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _appButton(BuildContext context, KodairApp app, BrowserProvider browser, SidebarProvider sidebar) {
    final isSelected = browser.currentAppUrl == app.url;
    return Tooltip(
      message: app.name,
      child: GestureDetector(
        onTap: () => browser.navigateToApp(app.url, name: app.name),
        onSecondaryTapDown: (details) => _showAppContextMenu(context, details.globalPosition, app, browser, sidebar),
        onLongPress: () => _showAppContextMenu(context, Offset.zero, app, browser, sidebar),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: isSelected
                ? KodairTheme.appButtonHover.withAlpha(200)
                : KodairTheme.appButtonBg,
            borderRadius: BorderRadius.circular(9),
            border: isSelected
                ? Border.all(color: Colors.white.withAlpha(150), width: 1.5)
                : null,
            boxShadow: isSelected
                ? [BoxShadow(color: KodairTheme.primaryBlue.withAlpha(100), blurRadius: 8)]
                : null,
          ),
          child: Center(
            child: Icon(
              app.iconData ?? Icons.apps,
              size: 19,
              color: isSelected ? Colors.white : KodairTheme.appButtonText,
            ),
          ),
        ),
      ),
    );
  }

  void _showAppContextMenu(BuildContext context, Offset position, KodairApp app, BrowserProvider browser, SidebarProvider sidebar) {
    final pos = position == Offset.zero
        ? RelativeRect.fromLTRB(100, 300, 100, 300)
        : RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy);

    showMenu(
      context: context,
      position: pos,
      color: KodairTheme.appBarBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem(
          onTap: () => browser.addTab(app.url, app.name),
          child: const Row(
            children: [
              Icon(Icons.open_in_new, size: 18, color: Colors.white70),
              SizedBox(width: 8),
              Text('Open in New Tab', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          onTap: () => _showEditAppDialog(context, app, sidebar),
          child: const Row(
            children: [
              Icon(Icons.edit, size: 18, color: Colors.white70),
              SizedBox(width: 8),
              Text('Edit App', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => sidebar.removeApp(app.id),
          child: const Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Remove', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditAppDialog(BuildContext context, KodairApp app, SidebarProvider sidebar) {
    final nameCtrl = TextEditingController(text: app.name);
    final urlCtrl = TextEditingController(text: app.url);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KodairTheme.darkBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Edit App', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'URL',
                labelStyle: const TextStyle(color: Colors.white54),
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
              sidebar.editApp(app.id, name: nameCtrl.text.trim(), url: urlCtrl.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: KodairTheme.primaryBlue),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _addAppBtn(BuildContext context, SidebarProvider sidebar) {
    return Tooltip(
      message: 'Add App',
      child: GestureDetector(
        onTap: () => _showAddAppDialog(context, sidebar),
        child: Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: KodairTheme.appButtonBg.withAlpha(100),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withAlpha(60), width: 1),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 19, color: Colors.white70),
          ),
        ),
      ),
    );
  }

  void _showAddAppDialog(BuildContext context, SidebarProvider sidebar) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KodairTheme.darkBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Add Custom App', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'App Name',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
                labelStyle: const TextStyle(color: Colors.white54),
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
              if (nameCtrl.text.trim().isNotEmpty && urlCtrl.text.trim().isNotEmpty) {
                sidebar.addApp(name: nameCtrl.text.trim(), url: urlCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: KodairTheme.primaryGreen, foregroundColor: Colors.black87),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _miniBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: KodairTheme.appButtonBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(icon, size: 14, color: KodairTheme.appButtonText),
          ),
        ),
      ),
    );
  }

  Widget _utilBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: KodairTheme.appButtonBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(icon, size: 20, color: KodairTheme.appButtonText),
          ),
        ),
      ),
    );
  }

  Widget _buildBootBar(BuildContext context, BrowserProvider browser) {
    return GestureDetector(
      onTap: () => browser.navigateToApp(
        'https://kodair.us/Kotad/Kotad.html',
        name: 'Calendar',
      ),
      child: Container(
        height: 20,
        width: double.infinity,
        color: KodairTheme.sockBg,
        child: const Center(child: _DateTimeDisplay()),
      ),
    );
  }
}

// ===== LIVE WEATHER WIDGET =====
class _WeatherWidget extends StatefulWidget {
  final BrowserProvider browser;
  const _WeatherWidget({required this.browser});

  @override
  State<_WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<_WeatherWidget> {
  String _weatherText = 'Weather';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _timer = Timer.periodic(const Duration(hours: 1), (_) => _fetchWeather());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    try {
      final ipResp = await http.get(Uri.parse('https://ipwho.is'));
      if (ipResp.statusCode == 200) {
        final ipData = json.decode(ipResp.body);
        final postal = ipData['postal'];
        final weatherResp = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?zip=$postal&id=524901&APPID=710a8a155ade8daf23d7240bf1ca4d6f&units=imperial',
        ));
        if (weatherResp.statusCode == 200) {
          final wData = json.decode(weatherResp.body);
          final temp = wData['main']['temp'];
          if (mounted) setState(() => _weatherText = '${temp.round()}°F');
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.browser.currentAppUrl == 'https://weatherscan.net';
    return GestureDetector(
      onTap: () => widget.browser.navigateToApp('https://weatherscan.net', name: 'Weather'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 85,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? KodairTheme.appButtonHover.withAlpha(200) : KodairTheme.appButtonBg,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: Colors.white.withAlpha(150), width: 1.5) : null,
        ),
        child: Center(
          child: Text(
            _weatherText,
            style: TextStyle(
              color: isSelected ? Colors.white : KodairTheme.appButtonText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ===== ANIMATED KOSTREAM WIDGET =====
class _KostreamWidget extends StatefulWidget {
  final BrowserProvider browser;
  const _KostreamWidget({required this.browser});

  @override
  State<_KostreamWidget> createState() => _KostreamWidgetState();
}

class _KostreamWidgetState extends State<_KostreamWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glitch;

  @override
  void initState() {
    super.initState();
    _glitch = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glitch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.browser.currentAppUrl.contains('KodScan');
    return GestureDetector(
      onTap: () => widget.browser.navigateToApp(
        'https://kodair.us/KodScan/KodScan.html',
        name: 'Kostream',
      ),
      child: AnimatedBuilder(
        animation: _glitch,
        builder: (context, child) {
          final g = (_glitch.value - 0.5) * 2;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 85,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? KodairTheme.appButtonHover.withAlpha(200) : KodairTheme.appButtonBg,
              borderRadius: BorderRadius.circular(10),
              border: isSelected ? Border.all(color: Colors.white.withAlpha(150), width: 1.5) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withAlpha((30 + g.abs() * 40).toInt()),
                  blurRadius: 4 + g.abs() * 4,
                  offset: Offset(g * 1.5, 0),
                ),
                BoxShadow(
                  color: const Color(0xFFFF00FF).withAlpha((20 + g.abs() * 30).toInt()),
                  blurRadius: 3 + g.abs() * 3,
                  offset: Offset(-g * 1.5, 0),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: g * 1.2,
                  top: 0,
                  bottom: 0,
                  right: -g * 1.2,
                  child: Center(
                    child: Text('KOSTREAM',
                        style: TextStyle(
                          color: Colors.cyan.withAlpha(80),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        )),
                  ),
                ),
                Center(
                  child: Text('KOSTREAM',
                      style: TextStyle(
                        color: isSelected ? Colors.white : KodairTheme.appButtonText,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      )),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===== DATE/TIME DISPLAY =====
class _DateTimeDisplay extends StatelessWidget {
  const _DateTimeDisplay();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final now = DateTime.now();
        final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        final dayName = days[now.weekday % 7];
        final monthName = months[now.month - 1];
        final day = now.day.toString().padLeft(2, '0');
        final hour = now.hour == 0 ? 12 : now.hour > 12 ? now.hour - 12 : now.hour;
        final minute = now.minute.toString().padLeft(2, '0');
        final ampm = now.hour >= 12 ? 'PM' : 'AM';
        return Text(
          '$dayName $monthName $day $hour:$minute $ampm',
          style: const TextStyle(fontSize: 9, color: Color(0xBF000000), fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

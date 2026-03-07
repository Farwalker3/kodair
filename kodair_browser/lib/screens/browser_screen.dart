import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../providers/browser_provider.dart';
import '../theme/kodair_theme.dart';
import '../widgets/kod_bar.dart';
import '../widgets/content_view.dart';
import '../widgets/info_panel.dart';
import '../widgets/settings_panel.dart';
import '../widgets/accounts_panel.dart';
import '../widgets/search_overlay.dart';

class BrowserScreen extends StatelessWidget {
  const BrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final browser = context.watch<BrowserProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final sidebarWidth = isMobile && browser.isSidebarCollapsed ? 0.0 : 95.0;
    final panelWidth = isMobile
        ? screenWidth - sidebarWidth
        : (screenWidth - sidebarWidth) * 0.35;

    return Scaffold(
      body: Stack(
        children: [
          // ===== ANIMATED GRADIENT BACKGROUND (full screen) =====
          // IgnorePointer ensures mouse events pass through to WebView
          const IgnorePointer(child: _AnimatedGradientBg()),
          const IgnorePointer(child: _FloatingCircles()),

          // ===== MAIN LAYOUT =====
          Column(
            children: [
              // Custom window title bar with ALL controls
              _buildCustomTitleBar(context, browser),

              // Sidebar + Content
              Expanded(
                child: Row(
                  children: [
                    if (!(isMobile && browser.isSidebarCollapsed))
                      const KodBar(),
                    Expanded(child: const ContentView()),
                  ],
                ),
              ),
            ],
          ),

          // ===== OVERLAY PANELS =====
          if (browser.isInfoPanelOpen)
            Positioned(
              left: sidebarWidth,
              top: 32,
              bottom: 0,
              width: panelWidth,
              child: const InfoPanel(),
            ),
          if (browser.isSettingsPanelOpen)
            Positioned(
              left: sidebarWidth,
              top: 32,
              bottom: 0,
              width: panelWidth,
              child: const SettingsPanel(),
            ),
          if (browser.isAccountsPanelOpen)
            Positioned(
              left: sidebarWidth,
              top: 32,
              bottom: 0,
              width: panelWidth,
              child: const AccountsPanel(),
            ),

          // ===== SEARCH OVERLAY =====
          if (browser.isSearchOpen) const SearchOverlay(),


          // ===== MOBILE SIDEBAR TOGGLE =====
          if (isMobile && browser.isSidebarCollapsed)
            Positioned(
              left: 8,
              top: 40,
              child: FloatingActionButton.small(
                onPressed: () => browser.toggleSidebar(),
                backgroundColor: KodairTheme.primaryBlue.withAlpha(200),
                child: const Icon(Icons.menu, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  /// Custom title bar with ALL navigation controls merged in
  Widget _buildCustomTitleBar(BuildContext context, BrowserProvider browser) {
    return Container(
      height: 32,
      color: KodairTheme.sizeBarBg,
      child: Row(
        children: [
          // --- LEFT: Navigation controls (from original SizeBar) ---
          // Home/Close
          _TitleBarBtn(
            icon: Icons.close,
            hoverColor: KodairTheme.closeRed,
            onTap: () => browser.goHome(),
            tooltip: 'Home',
          ),
          // Refresh
          _TitleBarBtn(
            icon: Icons.refresh,
            hoverColor: KodairTheme.refreshYellow,
            onTap: () {
              final url = browser.currentAppUrl;
              browser.navigateToApp(url);
            },
            tooltip: 'Refresh',
          ),
          // Fullscreen (the ONLY fullscreen button)
          _TitleBarBtn(
            icon: Icons.fullscreen,
            hoverColor: KodairTheme.fullscreenGreen,
            onTap: () => appWindow.maximizeOrRestore(),
            tooltip: 'Fullscreen',
          ),
          // Back
          _TitleBarBtn(
            icon: Icons.arrow_back,
            hoverColor: KodairTheme.backBlue,
            onTap: browser.canGoBack ? () => browser.goBack() : null,
            tooltip: 'Back',
          ),
          // Forward
          _TitleBarBtn(
            icon: Icons.arrow_forward,
            hoverColor: KodairTheme.forwardCyan,
            onTap: browser.canGoForward ? () => browser.goForward() : null,
            tooltip: 'Forward',
          ),

          const SizedBox(width: 8),

          // --- CENTER: Draggable title area ---
          Expanded(
            child: MoveWindow(
              child: Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kodair — ${browser.currentAppName}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // --- RIGHT: Window management buttons ---
          MinimizeWindowButton(
            colors: WindowButtonColors(
              iconNormal: Colors.white70,
              mouseOver: Colors.white24,
              mouseDown: Colors.white12,
            ),
          ),
          MaximizeWindowButton(
            colors: WindowButtonColors(
              iconNormal: Colors.white70,
              mouseOver: Colors.white24,
              mouseDown: Colors.white12,
            ),
          ),
          CloseWindowButton(
            colors: WindowButtonColors(
              iconNormal: Colors.white70,
              mouseOver: const Color(0xFFD32F2F),
              mouseDown: const Color(0xFFB71C1C),
              iconMouseOver: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hover button for the title bar
class _TitleBarBtn extends StatefulWidget {
  final IconData icon;
  final Color hoverColor;
  final VoidCallback? onTap;
  final String? tooltip;

  const _TitleBarBtn({
    required this.icon,
    required this.hoverColor,
    this.onTap,
    this.tooltip,
  });

  @override
  State<_TitleBarBtn> createState() => _TitleBarBtnState();
}

class _TitleBarBtnState extends State<_TitleBarBtn> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip ?? '',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hovering
                  ? widget.hoverColor
                  : KodairTheme.sizeActionBg.withAlpha(80),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: 14,
                color: _hovering ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ===== ANIMATED GRADIENT BACKGROUND =====
class _AnimatedGradientBg extends StatefulWidget {
  const _AnimatedGradientBg();

  @override
  State<_AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<_AnimatedGradientBg>
    with TickerProviderStateMixin {
  late AnimationController _bg1, _bg2, _bg3;

  @override
  void initState() {
    super.initState();
    _bg1 = AnimationController(
        duration: const Duration(seconds: 7), vsync: this)
      ..repeat(reverse: true);
    _bg2 = AnimationController(
        duration: const Duration(seconds: 4), vsync: this)
      ..repeat(reverse: true);
    _bg3 = AnimationController(
        duration: const Duration(seconds: 5), vsync: this)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bg1.dispose();
    _bg2.dispose();
    _bg3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6688FF), Color(0xFF66FF88)],
        ),
      ),
      child: Stack(
        children: [
          _bgLayer(_bg1, -60),
          _bgLayer(_bg2, -45),
          _bgLayer(_bg3, -75),
        ],
      ),
    );
  }

  Widget _bgLayer(AnimationController ctrl, double angleDeg) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final offset =
            Tween<double>(begin: -0.25, end: 0.25).animate(ctrl).value;
        return Positioned.fill(
          child: Transform.translate(
            offset:
                Offset(MediaQuery.of(context).size.width * offset, 0),
            child: Opacity(
              opacity: 0.15,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [Color(0xFF0033FF), Color(0xFF00FF22)],
                    transform:
                        GradientRotation(angleDeg * 3.14159 / 180),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===== FLOATING CIRCLES =====
class _FloatingCircles extends StatefulWidget {
  const _FloatingCircles();

  @override
  State<_FloatingCircles> createState() => _FloatingCirclesState();
}

class _FloatingCirclesState extends State<_FloatingCircles>
    with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;

  static const _data = [
    (left: 0.25, size: 80.0, dur: 25, delay: 0),
    (left: 0.10, size: 20.0, dur: 12, delay: 2),
    (left: 0.70, size: 20.0, dur: 25, delay: 4),
    (left: 0.40, size: 60.0, dur: 18, delay: 0),
    (left: 0.65, size: 20.0, dur: 25, delay: 0),
    (left: 0.75, size: 110.0, dur: 25, delay: 3),
    (left: 0.35, size: 150.0, dur: 25, delay: 7),
    (left: 0.50, size: 25.0, dur: 45, delay: 15),
    (left: 0.20, size: 15.0, dur: 35, delay: 2),
    (left: 0.85, size: 150.0, dur: 11, delay: 0),
  ];

  @override
  void initState() {
    super.initState();
    _ctrls = _data
        .map((d) => AnimationController(
            duration: Duration(seconds: d.dur), vsync: this))
        .toList();
    for (int i = 0; i < _data.length; i++) {
      Future.delayed(Duration(seconds: _data[i].delay), () {
        if (mounted) _ctrls[i].repeat();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    return Stack(
      children: List.generate(_data.length, (i) {
        final d = _data[i];
        return AnimatedBuilder(
          animation: _ctrls[i],
          builder: (_, child) {
            final t = _ctrls[i].value;
            final y = 1.1 - t * 1.4; // bottom to top
            return Positioned(
              left: w * d.left - d.size / 2,
              top: h * y,
              child: Opacity(
                opacity: ((1.0 - t) * 0.3).clamp(0.0, 0.3),
                child: Transform.rotate(
                  angle: t * 12.566,
                  child: Container(
                    width: d.size,
                    height: d.size,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius:
                          BorderRadius.circular(d.size * t * 0.5),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}


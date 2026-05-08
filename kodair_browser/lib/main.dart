import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:io';
import 'providers/browser_provider.dart';
import 'providers/trails_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/sidebar_provider.dart';
import 'theme/kodair_theme.dart';
import 'screens/browser_screen.dart';
import 'utils/native_env.dart';
import 'services/update_service.dart';
import 'package:home_widget/home_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Fix for flutter_inappwebview transparentBackground bug on Windows: 
  // Force WebView2's default background color to fully transparent via environment variable
  if (Platform.isWindows) {
    NativeEnv.set('WEBVIEW2_DEFAULT_BACKGROUND_COLOR', '0');
  }

  runApp(const KodairBrowserApp());

  // Configure the custom window frame (Windows/macOS/Linux)
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    doWhenWindowReady(() {
      final win = appWindow;
      const initialSize = Size(1280, 720);
      win.minSize = const Size(600, 400);
      win.size = initialSize;
      win.alignment = Alignment.center;
      win.title = 'Kodair';
      win.show();
    });
  }
}

class KodairBrowserApp extends StatelessWidget {
  const KodairBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BrowserProvider()),
        ChangeNotifierProvider(create: (_) => TrailsProvider()),
        ChangeNotifierProvider(create: (_) => SidebarProvider()),
      ],
      child: MaterialApp(
        title: 'Kodair Browser',
        debugShowCheckedModeBanner: false,
        theme: KodairTheme.darkTheme,
        darkTheme: KodairTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const UpdateChecker(child: BrowserScreen()),
      ),
    );
  }
}

class UpdateChecker extends StatefulWidget {
  final Widget child;
  const UpdateChecker({super.key, required this.child});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.showUpdateDialog(context);
    });
    
    if (Platform.isIOS) {
      HomeWidget.setAppGroupId('us.kodair.kodair_browser');
    }
    
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        HomeWidget.initiallyLaunchedFromHomeWidget().then(_checkForWidgetLaunch);
        HomeWidget.widgetClicked.listen(_checkForWidgetLaunch);
      } catch (e) {
        debugPrint('HomeWidget Init Error: $e');
      }
    }
  }

  void _checkForWidgetLaunch(Uri? uri) {
    if (!mounted) return;
    if (uri != null && uri.host == 'search') {
      final browser = context.read<BrowserProvider>();
      if (!browser.isSearchOpen) {
        browser.toggleSearch();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

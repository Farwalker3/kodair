import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:io';
import 'providers/browser_provider.dart';
import 'theme/kodair_theme.dart';
import 'screens/browser_screen.dart';
import 'utils/native_env.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Fix for flutter_inappwebview transparentBackground bug on Windows: 
  // Force WebView2's default background color to fully transparent via environment variable
  if (Platform.isWindows) {
    NativeEnv.set('WEBVIEW2_DEFAULT_BACKGROUND_COLOR', '0');
  }

  runApp(const KodairBrowserApp());

  // Configure the custom window frame (Windows/macOS/Linux)
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

class KodairBrowserApp extends StatelessWidget {
  const KodairBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BrowserProvider(),
      child: MaterialApp(
        title: 'Kodair Browser',
        debugShowCheckedModeBanner: false,
        theme: KodairTheme.darkTheme,
        darkTheme: KodairTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const BrowserScreen(),
      ),
    );
  }
}

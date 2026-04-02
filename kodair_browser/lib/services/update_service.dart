import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final bool isUpdateAvailable;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;

  UpdateInfo({
    required this.isUpdateAvailable,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}

class UpdateService {
  static const String _repoUrl = 'https://api.github.com/repos/Farwalker3/kodair/releases/latest';

  /// Check GitHub for the latest release and compare it with the current app version.
  static Future<UpdateInfo> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.0"

      final response = await http.get(Uri.parse(_repoUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String latestTag = data['tag_name'] ?? '';
        String latestVersion = latestTag.replaceAll(RegExp(r'^[vV]'), ''); // strips 'v'
        
        // Simple version compare
        bool isUpdateAvailable = _compareVersions(currentVersion, latestVersion) < 0;

        return UpdateInfo(
          isUpdateAvailable: isUpdateAvailable,
          latestVersion: latestVersion,
          releaseNotes: data['body'] ?? 'No release notes available.',
          downloadUrl: data['html_url'] ?? 'https://github.com/Farwalker3/kodair/releases/latest',
        );
      }
    } catch (e) {
      // Ignored for silent fails
    }

    return UpdateInfo(
      isUpdateAvailable: false,
      latestVersion: '',
      releaseNotes: '',
      downloadUrl: '',
    );
  }

  /// Returns > 0 if v1 > v2, < 0 if v1 < v2, 0 if equal
  static int _compareVersions(String v1, String v2) {
    List<int> p1 = v1.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    List<int> p2 = v2.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    
    // pad to same length
    while (p1.length < p2.length) p1.add(0);
    while (p2.length < p1.length) p2.add(0);
    
    for (int i = 0; i < p1.length; i++) {
      if (p1[i] > p2[i]) return 1;
      if (p1[i] < p2[i]) return -1;
    }
    return 0;
  }

  /// Triggers an update check and optionally shows a dialog.
  /// Set [showNoUpdate] to true when checking manually from Settings.
  static Future<void> showUpdateDialog(BuildContext context, {bool showNoUpdate = false}) async {
    if (showNoUpdate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checking for updates...'), duration: Duration(seconds: 1)),
      );
    }

    final updateInfo = await checkForUpdates();

    if (!context.mounted) return;

    if (updateInfo.isUpdateAvailable) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Update Available (${updateInfo.latestVersion})'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Text('A new version of Kodair Browser is available!\n\nRelease Notes:\n${updateInfo.releaseNotes}'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                _launchUrl(updateInfo.downloadUrl);
                Navigator.pop(ctx);
              },
              child: const Text('Download Update'),
            ),
          ],
        ),
      );
    } else if (showNoUpdate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are on the latest version!')),
      );
    }
  }

  static Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/kodair_theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_sync_service.dart';

class AccountsPanel extends StatelessWidget {
  const AccountsPanel({super.key});

  @override
  Widget build(BuildContext context) {
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
          Container(
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
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: const Text(
                    'Accounts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_circle,
                        size: 64,
                        color: KodairTheme.primaryBlue,
                      ),
                      const SizedBox(height: 16),
                      Consumer<AuthProvider>(
                        builder: (context, auth, child) {
                          if (auth.isAuthenticated) {
                            Map<String, dynamic> payload = {};
                            try {
                               // Safe decode
                               payload = jsonDecode(auth.iisuTokenPayload ?? '{}');
                            } catch (e) {}

                            String rawUser = payload['username']?.toString() ?? 'Persona';
                            // Clean the trailing DOM dump so we only get the absolute username
                            final cleanUser = rawUser.split('\\n').firstWhere((s) => s.trim().isNotEmpty, orElse: () => 'Persona').trim();
                            
                            String rawEmail = payload['email']?.toString() ?? '';
                            final cleanEmail = rawEmail.split('\\n').firstWhere((s) => s.trim().isNotEmpty, orElse: () => '').trim();
                            
                            return Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [KodairTheme.primaryBlue.withAlpha(200), KodairTheme.primaryGreen.withAlpha(150)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: KodairTheme.primaryBlue.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showAvatarEditorDialog(context, payload),
                                        child: Stack(
                                          alignment: Alignment.bottomRight,
                                          children: [
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 3),
                                                boxShadow: [
                                                  BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8, offset: const Offset(0, 4))
                                                ]
                                              ),
                                              child: CircleAvatar(
                                                backgroundColor: Colors.white,
                                                backgroundImage: _resolveAvatarImage(payload['avatar']?.toString() ?? ''),
                                                child: payload['avatar'] == null || payload['avatar'].toString().isEmpty
                                                    ? Icon(Icons.person, size: 40, color: KodairTheme.primaryBlue.withAlpha(150))
                                                    : null,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(color: KodairTheme.primaryBlue, shape: BoxShape.circle),
                                              child: const Icon(Icons.edit, size: 12, color: Colors.white),
                                            )
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        cleanUser,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                                      if (cleanEmail.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          cleanEmail,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.black.withAlpha(60), borderRadius: BorderRadius.circular(20)),
                                        child: const Text('Linked to iiSU Network', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final path = await DataSyncService.exportBackup();
                                        if (path != null && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to: \$path'), backgroundColor: KodairTheme.primaryGreen, duration: const Duration(seconds: 4)));
                                        }
                                      },
                                      icon: const Icon(Icons.download, size: 14),
                                      label: const Text('Export .kdir', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: KodairTheme.primaryBlue,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final success = await DataSyncService.importBackup();
                                        if (success && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restored! Please restart Kodair to mount memory.'), backgroundColor: KodairTheme.primaryGreen, duration: Duration(seconds: 4)));
                                        } else if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No backup found in Downloads folder!'), backgroundColor: Colors.redAccent));
                                        }
                                      },
                                      icon: const Icon(Icons.upload, size: 14),
                                      label: const Text('Import', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: KodairTheme.darkBg,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => auth.logout(),
                                  icon: const Icon(Icons.link_off, size: 16),
                                  label: const Text('Unlink Account'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: KodairTheme.darkBg,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    minimumSize: const Size.fromHeight(40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                )
                              ]
                            );
                          }
                          return ElevatedButton.icon(
                            onPressed: () {
                              _showIisuAuthModal(context);
                            },
                            icon: const Icon(Icons.login, size: 16),
                            label: const Text('iiSU Network'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KodairTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _resolveAvatarImage(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('file://')) {
      final path = url.replaceFirst('file://', '');
      final file = File(path);
      if (file.existsSync()) return FileImage(file);
      return null;
    }
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    return null;
  }

  void _showIisuAuthModal(BuildContext context) {
    InAppWebViewController? webController;
    bool isExtracting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(ctx).size.height * 0.85,
                decoration: BoxDecoration(
                  color: KodairTheme.lightBg,
                  borderRadius: BorderRadius.circular(16)
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: KodairTheme.darkBg,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.security, color: KodairTheme.primaryBlue, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: const Text('Secure Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                                ]
                              ),
                            ),
                            Row(
                              children: [
                                isExtracting 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: KodairTheme.primaryGreen, strokeWidth: 2))
                                : ElevatedButton.icon(
                                  icon: const Icon(Icons.sync, size: 14),
                                  label: const Text('Sync to Kodair', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(backgroundColor: KodairTheme.primaryGreen, foregroundColor: Colors.black87),
                                  onPressed: () async {
                                    if (webController != null) {
                                      setState(() => isExtracting = true);
                                      try {
                                        CookieManager cookieManager = CookieManager.instance();
                                        List<Cookie> cookies = await cookieManager.getCookies(url: WebUri("https://accounts.iisu.network"));
                                        String nativeCookies = cookies.map((c) => '\${c.name}=\${c.value}').join('; ');

                                        final dump = await webController!.evaluateJavascript(source: '''
                                          (function() {
                                            const lines = document.body.innerText.split(/\\r?\\n/).map(l => l.trim()).filter(l => l.length > 0);
                                            let username = "Unknown";
                                            let email = "Unknown";
                                            
                                            // Secure native DOM lookup avoiding Dart collision spaces
                                            const uIndex = lines.indexOf('Username');
                                            if (uIndex !== -1 && uIndex + 1 < lines.length) {
                                              username = lines[uIndex + 1];
                                            }
                                            
                                            const eIndex = lines.indexOf('Email');
                                            if (eIndex !== -1 && eIndex + 1 < lines.length) {
                                              email = lines[eIndex + 1];
                                            }
                                            
                                            return JSON.stringify({
                                              username: username,
                                              email: email
                                            });
                                          })();
                                        ''');
                                        
                                        if (dump != null) {
                                          final dumpMap = jsonDecode(dump.toString()) as Map<String, dynamic>;
                                          
                                          // Retain the existing avatar or define blank
                                          String safeAvatar = context.read<AuthProvider>().iisuTokenPayload != null
                                              ? (jsonDecode(context.read<AuthProvider>().iisuTokenPayload!)['avatar'] ?? '') 
                                              : '';

                                          final safePayloadJson = {
                                            "username": dumpMap['username'],
                                            "email": dumpMap['email'],
                                            "avatar": safeAvatar,
                                            "nativeCookies": nativeCookies
                                          };

                                          context.read<AuthProvider>().setToken(jsonEncode(safePayloadJson));
                                          Navigator.pop(ctx);
                                        }
                                      } finally {
                                        if (ctx.mounted) {
                                          setState(() => isExtracting = false);
                                        }
                                      }
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  Expanded(
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(url: WebUri('https://accounts.iisu.network/auth')),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        domStorageEnabled: true,
                        transparentBackground: false,
                      ),
                      onWebViewCreated: (controller) {
                        webController = controller;
                      },
                    ),
                  )
                ],
              ),
            ),
          )
            );
          }
        );
      }
    );
  }

  void _showAvatarEditorDialog(BuildContext context, Map<String, dynamic> currentPayload) {
    final TextEditingController avatarCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KodairTheme.darkBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Set Profile Picture', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Paste an image URL or upload from your device.', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 20),
              TextField(
                controller: avatarCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1A1A2E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  hintText: 'https://example.com/avatar.png',
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.link, color: Colors.white38, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  if (avatarCtrl.text.trim().isEmpty) return;
                  final newPayload = Map<String, dynamic>.from(currentPayload);
                  newPayload['avatar'] = avatarCtrl.text.trim();
                  context.read<AuthProvider>().setToken(jsonEncode(newPayload));
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Use URL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KodairTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white24)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: Colors.white.withAlpha(100)))),
                  const Expanded(child: Divider(color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
                  if (image != null) {
                    // Copy to app's persistent directory so it survives cache clears
                    final appDir = await getApplicationDocumentsDirectory();
                    final savedPath = '${appDir.path}/kodair_avatar.jpg';
                    await File(image.path).copy(savedPath);
                    
                    final newPayload = Map<String, dynamic>.from(currentPayload);
                    newPayload['avatar'] = 'file://$savedPath';
                    if (ctx.mounted) {
                      context.read<AuthProvider>().setToken(jsonEncode(newPayload));
                      Navigator.pop(ctx);
                    }
                  }
                },
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Choose from Device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KodairTheme.primaryGreen,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
            ]
          )
        );
      }
    );
  }
}

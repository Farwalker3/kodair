import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/browser_provider.dart';
import '../theme/kodair_theme.dart';

/// Share panel — share the current tab URL via clipboard, system share, or QR code.
class SharePanel extends StatelessWidget {
  const SharePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final browser = context.watch<BrowserProvider>();
    final url = browser.currentAppUrl;
    final title = browser.currentAppName;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF0101020),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 16, offset: const Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1A2A3E), Color(0xFF0D0D1A)]),
            ),
            child: Row(
              children: [
                const Icon(Icons.share, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text('Share', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                  onPressed: () => browser.togglePanel(PanelType.info), // close via toggle
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Current page info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withAlpha(15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.isNotEmpty ? title : 'Current Tab',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          url,
                          style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // QR Code
                  if (url.isNotEmpty && url.startsWith('http'))
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: url,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0D0D1A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0D0D1A),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Action buttons
                  _shareButton(
                    context,
                    icon: Icons.copy,
                    label: 'Copy Link',
                    color: KodairTheme.primaryBlue,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied!'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _shareButton(
                    context,
                    icon: Icons.share,
                    label: 'Share via System',
                    color: KodairTheme.primaryGreen,
                    onTap: () {
                      Share.share('$title\n$url');
                    },
                  ),
                  const SizedBox(height: 8),
                  _shareButton(
                    context,
                    icon: Icons.copy_all,
                    label: 'Copy Title + URL',
                    color: const Color(0xFF9C27B0),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: '$title\n$url'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Title & link copied!'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shareButton(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withAlpha(40),
          foregroundColor: color,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    );
  }
}

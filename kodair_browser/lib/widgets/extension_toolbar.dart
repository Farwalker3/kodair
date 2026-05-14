import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/browser_extension_item.dart';
import '../providers/browser_provider.dart';
import '../theme/kodair_theme.dart';

class ExtensionToolbar extends StatelessWidget {
  final bool compact;

  const ExtensionToolbar({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final browser = context.watch<BrowserProvider>();
    final items = browser.extensionToolbarItems;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _ExtensionIconButton(item: item, compact: compact),
          ),
      ],
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: row,
    );
  }
}

class ExtensionPopupOverlay extends StatelessWidget {
  const ExtensionPopupOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final browser = context.watch<BrowserProvider>();
    final item = browser.activeExtensionPopup;
    if (item == null) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 700;

    return Positioned(
      top: isMobile ? 0 : 40,
      right: isMobile ? 0 : 16,
      left: isMobile ? 0 : null,
      child: SafeArea(
        child: Align(
          alignment: isMobile ? Alignment.topCenter : Alignment.topRight,
          child: Container(
            width: isMobile ? double.infinity : 320,
            margin: isMobile ? EdgeInsets.zero : const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827).withAlpha(245),
              borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(18)),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 24, offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.enabled ? Colors.white : Colors.white54, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(
                            item.nativeEngine == null ? 'Native popup ready' : 'Native engine: ${item.nativeEngine}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: browser.closeExtensionPopup,
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (item.description != null)
                  Text(item.description!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                if (item.sourceUrl != null) ...[
                  const SizedBox(height: 6),
                  Text(item.sourceUrl!, style: const TextStyle(color: Colors.white54, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () {
                        browser.closeExtensionPopup();
                        if (item.popupUrl != null) {
                          browser.navigateToApp(item.popupUrl!, name: '${item.name} popup');
                        }
                      },
                      child: const Text('Open popup'),
                    ),
                    if (item.storeUrl != null)
                      OutlinedButton(
                        onPressed: () {
                          browser.navigateToApp(item.storeUrl!, name: '${item.name} store');
                        },
                        child: const Text('Open store'),
                      ),
                    OutlinedButton(
                      onPressed: () {
                        if (item.isBuiltIn) {
                          if (item.id == 'ghostery') {
                            browser.toggleGhostery();
                          } else if (item.id == 'aliasvault') {
                            browser.toggleAliasVaultBridge();
                          }
                        } else {
                          browser.setNativeExtensionEnabled(item.id, !item.enabled);
                        }
                        browser.closeExtensionPopup();
                      },
                      child: Text(item.enabled ? 'Disable' : 'Enable'),
                    ),
                    if (!item.isBuiltIn)
                      OutlinedButton(
                        onPressed: () {
                          browser.removeNativeExtension(item.id);
                          browser.closeExtensionPopup();
                        },
                        child: const Text('Remove'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExtensionIconButton extends StatelessWidget {
  final BrowserExtensionItem item;
  final bool compact;

  const _ExtensionIconButton({required this.item, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final browser = context.read<BrowserProvider>();
    final isActive = browser.activeExtensionPopup?.id == item.id;

    return Tooltip(
      message: item.name,
      child: PopupMenuButton<_ExtensionAction>(
        tooltip: item.name,
        color: KodairTheme.appBarBg,
        onSelected: (action) async {
          switch (action) {
            case _ExtensionAction.openPopup:
              browser.openExtensionPopup(item.id);
              break;
            case _ExtensionAction.openStore:
              if (item.storeUrl != null) {
                browser.navigateToApp(item.storeUrl!, name: '${item.name} store');
              }
              break;
            case _ExtensionAction.toggle:
              if (item.isBuiltIn) {
                if (item.id == 'ghostery') {
                  browser.toggleGhostery();
                } else if (item.id == 'aliasvault') {
                  browser.toggleAliasVaultBridge();
                }
              } else {
                browser.setNativeExtensionEnabled(item.id, !item.enabled);
              }
              break;
            case _ExtensionAction.remove:
              browser.removeNativeExtension(item.id);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: _ExtensionAction.openPopup, child: Text('Open popup')),
          if (item.storeUrl != null)
            const PopupMenuItem(value: _ExtensionAction.openStore, child: Text('Open store page')),
          PopupMenuItem(value: _ExtensionAction.toggle, child: Text(item.enabled ? 'Disable' : 'Enable')),
          if (!item.isBuiltIn)
            const PopupMenuItem(value: _ExtensionAction.remove, child: Text('Remove from toolbar')),
        ],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: compact ? 24 : 28,
          height: compact ? 24 : 28,
          decoration: BoxDecoration(
            color: isActive ? KodairTheme.primaryBlue.withAlpha(80) : Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? KodairTheme.primaryBlue.withAlpha(180) : Colors.white.withAlpha(18)),
          ),
          child: Icon(
            item.icon,
            color: item.enabled ? Colors.white : Colors.white38,
            size: compact ? 14 : 16,
          ),
        ),
      ),
    );
  }
}

enum _ExtensionAction { openPopup, openStore, toggle, remove }

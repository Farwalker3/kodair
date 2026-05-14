import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/browser_extension_item.dart';

class NativeExtensionService {
  NativeExtensionService._();

  static final NativeExtensionService instance = NativeExtensionService._();
  static const MethodChannel _channel = MethodChannel('kodair/native_extensions');

  String get currentEngine {
    if (Platform.isAndroid) return 'geckoview';
    if (Platform.isWindows) return 'webview2';
    if (Platform.isMacOS) return 'webkit';
    return 'unknown';
  }

  bool get supportsNativeExtensions => !kIsWeb && (Platform.isAndroid || Platform.isWindows);

  bool shouldInterceptStoreInstall({required Uri uri, String? pageUrl}) {
    if (_looksLikeExtensionPackage(uri)) return true;

    final host = uri.host.toLowerCase();
    if (_isOfficialStoreHost(host) && _looksLikeStoreInstallPath(uri)) {
      return true;
    }

    if (pageUrl == null || pageUrl.isEmpty) return false;
    final pageHost = Uri.tryParse(pageUrl)?.host.toLowerCase() ?? '';
    return _isOfficialStoreHost(pageHost) && _looksLikeStoreInstallPath(uri);
  }

  Future<BrowserExtensionItem?> installExtensionFromUri({
    required Uri uri,
    String? pageUrl,
    String? suggestedFilename,
  }) async {
    if (!supportsNativeExtensions || !shouldInterceptStoreInstall(uri: uri, pageUrl: pageUrl)) {
      return null;
    }

    final fallback = _buildFallbackItem(uri: uri, pageUrl: pageUrl, suggestedFilename: suggestedFilename);

    try {
      final result = await _channel.invokeMethod<dynamic>('installExtensionFromUri', {
        'engine': currentEngine,
        'uri': uri.toString(),
        'pageUrl': pageUrl,
        'suggestedFilename': suggestedFilename,
        'fallback': fallback.toJson(),
      });
      if (result is Map) {
        final parsed = BrowserExtensionItem.fromJson(Map<String, dynamic>.from(result));
        return parsed.copyWith(
          nativeEngine: parsed.nativeEngine ?? currentEngine,
          sourceUrl: parsed.sourceUrl ?? uri.toString(),
        );
      }
      return fallback.copyWith(nativeEngine: currentEngine, sourceUrl: uri.toString());
    } on MissingPluginException {
      return fallback.copyWith(nativeEngine: currentEngine, sourceUrl: uri.toString());
    } catch (_) {
      return fallback.copyWith(nativeEngine: currentEngine, sourceUrl: uri.toString());
    }
  }

  Future<void> openExtensionPopup(String extensionId, {String? pageUrl}) async {
    if (!supportsNativeExtensions) return;
    try {
      await _channel.invokeMethod<void>('openExtensionPopup', {
        'engine': currentEngine,
        'extensionId': extensionId,
        'pageUrl': pageUrl,
      });
    } catch (_) {
      // The Dart side still keeps the popup state, so a missing native handler
      // should not break the toolbar.
    }
  }

  Future<void> closeExtensionPopup(String extensionId) async {
    if (!supportsNativeExtensions) return;
    try {
      await _channel.invokeMethod<void>('closeExtensionPopup', {
        'engine': currentEngine,
        'extensionId': extensionId,
      });
    } catch (_) {
      // No-op.
    }
  }

  bool _looksLikeExtensionPackage(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.endsWith('.xpi') || path.endsWith('.crx');
  }

  bool _looksLikeStoreInstallPath(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.contains('/download') || path.contains('/install') || path.endsWith('.xpi') || path.endsWith('.crx');
  }

  bool _isOfficialStoreHost(String host) {
    return host == 'addons.mozilla.org' ||
        host.endsWith('.addons.mozilla.org') ||
        host == 'chrome.google.com' ||
        host == 'chromewebstore.google.com' ||
        host == 'microsoftedge.microsoft.com' ||
        host.endsWith('.microsoftedge.microsoft.com');
  }

  BrowserExtensionItem _buildFallbackItem({
    required Uri uri,
    String? pageUrl,
    String? suggestedFilename,
  }) {
    final inferredName = _inferName(uri, pageUrl: pageUrl, suggestedFilename: suggestedFilename);
    return BrowserExtensionItem(
      id: _inferId(uri, pageUrl: pageUrl, suggestedFilename: suggestedFilename),
      name: inferredName,
      icon: _iconForName(inferredName, uri),
      enabled: true,
      storeUrl: pageUrl,
      popupUrl: pageUrl,
      sourceUrl: uri.toString(),
      nativeEngine: currentEngine,
      description: 'Installed from ${uri.host}',
    );
  }

  String _inferName(Uri uri, {String? pageUrl, String? suggestedFilename}) {
    final pageUri = pageUrl == null ? null : Uri.tryParse(pageUrl);
    final storeLabel = _storeLabel(pageUri?.host ?? uri.host);
    if (storeLabel != null && suggestedFilename == null) {
      return storeLabel;
    }

    final candidate = _trimKnownExtensions(
      suggestedFilename ??
          (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '') ??
          '',
    );
    if (candidate.isNotEmpty) return candidate;

    if (pageUri != null) {
      final last = pageUri.pathSegments.isNotEmpty ? pageUri.pathSegments.last : '';
      final trimmed = _trimKnownExtensions(last);
      if (trimmed.isNotEmpty) return trimmed.replaceAll('-', ' ');
    }

    return storeLabel ?? 'Extension';
  }

  String _inferId(Uri uri, {String? pageUrl, String? suggestedFilename}) {
    final pageUri = pageUrl == null ? null : Uri.tryParse(pageUrl);
    if (pageUri != null && pageUri.host.contains('chromewebstore.google.com')) {
      final segments = pageUri.pathSegments;
      final detailIndex = segments.indexOf('detail');
      if (detailIndex >= 0 && detailIndex + 1 < segments.length) {
        return segments[detailIndex + 1];
      }
    }

    final name = _inferName(uri, pageUrl: pageUrl, suggestedFilename: suggestedFilename);
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'(^-|-$)'), '');
  }

  String _trimKnownExtensions(String input) {
    return input.replaceAll(RegExp(r'\.(xpi|crx|zip)$', caseSensitive: false), '');
  }

  String? _storeLabel(String host) {
    if (host.contains('addons.mozilla.org')) return 'Firefox Add-on';
    if (host.contains('chromewebstore.google.com') || host.contains('chrome.google.com')) return 'Chrome Extension';
    if (host.contains('microsoftedge.microsoft.com')) return 'Edge Add-on';
    return null;
  }

  IconData _iconForName(String name, Uri uri) {
    final lower = name.toLowerCase();
    if (lower.contains('ghostery')) return Icons.shield_outlined;
    if (lower.contains('aliasvault')) return Icons.key_outlined;
    if (uri.host.contains('addons.mozilla.org')) return Icons.language_outlined;
    if (uri.host.contains('chromewebstore.google.com') || uri.host.contains('chrome.google.com')) return Icons.extension_outlined;
    if (uri.host.contains('microsoftedge.microsoft.com')) return Icons.web_outlined;
    return Icons.extension_outlined;
  }
}

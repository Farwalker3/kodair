import 'package:flutter/material.dart';

class BrowserExtensionItem {
  final String id;
  final String name;
  final IconData icon;
  final bool enabled;
  final bool isBuiltIn;
  final String? storeUrl;
  final String? popupUrl;
  final String? sourceUrl;
  final String? nativeEngine;
  final String? description;

  const BrowserExtensionItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.enabled,
    this.isBuiltIn = false,
    this.storeUrl,
    this.popupUrl,
    this.sourceUrl,
    this.nativeEngine,
    this.description,
  });

  BrowserExtensionItem copyWith({
    String? id,
    String? name,
    IconData? icon,
    bool? enabled,
    bool? isBuiltIn,
    String? storeUrl,
    String? popupUrl,
    String? sourceUrl,
    String? nativeEngine,
    String? description,
  }) {
    return BrowserExtensionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      enabled: enabled ?? this.enabled,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      storeUrl: storeUrl ?? this.storeUrl,
      popupUrl: popupUrl ?? this.popupUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      nativeEngine: nativeEngine ?? this.nativeEngine,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'iconMatchTextDirection': icon.matchTextDirection,
      'enabled': enabled,
      'isBuiltIn': isBuiltIn,
      'storeUrl': storeUrl,
      'popupUrl': popupUrl,
      'sourceUrl': sourceUrl,
      'nativeEngine': nativeEngine,
      'description': description,
    };
  }

  factory BrowserExtensionItem.fromJson(Map<String, dynamic> json) {
    return BrowserExtensionItem(
      id: json['id'] as String? ?? 'extension',
      name: json['name'] as String? ?? 'Extension',
      icon: IconData(
        json['iconCodePoint'] as int? ?? Icons.extension_outlined.codePoint,
        fontFamily: json['iconFontFamily'] as String? ?? Icons.extension_outlined.fontFamily,
        fontPackage: json['iconFontPackage'] as String?,
        matchTextDirection: json['iconMatchTextDirection'] as bool? ?? false,
      ),
      enabled: json['enabled'] as bool? ?? true,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      storeUrl: json['storeUrl'] as String?,
      popupUrl: json['popupUrl'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      nativeEngine: json['nativeEngine'] as String?,
      description: json['description'] as String?,
    );
  }
}

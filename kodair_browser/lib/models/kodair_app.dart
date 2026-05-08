import 'package:flutter/material.dart';

class KodairApp {
  final String id;
  final String name;
  final String url;
  final IconData? iconData;
  final String? svgIcon;
  final bool isWidget;
  final bool isCustom;
  int position;

  KodairApp({
    required this.id,
    required this.name,
    required this.url,
    this.iconData,
    this.svgIcon,
    this.isWidget = false,
    this.isCustom = false,
    this.position = 0,
  });

  /// Const-friendly factory for built-in apps (assigned a deterministic id)
  factory KodairApp.builtIn({
    required String name,
    required String url,
    IconData? iconData,
    String? svgIcon,
    bool isWidget = false,
    int position = 0,
  }) {
    return KodairApp(
      id: 'builtin_${name.toLowerCase().replaceAll(' ', '_')}',
      name: name,
      url: url,
      iconData: iconData,
      svgIcon: svgIcon,
      isWidget: isWidget,
      isCustom: false,
      position: position,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'iconCodePoint': iconData?.codePoint,
    'iconFontFamily': iconData?.fontFamily,
    'svgIcon': svgIcon,
    'isWidget': isWidget,
    'isCustom': isCustom,
    'position': position,
  };

  factory KodairApp.fromJson(Map<String, dynamic> json) {
    IconData? icon;
    if (json['iconCodePoint'] != null) {
      icon = IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
        fontPackage: null,
      );
    }
    return KodairApp(
      id: json['id'] as String? ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'App',
      url: json['url'] as String? ?? '',
      iconData: icon,
      svgIcon: json['svgIcon'] as String?,
      isWidget: json['isWidget'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? true,
      position: json['position'] as int? ?? 0,
    );
  }

  KodairApp copyWith({
    String? name,
    String? url,
    IconData? iconData,
    int? position,
  }) {
    return KodairApp(
      id: id,
      name: name ?? this.name,
      url: url ?? this.url,
      iconData: iconData ?? this.iconData,
      svgIcon: svgIcon,
      isWidget: isWidget,
      isCustom: isCustom,
      position: position ?? this.position,
    );
  }
}

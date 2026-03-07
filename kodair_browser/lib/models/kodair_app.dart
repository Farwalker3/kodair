import 'package:flutter/material.dart';

class KodairApp {
  final String name;
  final String url;
  final IconData? iconData;
  final String? svgIcon;
  final bool isWidget;

  const KodairApp({
    required this.name,
    required this.url,
    this.iconData,
    this.svgIcon,
    this.isWidget = false,
  });
}

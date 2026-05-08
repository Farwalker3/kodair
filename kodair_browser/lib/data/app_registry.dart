import 'package:flutter/material.dart';
import '../models/kodair_app.dart';

/// Base URL for loading Kodair HTML apps remotely
const String kodairBaseUrl = 'https://kodair.us/';

/// Default sidebar apps — these are the factory defaults.
/// SidebarProvider clones these on first run, then user edits are persisted separately.
List<KodairApp> get defaultKodairApps => [
  KodairApp.builtIn(name: 'Weather', url: 'https://weatherscan.net', iconData: Icons.cloud, isWidget: true, position: 0),
  KodairApp.builtIn(name: 'Kostream', url: '${kodairBaseUrl}KodScan/KodScan.html', iconData: Icons.live_tv, isWidget: true, position: 1),
  KodairApp.builtIn(name: 'KodWeb', url: '${kodairBaseUrl}KodWeb/KodWeb.html', iconData: Icons.language, position: 2),
  KodairApp.builtIn(name: 'Texair', url: '${kodairBaseUrl}Texair/Texair.html', iconData: Icons.notes, position: 3),
  KodairApp.builtIn(name: 'Minecraft', url: '${kodairBaseUrl}Minecraft/Minecraft.html', iconData: Icons.videogame_asset, position: 4),
  KodairApp.builtIn(name: 'Chess', url: '${kodairBaseUrl}Chess/index.html', iconData: Icons.extension, position: 5),
  KodairApp.builtIn(name: 'KodPiano', url: '${kodairBaseUrl}KodPiano/KodPiano.html', iconData: Icons.piano, position: 6),
  KodairApp.builtIn(name: 'Kordle', url: '${kodairBaseUrl}Kordle/index.html', iconData: Icons.abc, position: 7),
  KodairApp.builtIn(name: 'Paint', url: '${kodairBaseUrl}jspaint/index.html', iconData: Icons.palette, position: 8),
  KodairApp.builtIn(name: 'KodRPS', url: '${kodairBaseUrl}KodRPS/KodRPS.html', iconData: Icons.back_hand, position: 9),
  KodairApp.builtIn(name: 'Kodcom', url: '${kodairBaseUrl}Kodcom/Kodcom.html', iconData: Icons.terminal, position: 10),
  KodairApp.builtIn(name: 'KodEditor', url: '${kodairBaseUrl}KodEditor/KodEditor.html', iconData: Icons.code, position: 11),
  KodairApp.builtIn(name: 'Kodsly', url: '${kodairBaseUrl}Kodsly/Kodsly.html', iconData: Icons.security, position: 12),
  KodairApp.builtIn(name: 'Blog', url: 'https://blog.kodair.us', iconData: Icons.article, position: 13),
  KodairApp.builtIn(name: 'Cub3', url: '${kodairBaseUrl}Cub3/index.html', iconData: Icons.view_in_ar, position: 14),
  KodairApp.builtIn(name: 'Calculator', url: '${kodairBaseUrl}numworks/simulator.html', iconData: Icons.calculate, position: 15),
  KodairApp.builtIn(name: 'Pixel Art', url: '${kodairBaseUrl}pixel-monk/index.html', iconData: Icons.grid_on, position: 16),
  KodairApp.builtIn(name: 'GenMusic', url: '${kodairBaseUrl}genmusic/index.html', iconData: Icons.music_note, position: 17),
  KodairApp.builtIn(name: 'Marbles', url: '${kodairBaseUrl}MusicMarbles/index.html', iconData: Icons.circle, position: 18),
  KodairApp.builtIn(name: 'Odra', url: '${kodairBaseUrl}odra/index.html', iconData: Icons.nightlight_round, position: 19),
  KodairApp.builtIn(name: 'Nixie', url: '${kodairBaseUrl}Nixie/Nixie.html', iconData: Icons.bolt, position: 20),
  KodairApp.builtIn(name: 'KodTodo', url: '${kodairBaseUrl}KodTodo/index.html', iconData: Icons.checklist, position: 21),
  KodairApp.builtIn(name: 'AirStore', url: '${kodairBaseUrl}AirStore2.html', iconData: Icons.storefront, position: 22),
];

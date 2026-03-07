import 'package:flutter/material.dart';
import '../models/kodair_app.dart';

/// Base URL for loading Kodair HTML apps remotely
const String kodairBaseUrl = 'https://kodair.us/';

/// All sidebar apps extracted from the original index.html
final List<KodairApp> kodairApps = [
  const KodairApp(
    name: 'Weather',
    url: 'https://weatherscan.net',
    iconData: Icons.cloud,
    isWidget: true,
  ),
  const KodairApp(
    name: 'Kostream',
    url: '${kodairBaseUrl}KodScan/KodScan.html',
    iconData: Icons.live_tv,
    isWidget: true,
  ),
  const KodairApp(
    name: 'KodWeb',
    url: '${kodairBaseUrl}KodWeb/KodWeb.html',
    iconData: Icons.language,
  ),
  const KodairApp(
    name: 'Texair',
    url: '${kodairBaseUrl}Texair/Texair.html',
    iconData: Icons.notes,
  ),
  const KodairApp(
    name: 'Minecraft',
    url: '${kodairBaseUrl}Minecraft/Minecraft.html',
    iconData: Icons.videogame_asset,
  ),
  const KodairApp(
    name: 'Chess',
    url: '${kodairBaseUrl}Chess/index.html',
    iconData: Icons.extension,
  ),
  const KodairApp(
    name: 'KodPiano',
    url: '${kodairBaseUrl}KodPiano/KodPiano.html',
    iconData: Icons.piano,
  ),
  const KodairApp(
    name: 'Kordle',
    url: '${kodairBaseUrl}Kordle/index.html',
    iconData: Icons.abc,
  ),
  const KodairApp(
    name: 'Paint',
    url: '${kodairBaseUrl}jspaint/index.html',
    iconData: Icons.palette,
  ),
  const KodairApp(
    name: 'KodRPS',
    url: '${kodairBaseUrl}KodRPS/KodRPS.html',
    iconData: Icons.back_hand,
  ),
  const KodairApp(
    name: 'Kodcom',
    url: '${kodairBaseUrl}Kodcom/Kodcom.html',
    iconData: Icons.terminal,
  ),
  const KodairApp(
    name: 'KodEditor',
    url: '${kodairBaseUrl}KodEditor/KodEditor.html',
    iconData: Icons.code,
  ),
  const KodairApp(
    name: 'Kodsly',
    url: '${kodairBaseUrl}Kodsly/Kodsly.html',
    iconData: Icons.security,
  ),
  const KodairApp(
    name: 'Blog',
    url: 'https://blog.kodair.us',
    iconData: Icons.article,
  ),
  const KodairApp(
    name: 'Cub3',
    url: '${kodairBaseUrl}Cub3/index.html',
    iconData: Icons.view_in_ar,
  ),
  const KodairApp(
    name: 'Calculator',
    url: '${kodairBaseUrl}numworks/simulator.html',
    iconData: Icons.calculate,
  ),
  const KodairApp(
    name: 'Pixel Art',
    url: '${kodairBaseUrl}pixel-monk/index.html',
    iconData: Icons.grid_on,
  ),
  const KodairApp(
    name: 'GenMusic',
    url: '${kodairBaseUrl}genmusic/index.html',
    iconData: Icons.music_note,
  ),
  const KodairApp(
    name: 'Marbles',
    url: '${kodairBaseUrl}MusicMarbles/index.html',
    iconData: Icons.circle,
  ),
  const KodairApp(
    name: 'Odra',
    url: '${kodairBaseUrl}odra/index.html',
    iconData: Icons.nightlight_round,
  ),
  const KodairApp(
    name: 'Nixie',
    url: '${kodairBaseUrl}Nixie/Nixie.html',
    iconData: Icons.bolt,
  ),
  const KodairApp(
    name: 'KodTodo',
    url: '${kodairBaseUrl}KodTodo/index.html',
    iconData: Icons.checklist,
  ),
  const KodairApp(
    name: 'AirStore',
    url: '${kodairBaseUrl}AirStore2.html',
    iconData: Icons.storefront,
  ),
];

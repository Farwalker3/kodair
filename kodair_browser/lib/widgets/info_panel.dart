import 'package:flutter/material.dart';
import '../theme/kodair_theme.dart';

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key});

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
      child: ClipRect(
        child: BackdropFilter(
          filter: ColorFilter.mode(
            Colors.white.withAlpha(10),
            BlendMode.srcOver,
          ),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildUpdateCard('About', 'Current Version: Alpha 4.3'),
              _buildUpdateCard(
                'Alpha V4.3 (5/2/25)',
                'The Screen Update: Added multiple screen effects, an accessibility tool, and fullscreen settings. The Kostream, Minecraft clone, and weather apps have been updated, and there is now a chess app.',
              ),
              _buildUpdateCard(
                'Alpha V4.2 (4/29/24)',
                'The Musical Update: Added three new musical apps — music generation, music marbles, and dream music. A nixie tube clock has been added as well.',
              ),
              _buildUpdateCard(
                'Alpha V4.1 (4/28/24)',
                'The BeeFax Update: Added the BeeFax app (Ceefax/Weatherscan-Esque Clone) and musicode for composing/analyzing music.',
              ),
              _buildUpdateCard(
                'Alpha V4.0 (4/27/24)',
                'The Kodar Update: Added the Kodar radar weather app and a globe made of its own code in the KodEDU app.',
              ),
              _buildUpdateCard(
                'Alpha V3.9 (4/26/24)',
                'The Pixel Update: A 3D pixel art app has been added. The story planner app is now editable.',
              ),
              _buildUpdateCard(
                'Alpha V3.8 (4/25/24)',
                'The RPS Update: Rock Paper Scissors game added, developed by Coley Hughes Hatt. Mini piano added to KodPiano.',
              ),
              _buildUpdateCard(
                'Alpha V3.7 (4/24/24)',
                'The Settings Update: Introducing settings app. You can now change the favicon of the website.',
              ),
              _buildUpdateCard(
                'Alpha V3.6 (4/23/24)',
                'The To-do Update: New to-do application added, KodWeb home opens IRIS search engine.',
              ),
              _buildUpdateCard(
                'Alpha V3.5 (4/22/24)',
                'The Airsponsor Update: Introducing Airsponsor, your platform for authentic product endorsements.',
              ),
              _buildUpdateCard(
                'Alpha V3.0 — V3.4',
                'Blog, Live user count, Broadcast channel API, Minecraft update, and AirStore updates.',
              ),
              _buildUpdateCard(
                'Alpha V1.0 — V2.9',
                'Utilities, developer tools, Kordle, KodPiano, Kodoshop, Kodcut, Kodex, and many more foundational apps.',
              ),
              _buildUpdateCard(
                'Alpha V0.0 — V0.9',
                'The very beginning: Initial release with radio, TV, drawing, RSS, education, password manager, and exchange apps.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KodairTheme.searchInputBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Kodair Is Developed By',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'John C. Barr',
                      style: TextStyle(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateCard(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: KodairTheme.searchInputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFCCCCCC),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              body,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

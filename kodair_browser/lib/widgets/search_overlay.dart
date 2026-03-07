import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/browser_provider.dart';
import '../theme/kodair_theme.dart';

class SearchOverlay extends StatefulWidget {
  const SearchOverlay({super.key});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  Timer? _debounce;

  // Quick answer state
  String? _answerTitle;
  String? _answerText;
  String? _answerSource;
  String? _answerUrl;
  bool _answerLoading = false;
  String? _lastQuery;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward().then((_) {
      // Explicitly request focus after animation to guarantee keyboard input
      _focusNode.requestFocus();
    });
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final text = _controller.text.trim();
      if (text.isNotEmpty &&
          text != _lastQuery &&
          !text.startsWith('http') &&
          !text.startsWith('www.') &&
          (text.contains(' ') || !text.contains('.'))) {
        _fetchQuickAnswer(text);
      } else if (text.isEmpty) {
        setState(() {
          _answerTitle = null;
          _answerText = null;
          _answerSource = null;
          _answerUrl = null;
          _lastQuery = null;
        });
      }
    });
  }

  /// Fetch a quick answer from Wikipedia Summary API, then DuckDuckGo as fallback
  Future<void> _fetchQuickAnswer(String query) async {
    _lastQuery = query;
    setState(() {
      _answerLoading = true;
      _answerTitle = null;
      _answerText = null;
      _answerSource = null;
      _answerUrl = null;
    });

    // Try Wikipedia first
    try {
      final wikiUrl = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(query)}',
      );
      final wikiResp = await http.get(wikiUrl, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 4));

      if (mounted && _lastQuery == query && wikiResp.statusCode == 200) {
        final data = json.decode(wikiResp.body);
        final extract = data['extract'] as String?;
        final title = data['title'] as String?;
        final pageUrl = data['content_urls']?['desktop']?['page'] as String?;

        if (extract != null && extract.isNotEmpty && extract.length > 20) {
          setState(() {
            _answerTitle = title ?? query;
            _answerText = extract.length > 300
                ? '${extract.substring(0, 300)}...'
                : extract;
            _answerSource = 'Wikipedia';
            _answerUrl = pageUrl;
            _answerLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback: DuckDuckGo Instant Answer API
    try {
      final ddgUrl = Uri.parse(
        'https://api.duckduckgo.com/?q=${Uri.encodeComponent(query)}&format=json&no_html=1&skip_disambig=1',
      );
      final ddgResp = await http.get(ddgUrl).timeout(const Duration(seconds: 4));

      if (mounted && _lastQuery == query && ddgResp.statusCode == 200) {
        final data = json.decode(ddgResp.body);
        final abstract = data['AbstractText'] as String?;
        final heading = data['Heading'] as String?;
        final source = data['AbstractSource'] as String?;
        final url = data['AbstractURL'] as String?;

        if (abstract != null && abstract.isNotEmpty) {
          setState(() {
            _answerTitle = heading ?? query;
            _answerText = abstract.length > 300
                ? '${abstract.substring(0, 300)}...'
                : abstract;
            _answerSource = source ?? 'DuckDuckGo';
            _answerUrl = url;
            _answerLoading = false;
          });
          return;
        }

        // Try DuckDuckGo Answer field
        final answer = data['Answer'] as String?;
        if (answer != null && answer.isNotEmpty) {
          setState(() {
            _answerTitle = heading ?? query;
            _answerText = answer;
            _answerSource = 'Instant Answer';
            _answerUrl = null;
            _answerLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    // No answer found
    if (mounted && _lastQuery == query) {
      setState(() => _answerLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final browser = context.read<BrowserProvider>();
    final screenSize = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeAnim,
      child: GestureDetector(
        onTap: () => browser.toggleSearch(),
        child: Container(
          color: Colors.black.withAlpha(80),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: screenSize.width * 0.55,
                  constraints: const BoxConstraints(maxHeight: 500),
                  decoration: BoxDecoration(
                    color: KodairTheme.searchBg,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(80),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search input
                      _buildSearchInput(browser),

                      // Quick answer card (like Siri in Spotlight)
                      if (_answerLoading) _buildAnswerLoading(),
                      if (_answerText != null) _buildAnswerCard(browser),

                      // Quick actions
                      _buildQuickActions(browser),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput(BrowserProvider browser) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: KodairTheme.searchInputBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Search or enter URL...',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 16),
                border: InputBorder.none,
              ),
              onSubmitted: (value) => _handleSearch(value, browser),
            ),
          ),
          IconButton(
            onPressed: () => browser.toggleSearch(),
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }

  /// Quick answer card — like Siri answers in macOS Spotlight
  Widget _buildAnswerCard(BrowserProvider browser) {
    return GestureDetector(
      onTap: () {
        if (_answerUrl != null) {
          browser.navigateToApp(_answerUrl!, name: _answerTitle ?? '');
          browser.toggleSearch();
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A3E), Color(0xFF2A2A50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF4A90D9).withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with source badge
            Row(
              children: [
                Icon(
                  _answerSource == 'Wikipedia'
                      ? Icons.menu_book_rounded
                      : Icons.auto_awesome,
                  size: 16,
                  color: const Color(0xFF4A90D9),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _answerTitle ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90D9).withAlpha(40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _answerSource ?? '',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF4A90D9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Answer text
            Text(
              _answerText!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                height: 1.4,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            if (_answerUrl != null) ...[
              const SizedBox(height: 6),
              Text(
                'Click to read more →',
                style: TextStyle(
                  fontSize: 10,
                  color: const Color(0xFF4A90D9).withAlpha(180),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerLoading() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A3E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90D9)),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Looking up answer...',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BrowserProvider browser) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _qa('Google', Icons.search,
              () => _nav('https://google.com', browser)),
          _qa('YouTube', Icons.play_circle,
              () => _nav('https://youtube.com', browser)),
          _qa('GitHub', Icons.code,
              () => _nav('https://github.com', browser)),
          _qa('Reddit', Icons.forum,
              () => _nav('https://reddit.com', browser)),
          _qa('Wikipedia', Icons.menu_book,
              () => _nav('https://wikipedia.org', browser)),
          _qa('AirStore', Icons.storefront,
              () => _nav('https://kodair.us/AirStore2.html', browser)),
          _qa('Twitter', Icons.alternate_email,
              () => _nav('https://x.com', browser)),
          _qa('ChatGPT', Icons.smart_toy,
              () => _nav('https://chat.openai.com', browser)),
        ],
      ),
    );
  }

  Widget _qa(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: KodairTheme.appButtonBg.withAlpha(150),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _handleSearch(String value, BrowserProvider browser) {
    if (value.isEmpty) return;
    String url;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      url = value;
    } else if (value.contains('.') && !value.contains(' ')) {
      url = 'https://$value';
    } else {
      url = 'https://www.google.com/search?q=${Uri.encodeComponent(value)}';
    }
    // navigateToApp already closes search via _closeAllPanels(), so don't toggle
    browser.navigateToApp(url, name: value);
  }

  void _nav(String url, BrowserProvider browser) {
    browser.navigateToApp(url);
    browser.toggleSearch();
  }
}

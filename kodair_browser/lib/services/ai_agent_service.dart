import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single action the AI agent wants to perform.
class AgentAction {
  final String type; // click, type, navigate, scroll, extract, done, error
  final String selector; // CSS selector or text match
  final String value; // text to type, URL to navigate, etc.
  final String reasoning; // why the agent chose this action

  const AgentAction({
    required this.type,
    this.selector = '',
    this.value = '',
    this.reasoning = '',
  });

  @override
  String toString() => '[$type] ${selector.isNotEmpty ? "$selector " : ""}${value.isNotEmpty ? "→ $value " : ""}($reasoning)';
}

/// Parsed user intent from natural language.
class _ParsedIntent {
  final String action; // click, type, navigate, scroll, find, read, submit
  final String target; // what to click/find/type into
  final String value;  // what to type / URL to go to

  _ParsedIntent(this.action, this.target, this.value);
}

/// The AI Browser Agent — works WITHOUT any API key.
/// Uses smart keyword matching + DOM analysis to understand and execute commands.
class AiAgentService {
  /// Extract a simplified DOM representation from the current page.
  static Future<String> extractPageContext(InAppWebViewController controller) async {
    try {
      final result = await controller.evaluateJavascript(source: '''
        (function() {
          var out = [];
          out.push("URL: " + location.href);
          out.push("Title: " + document.title);

          // Collect interactive elements
          var items = document.querySelectorAll('a, button, input, textarea, select, [role="button"], [onclick]');
          var interactives = [];
          for (var i = 0; i < Math.min(items.length, 80); i++) {
            var el = items[i];
            var rect = el.getBoundingClientRect();
            if (rect.width === 0 || rect.height === 0) continue;

            var tag = el.tagName.toLowerCase();
            var text = (el.innerText || el.value || el.placeholder || el.title || el.alt || el.ariaLabel || '').trim().substring(0, 80);
            var id = el.id || '';
            var name = el.name || '';
            var type = el.type || '';
            var href = el.href || '';
            var cls = el.className && typeof el.className === 'string' ? el.className : '';

            interactives.push(JSON.stringify({
              idx: i,
              tag: tag,
              text: text,
              id: id,
              name: name,
              type: type,
              href: href.substring(0, 200),
              cls: cls.substring(0, 100)
            }));
          }

          out.push("ELEMENTS:" + interactives.join("|||"));

          // Visible text excerpt
          var bodyText = (document.body.innerText || '').substring(0, 3000);
          out.push("TEXT:" + bodyText);

          return out.join("\\n---\\n");
        })();
      ''');
      return result?.toString() ?? '';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Parse a page context string into structured data.
  static Map<String, dynamic> _parsePage(String rawContext) {
    final parts = rawContext.split('\n---\n');
    String url = '', title = '';
    List<Map<String, dynamic>> elements = [];
    String bodyText = '';

    for (final part in parts) {
      if (part.startsWith('URL: ')) url = part.substring(5);
      if (part.startsWith('Title: ')) title = part.substring(7);
      if (part.startsWith('ELEMENTS:')) {
        final jsonStrs = part.substring(9).split('|||');
        for (final js in jsonStrs) {
          try { elements.add(jsonDecode(js)); } catch (_) {}
        }
      }
      if (part.startsWith('TEXT:')) bodyText = part.substring(5);
    }

    return {'url': url, 'title': title, 'elements': elements, 'text': bodyText};
  }

  /// Parse natural language prompt into a structured intent.
  static _ParsedIntent parseIntent(String prompt) {
    final p = prompt.toLowerCase().trim();

    // Navigate patterns
    final navPatterns = [
      RegExp(r'(?:go to|navigate to|open|visit|load)\s+(.+)', caseSensitive: false),
      RegExp(r'(?:take me to)\s+(.+)', caseSensitive: false),
    ];
    for (final pat in navPatterns) {
      final m = pat.firstMatch(p);
      if (m != null) {
        var target = m.group(1)!.trim();
        if (!target.startsWith('http')) target = 'https://$target';
        return _ParsedIntent('navigate', '', target);
      }
    }

    // Search patterns
    final searchPatterns = [
      RegExp(r'search (?:for |)(.+)', caseSensitive: false),
      RegExp(r'look up (.+)', caseSensitive: false),
      RegExp(r'google (.+)', caseSensitive: false),
      RegExp(r'find (.+)', caseSensitive: false),
    ];
    for (final pat in searchPatterns) {
      final m = pat.firstMatch(p);
      if (m != null) return _ParsedIntent('search', '', m.group(1)!.trim());
    }

    // Type patterns
    final typePatterns = [
      RegExp(r"""type ["'](.+?)["'] (?:in|into|on) (.+)""", caseSensitive: false),
      RegExp(r'type (.+?) (?:in|into|on) (.+)', caseSensitive: false),
      RegExp(r"""enter ["'](.+?)["'] (?:in|into|on) (.+)""", caseSensitive: false),
      RegExp(r"""fill (?:in |)(.+?) with ["']?(.+?)["']?$""", caseSensitive: false),
    ];
    for (final pat in typePatterns) {
      final m = pat.firstMatch(p);
      if (m != null) return _ParsedIntent('type', m.group(2)!.trim(), m.group(1)!.trim());
    }

    // Click patterns
    final clickPatterns = [
      RegExp(r'click (?:on |the |)(.+)', caseSensitive: false),
      RegExp(r'press (?:the |)(.+)', caseSensitive: false),
      RegExp(r'tap (?:on |the |)(.+)', caseSensitive: false),
      RegExp(r'hit (?:the |)(.+)', caseSensitive: false),
      RegExp(r'select (?:the |)(.+)', caseSensitive: false),
    ];
    for (final pat in clickPatterns) {
      final m = pat.firstMatch(p);
      if (m != null) return _ParsedIntent('click', m.group(1)!.trim(), '');
    }

    // Scroll patterns
    if (p.contains('scroll down') || p.contains('page down')) return _ParsedIntent('scroll', '', 'down');
    if (p.contains('scroll up') || p.contains('page up')) return _ParsedIntent('scroll', '', 'up');
    if (p.contains('scroll') || p.contains('bottom')) return _ParsedIntent('scroll', '', 'down');
    if (p.contains('top')) return _ParsedIntent('scroll', '', 'up');

    // Go back / forward
    if (p.contains('go back') || p.contains('back')) return _ParsedIntent('back', '', '');
    if (p.contains('go forward') || p.contains('forward')) return _ParsedIntent('forward', '', '');

    // Read / extract
    if (p.contains('read') || p.contains('what does') || p.contains('extract') || p.contains('get text')) {
      return _ParsedIntent('read', '', '');
    }

    // Submit
    if (p.contains('submit') || p.contains('enter') || p.contains('send')) {
      return _ParsedIntent('submit', '', '');
    }

    // Default: try to click whatever they said
    return _ParsedIntent('click', p, '');
  }

  /// Fuzzy-match an element target against the DOM elements.
  static int? _findElement(List<Map<String, dynamic>> elements, String target) {
    final t = target.toLowerCase().trim().replaceAll(RegExp(r"""["']"""), '');
    if (t.isEmpty) return null;

    // Exact text match
    for (int i = 0; i < elements.length; i++) {
      final el = elements[i];
      final text = (el['text'] as String? ?? '').toLowerCase();
      if (text == t) return el['idx'] as int;
    }

    // Contains match
    for (int i = 0; i < elements.length; i++) {
      final el = elements[i];
      final text = (el['text'] as String? ?? '').toLowerCase();
      if (text.contains(t) || t.contains(text)) return el['idx'] as int;
    }

    // ID or name match
    for (int i = 0; i < elements.length; i++) {
      final el = elements[i];
      final id = (el['id'] as String? ?? '').toLowerCase();
      final name = (el['name'] as String? ?? '').toLowerCase();
      if (id.contains(t) || name.contains(t) || t.contains(id) || t.contains(name)) {
        return el['idx'] as int;
      }
    }

    // Placeholder / class match
    for (int i = 0; i < elements.length; i++) {
      final el = elements[i];
      final cls = (el['cls'] as String? ?? '').toLowerCase();
      if (cls.contains(t)) return el['idx'] as int;
    }

    // Type-based match (e.g., "search box" → input[type=search] or input[type=text])
    if (t.contains('search') || t.contains('query')) {
      for (int i = 0; i < elements.length; i++) {
        final el = elements[i];
        final tag = el['tag'] as String? ?? '';
        final type = (el['type'] as String? ?? '').toLowerCase();
        final name = (el['name'] as String? ?? '').toLowerCase();
        if (tag == 'input' && (type == 'search' || type == 'text' || name.contains('search') || name.contains('q'))) {
          return el['idx'] as int;
        }
      }
    }

    // Button-like match
    if (t.contains('button') || t.contains('submit') || t.contains('login') || t.contains('sign')) {
      for (int i = 0; i < elements.length; i++) {
        final el = elements[i];
        final tag = el['tag'] as String? ?? '';
        final type = (el['type'] as String? ?? '').toLowerCase();
        if (tag == 'button' || type == 'submit') return el['idx'] as int;
      }
    }

    return null;
  }

  /// Decide the next action based on parsed intent + page context.
  static AgentAction decideAction(String userGoal, String pageContext, List<AgentAction> history) {
    final intent = parseIntent(userGoal);
    final page = _parsePage(pageContext);
    final elements = page['elements'] as List<Map<String, dynamic>>;

    switch (intent.action) {
      case 'navigate':
        return AgentAction(type: 'navigate', value: intent.value, reasoning: 'Going to ${intent.value}');

      case 'search':
        // Find the search input
        final searchIdx = _findElement(elements, 'search');
        if (searchIdx != null) {
          if (history.isEmpty) {
            return AgentAction(type: 'type', selector: '$searchIdx', value: intent.value, reasoning: 'Typing "${intent.value}" in search box');
          } else if (history.length == 1) {
            return AgentAction(type: 'submit', selector: '$searchIdx', value: '', reasoning: 'Submitting search');
          } else {
            return AgentAction(type: 'done', reasoning: 'Search submitted for "${intent.value}"');
          }
        }
        // Fallback: navigate to google search
        return AgentAction(
          type: 'navigate',
          value: 'https://www.google.com/search?q=${Uri.encodeComponent(intent.value)}',
          reasoning: 'No search box found, using Google',
        );

      case 'click':
        final idx = _findElement(elements, intent.target);
        if (idx != null) {
          return AgentAction(type: 'click', selector: '$idx', reasoning: 'Clicking element matching "${intent.target}"');
        }
        return AgentAction(type: 'error', reasoning: 'Could not find element matching "${intent.target}" on this page');

      case 'type':
        final idx = _findElement(elements, intent.target);
        if (idx != null) {
          return AgentAction(type: 'type', selector: '$idx', value: intent.value, reasoning: 'Typing "${intent.value}" into "${intent.target}"');
        }
        return AgentAction(type: 'error', reasoning: 'Could not find input matching "${intent.target}"');

      case 'scroll':
        return AgentAction(type: 'scroll', value: intent.value, reasoning: 'Scrolling ${intent.value}');

      case 'back':
        return AgentAction(type: 'back', reasoning: 'Going back');

      case 'forward':
        return AgentAction(type: 'forward', reasoning: 'Going forward');

      case 'read':
        final text = (page['text'] as String? ?? '').substring(0, 500);
        return AgentAction(type: 'done', reasoning: 'Page content: $text');

      case 'submit':
        return AgentAction(type: 'submit', selector: '', reasoning: 'Submitting form');

      default:
        return AgentAction(type: 'error', reasoning: 'I don\'t understand that command. Try: "click X", "type X in Y", "go to URL", "search for X", "scroll down"');
    }
  }

  /// Execute an action on the WebView by element index.
  static Future<String> executeAction(InAppWebViewController controller, AgentAction action) async {
    try {
      switch (action.type) {
        case 'click':
          final idx = int.tryParse(action.selector);
          final result = await controller.evaluateJavascript(source: '''
            (function() {
              var items = document.querySelectorAll('a, button, input, textarea, select, [role="button"], [onclick]');
              var visible = [];
              for (var i = 0; i < items.length; i++) {
                var rect = items[i].getBoundingClientRect();
                if (rect.width > 0 && rect.height > 0) visible.push(items[i]);
              }
              var el = visible[${idx ?? 0}];
              if (el) {
                el.scrollIntoView({behavior: 'smooth', block: 'center'});
                setTimeout(function() { el.click(); }, 300);
                return 'Clicked: ' + (el.innerText || el.tagName).substring(0, 60);
              }
              return 'Element not found at index ${idx ?? 0}';
            })();
          ''');
          return result?.toString() ?? 'Click executed';

        case 'type':
          final idx = int.tryParse(action.selector);
          final result = await controller.evaluateJavascript(source: '''
            (function() {
              var items = document.querySelectorAll('a, button, input, textarea, select, [role="button"], [onclick]');
              var visible = [];
              for (var i = 0; i < items.length; i++) {
                var rect = items[i].getBoundingClientRect();
                if (rect.width > 0 && rect.height > 0) visible.push(items[i]);
              }
              var el = visible[${idx ?? 0}];
              if (el) {
                el.focus();
                el.value = '${_escapeJs(action.value)}';
                el.dispatchEvent(new Event('input', {bubbles: true}));
                el.dispatchEvent(new Event('change', {bubbles: true}));
                return 'Typed: "${_escapeJs(action.value)}" into ' + (el.name || el.id || el.tagName);
              }
              return 'Input not found at index ${idx ?? 0}';
            })();
          ''');
          return result?.toString() ?? 'Type executed';

        case 'submit':
          final result = await controller.evaluateJavascript(source: '''
            (function() {
              var form = document.querySelector('form');
              if (form) { form.submit(); return 'Form submitted'; }
              // Try pressing Enter on focused element
              var focused = document.activeElement;
              if (focused) {
                focused.dispatchEvent(new KeyboardEvent('keydown', {key: 'Enter', keyCode: 13, bubbles: true}));
                focused.dispatchEvent(new KeyboardEvent('keypress', {key: 'Enter', keyCode: 13, bubbles: true}));
                focused.dispatchEvent(new KeyboardEvent('keyup', {key: 'Enter', keyCode: 13, bubbles: true}));
                return 'Enter key sent';
              }
              return 'No form or focused element found';
            })();
          ''');
          return result?.toString() ?? 'Submit executed';

        case 'navigate':
          await controller.loadUrl(urlRequest: URLRequest(url: WebUri(action.value)));
          return 'Navigating to: ${action.value}';

        case 'scroll':
          final direction = action.value.contains('up') ? -500 : 500;
          await controller.evaluateJavascript(source: 'window.scrollBy({top: $direction, behavior: "smooth"});');
          return 'Scrolled ${direction > 0 ? "down" : "up"}';

        case 'back':
          await controller.goBack();
          return 'Went back';

        case 'forward':
          await controller.goForward();
          return 'Went forward';

        case 'done':
          return action.reasoning;

        default:
          return 'Unknown action: ${action.type}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  static String _escapeJs(String input) {
    return input.replaceAll('\\', '\\\\').replaceAll("'", "\\'").replaceAll('"', '\\"').replaceAll('\n', '\\n');
  }
}

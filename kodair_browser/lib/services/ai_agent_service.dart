import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single action the AI agent wants to perform.
class AgentAction {
  final String type; // click, type, navigate, scroll, extract, done, error
  final String selector; // CSS selector for click/type
  final String value; // text to type, URL to navigate, etc.
  final String reasoning; // why the agent chose this action

  const AgentAction({
    required this.type,
    this.selector = '',
    this.value = '',
    this.reasoning = '',
  });

  factory AgentAction.fromJson(Map<String, dynamic> json) {
    return AgentAction(
      type: json['action'] as String? ?? 'error',
      selector: json['selector'] as String? ?? '',
      value: json['value'] as String? ?? '',
      reasoning: json['reasoning'] as String? ?? '',
    );
  }

  @override
  String toString() => '[$type] ${selector.isNotEmpty ? "$selector " : ""}${value.isNotEmpty ? "→ $value " : ""}($reasoning)';
}

/// The AI Browser Agent service — handles DOM extraction, LLM calls, and action execution.
class AiAgentService {
  static const _apiKeyPref = 'gemini_api_key';

  GenerativeModel? _model;
  String _apiKey = '';

  /// Load API key from storage.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyPref) ?? '';
    if (_apiKey.isNotEmpty) {
      _initModel();
    }
  }

  void _initModel() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 1024,
      ),
    );
  }

  bool get hasApiKey => _apiKey.isNotEmpty;

  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, _apiKey);
    if (_apiKey.isNotEmpty) _initModel();
  }

  /// Extract a simplified DOM representation from the current page.
  static Future<String> extractPageContext(InAppWebViewController controller) async {
    try {
      final result = await controller.evaluateJavascript(source: '''
        (function() {
          var out = [];
          out.push("URL: " + location.href);
          out.push("Title: " + document.title);
          out.push("");

          // Collect interactive elements
          var items = document.querySelectorAll('a, button, input, textarea, select, [role="button"], [onclick]');
          var interactives = [];
          for (var i = 0; i < Math.min(items.length, 60); i++) {
            var el = items[i];
            var rect = el.getBoundingClientRect();
            if (rect.width === 0 || rect.height === 0) continue;

            var tag = el.tagName.toLowerCase();
            var text = (el.innerText || el.value || el.placeholder || el.title || el.alt || '').trim().substring(0, 80);
            var id = el.id ? '#' + el.id : '';
            var cls = el.className && typeof el.className === 'string' ? '.' + el.className.split(' ').filter(Boolean).slice(0,2).join('.') : '';
            var href = el.href ? ' href=' + el.href.substring(0, 100) : '';
            var type = el.type ? ' type=' + el.type : '';

            // Build a usable CSS selector
            var selector = tag;
            if (el.id) selector = '#' + el.id;
            else if (el.name) selector = tag + '[name="' + el.name + '"]';
            else if (text.length > 0 && text.length < 30) selector = tag + ':has-text("' + text.substring(0, 25) + '")';
            else selector = tag + id + cls;

            interactives.push('[' + i + '] ' + tag + id + cls + type + href + ' "' + text + '" → ' + selector);
          }

          out.push("INTERACTIVE ELEMENTS (" + interactives.length + "):");
          out.push(interactives.join("\\n"));
          out.push("");

          // Visible text excerpt
          var bodyText = (document.body.innerText || '').substring(0, 2000);
          out.push("VISIBLE TEXT (excerpt):");
          out.push(bodyText);

          return out.join("\\n");
        })();
      ''');
      return result?.toString() ?? 'Could not extract page context.';
    } catch (e) {
      return 'Error extracting page: $e';
    }
  }

  /// Ask the LLM to decide the next action.
  Future<AgentAction> decideNextAction(String userGoal, String pageContext, List<AgentAction> previousActions) async {
    if (_model == null) {
      return const AgentAction(type: 'error', reasoning: 'No API key configured. Go to Settings to add your free Gemini API key.');
    }

    final historyStr = previousActions.isEmpty
        ? 'None yet.'
        : previousActions.map((a) => '  - ${a.toString()}').join('\n');

    final prompt = '''You are a browser automation agent. The user wants you to perform a task on a web page.

USER GOAL: $userGoal

CURRENT PAGE CONTEXT:
$pageContext

PREVIOUS ACTIONS TAKEN:
$historyStr

Decide the NEXT single action to take. Respond with ONLY valid JSON (no markdown, no explanation):
{
  "action": "click" | "type" | "navigate" | "scroll" | "wait" | "done",
  "selector": "CSS selector of the element (for click/type actions)",
  "value": "text to type (for type action) or URL (for navigate) or direction (for scroll: up/down)",
  "reasoning": "brief explanation of why you chose this action"
}

Rules:
- If the task is complete, use action "done" with a summary in reasoning.
- If you need to click something, use the CSS selector from the interactive elements list.
- If you need to navigate to a URL, use action "navigate" with the full URL.
- Only take ONE action at a time.
- Never perform dangerous actions (delete accounts, make purchases, submit sensitive forms).
- If you're stuck or the page doesn't have what's needed, use "done" with an explanation.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(text);
      if (jsonMatch == null) {
        return AgentAction(type: 'error', reasoning: 'LLM returned invalid response: ${text.substring(0, 100)}');
      }

      final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      return AgentAction.fromJson(data);
    } catch (e) {
      return AgentAction(type: 'error', reasoning: 'LLM error: $e');
    }
  }

  /// Execute an action on the WebView.
  static Future<String> executeAction(InAppWebViewController controller, AgentAction action) async {
    try {
      switch (action.type) {
        case 'click':
          final result = await controller.evaluateJavascript(source: '''
            (function() {
              // Try direct selector first
              var el = document.querySelector('${_escapeJs(action.selector)}');
              
              // Fallback: try finding by text content
              if (!el) {
                var all = document.querySelectorAll('a, button, [role="button"]');
                for (var i = 0; i < all.length; i++) {
                  if (all[i].innerText && all[i].innerText.trim().includes('${_escapeJs(action.value)}')) {
                    el = all[i];
                    break;
                  }
                }
              }
              
              if (el) {
                el.scrollIntoView({behavior: 'smooth', block: 'center'});
                el.click();
                return 'Clicked: ' + (el.innerText || el.tagName).substring(0, 50);
              }
              return 'Element not found: ${_escapeJs(action.selector)}';
            })();
          ''');
          return result?.toString() ?? 'Click executed';

        case 'type':
          final result = await controller.evaluateJavascript(source: '''
            (function() {
              var el = document.querySelector('${_escapeJs(action.selector)}');
              if (el) {
                el.focus();
                el.value = '${_escapeJs(action.value)}';
                el.dispatchEvent(new Event('input', {bubbles: true}));
                el.dispatchEvent(new Event('change', {bubbles: true}));
                return 'Typed into: ' + (el.name || el.id || el.tagName);
              }
              return 'Input not found: ${_escapeJs(action.selector)}';
            })();
          ''');
          return result?.toString() ?? 'Type executed';

        case 'navigate':
          await controller.loadUrl(urlRequest: URLRequest(url: WebUri(action.value)));
          return 'Navigating to: ${action.value}';

        case 'scroll':
          final direction = action.value.toLowerCase().contains('up') ? -500 : 500;
          await controller.evaluateJavascript(source: 'window.scrollBy({top: $direction, behavior: "smooth"});');
          return 'Scrolled ${direction > 0 ? "down" : "up"}';

        case 'wait':
          await Future.delayed(const Duration(seconds: 2));
          return 'Waited 2 seconds';

        case 'done':
          return 'Task complete: ${action.reasoning}';

        default:
          return 'Unknown action: ${action.type}';
      }
    } catch (e) {
      return 'Execution error: $e';
    }
  }

  static String _escapeJs(String input) {
    return input.replaceAll('\\', '\\\\').replaceAll("'", "\\'").replaceAll('"', '\\"').replaceAll('\n', '\\n');
  }
}

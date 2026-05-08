import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/ai_agent_service.dart';

enum AgentState { idle, thinking, acting, paused, stopped, error }

/// A single entry in the agent's visible action log.
class AgentLogEntry {
  final String message;
  final AgentState state;
  final DateTime timestamp;

  AgentLogEntry(this.message, this.state) : timestamp = DateTime.now();
}

/// Provider managing the AI browser agent lifecycle.
class AiAgentProvider extends ChangeNotifier {
  final AiAgentService _service = AiAgentService();

  AgentState _state = AgentState.idle;
  final List<AgentLogEntry> _log = [];
  final List<AgentAction> _actionHistory = [];
  String _currentGoal = '';
  bool _shouldStop = false;
  bool _isPaused = false;
  int _stepCount = 0;
  static const int _maxSteps = 20; // Safety limit

  AgentState get state => _state;
  List<AgentLogEntry> get log => _log;
  String get currentGoal => _currentGoal;
  bool get hasApiKey => _service.hasApiKey;
  int get stepCount => _stepCount;

  AiAgentProvider() {
    _service.init();
  }

  Future<void> setApiKey(String key) async {
    await _service.setApiKey(key);
    notifyListeners();
  }

  /// Start the agent with a goal and a reference to the current WebView.
  Future<void> start(String goal, InAppWebViewController? controller) async {
    if (controller == null) {
      _addLog('No active page. Navigate to a page first.', AgentState.error);
      return;
    }
    if (!_service.hasApiKey) {
      _addLog('No API key. Add your free Gemini key in Settings → AI Agent.', AgentState.error);
      return;
    }
    if (goal.trim().isEmpty) {
      _addLog('Please enter a task for the agent.', AgentState.error);
      return;
    }

    _currentGoal = goal.trim();
    _shouldStop = false;
    _isPaused = false;
    _actionHistory.clear();
    _log.clear();
    _stepCount = 0;

    _addLog('🎯 Goal: $_currentGoal', AgentState.idle);
    _addLog('Starting agent...', AgentState.thinking);

    await _runLoop(controller);
  }

  Future<void> _runLoop(InAppWebViewController controller) async {
    while (!_shouldStop && _stepCount < _maxSteps) {
      // Check for pause
      while (_isPaused && !_shouldStop) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (_shouldStop) break;

      // Step 1: Think — extract page context
      _setState(AgentState.thinking);
      _addLog('📖 Reading page...', AgentState.thinking);

      await Future.delayed(const Duration(milliseconds: 500)); // Brief pause for UX

      final pageContext = await AiAgentService.extractPageContext(controller);

      if (_shouldStop) break;

      // Step 2: Decide — ask LLM for next action
      _addLog('🤔 Deciding next action...', AgentState.thinking);
      final action = await _service.decideNextAction(_currentGoal, pageContext, _actionHistory);

      if (_shouldStop) break;

      _actionHistory.add(action);
      _stepCount++;

      // Handle terminal states
      if (action.type == 'done') {
        _addLog('✅ ${action.reasoning}', AgentState.idle);
        _setState(AgentState.idle);
        return;
      }
      if (action.type == 'error') {
        _addLog('❌ ${action.reasoning}', AgentState.error);
        _setState(AgentState.error);
        return;
      }

      // Step 3: Act — execute the action
      _setState(AgentState.acting);
      _addLog('⚡ ${action.type.toUpperCase()}: ${action.selector.isNotEmpty ? action.selector : action.value}', AgentState.acting);
      _addLog('   💭 ${action.reasoning}', AgentState.acting);

      final result = await AiAgentService.executeAction(controller, action);
      _addLog('   → $result', AgentState.acting);

      // Wait for page to settle after action
      await Future.delayed(const Duration(seconds: 1));
    }

    if (_shouldStop) {
      _addLog('🛑 Agent stopped by user.', AgentState.stopped);
      _setState(AgentState.stopped);
    } else if (_stepCount >= _maxSteps) {
      _addLog('⚠️ Reached maximum steps ($_maxSteps). Stopping for safety.', AgentState.stopped);
      _setState(AgentState.stopped);
    }
  }

  void pause() {
    _isPaused = true;
    _addLog('⏸️ Paused.', AgentState.paused);
    _setState(AgentState.paused);
  }

  void resume() {
    _isPaused = false;
    _addLog('▶️ Resumed.', AgentState.thinking);
    _setState(AgentState.thinking);
  }

  void emergencyStop() {
    _shouldStop = true;
    _isPaused = false;
    _addLog('🚨 EMERGENCY STOP', AgentState.stopped);
    _setState(AgentState.stopped);
  }

  void reset() {
    _shouldStop = true;
    _isPaused = false;
    _log.clear();
    _actionHistory.clear();
    _currentGoal = '';
    _stepCount = 0;
    _setState(AgentState.idle);
  }

  void _setState(AgentState newState) {
    _state = newState;
    notifyListeners();
  }

  void _addLog(String message, AgentState state) {
    _log.add(AgentLogEntry(message, state));
    notifyListeners();
  }
}

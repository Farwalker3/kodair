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
/// Works WITHOUT any API key — uses built-in smart matching.
class AiAgentProvider extends ChangeNotifier {
  AgentState _state = AgentState.idle;
  final List<AgentLogEntry> _log = [];
  final List<AgentAction> _actionHistory = [];
  String _currentGoal = '';
  bool _shouldStop = false;
  int _stepCount = 0;
  static const int _maxSteps = 10;

  AgentState get state => _state;
  List<AgentLogEntry> get log => _log;
  String get currentGoal => _currentGoal;
  int get stepCount => _stepCount;

  /// Start the agent with a goal and a reference to the current WebView.
  Future<void> start(String goal, InAppWebViewController? controller) async {
    if (controller == null) {
      _addLog('No active page. Navigate to a page first.', AgentState.error);
      return;
    }
    if (goal.trim().isEmpty) {
      _addLog('Please tell me what to do.', AgentState.error);
      return;
    }

    _currentGoal = goal.trim();
    _shouldStop = false;
    _actionHistory.clear();
    _log.clear();
    _stepCount = 0;

    _addLog('🎯 Goal: $_currentGoal', AgentState.idle);
    _addLog('🧠 Analyzing command...', AgentState.thinking);

    await _runLoop(controller);
  }

  Future<void> _runLoop(InAppWebViewController controller) async {
    while (!_shouldStop && _stepCount < _maxSteps) {
      _setState(AgentState.thinking);

      // Extract page context
      _addLog('📖 Reading page...', AgentState.thinking);
      await Future.delayed(const Duration(milliseconds: 300));

      final pageContext = await AiAgentService.extractPageContext(controller);
      if (_shouldStop) break;

      // Decide next action using smart matching (no API key!)
      final action = AiAgentService.decideAction(_currentGoal, pageContext, _actionHistory);
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

      // Execute the action
      _setState(AgentState.acting);
      _addLog('⚡ ${action.type.toUpperCase()}: ${action.reasoning}', AgentState.acting);

      final result = await AiAgentService.executeAction(controller, action);
      _addLog('   → $result', AgentState.acting);

      // Wait for page to settle
      await Future.delayed(const Duration(seconds: 1));

      // For most commands, one action is enough
      if (action.type != 'search' || _stepCount >= 3) {
        _addLog('✅ Done.', AgentState.idle);
        _setState(AgentState.idle);
        return;
      }
    }

    if (_shouldStop) {
      _addLog('🛑 Stopped.', AgentState.stopped);
      _setState(AgentState.stopped);
    }
  }

  void emergencyStop() {
    _shouldStop = true;
    _addLog('🚨 EMERGENCY STOP', AgentState.stopped);
    _setState(AgentState.stopped);
  }

  void reset() {
    _shouldStop = true;
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

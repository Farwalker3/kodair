import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_agent_provider.dart';
import '../providers/browser_provider.dart';
import '../theme/kodair_theme.dart';

/// The AI Agent panel — shows prompt input, real-time action log, and control buttons.
class AiAgentPanel extends StatefulWidget {
  const AiAgentPanel({super.key});

  @override
  State<AiAgentPanel> createState() => _AiAgentPanelState();
}

class _AiAgentPanelState extends State<AiAgentPanel> {
  final _promptCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _promptCtrl.dispose();
    _apiKeyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final agent = context.watch<AiAgentProvider>();
    final isRunning = agent.state == AgentState.thinking || agent.state == AgentState.acting;
    final isPaused = agent.state == AgentState.paused;

    // Auto-scroll when log updates
    if (agent.log.isNotEmpty) _scrollToBottom();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF0101020),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 16, offset: const Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1A3E), Color(0xFF0D0D1A)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _stateColor(agent.state),
                    boxShadow: [BoxShadow(color: _stateColor(agent.state).withAlpha(150), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 8),
                const Text('AI Agent', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (agent.stepCount > 0)
                  Text('Step ${agent.stepCount}/20', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                  onPressed: () => context.read<BrowserProvider>().togglePanel(PanelType.info), // Close panel
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // API Key setup (if no key)
          if (!agent.hasApiKey) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔑 Setup Required', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Get your free Gemini API key from Google AI Studio (no credit card needed).',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Paste your Gemini API key',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_apiKeyCtrl.text.trim().isNotEmpty) {
                          agent.setApiKey(_apiKeyCtrl.text.trim());
                        }
                      },
                      icon: const Icon(Icons.key, size: 16),
                      label: const Text('Save Key'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KodairTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Log
          Expanded(
            child: agent.log.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.smart_toy_outlined, size: 48, color: Colors.white.withAlpha(30)),
                        const SizedBox(height: 8),
                        Text(
                          'Tell me what to do on this page.',
                          style: TextStyle(color: Colors.white.withAlpha(60), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(8),
                    itemCount: agent.log.length,
                    itemBuilder: (context, index) {
                      final entry = agent.log[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              margin: const EdgeInsets.only(right: 8, top: 2),
                              decoration: BoxDecoration(
                                color: _stateColor(entry.state),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.message,
                                style: TextStyle(
                                  color: entry.message.startsWith('   ')
                                      ? Colors.white54
                                      : Colors.white.withAlpha(200),
                                  fontSize: 12,
                                  fontFamily: 'Consolas',
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Control Buttons (when running)
          if (isRunning || isPaused)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF0D0D1A),
              child: Row(
                children: [
                  // Emergency Stop — always prominent
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => agent.emergencyStop(),
                      icon: const Icon(Icons.stop_circle, size: 20),
                      label: const Text('STOP', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1744),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Pause / Resume
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => isPaused ? agent.resume() : agent.pause(),
                      icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 18),
                      label: Text(isPaused ? 'GO' : 'PAUSE', style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPaused ? KodairTheme.primaryGreen : const Color(0xFFFFAB00),
                        foregroundColor: Colors.black87,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Prompt Input (when idle/stopped/error)
          if (!isRunning && !isPaused)
            Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFF0D0D1A),
              child: Row(
                children: [
                  if (agent.log.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white38, size: 20),
                      onPressed: () => agent.reset(),
                      tooltip: 'Clear',
                    ),
                  Expanded(
                    child: TextField(
                      controller: _promptCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _startAgent(context, agent),
                      decoration: InputDecoration(
                        hintText: agent.hasApiKey ? 'What should I do?' : 'Add API key first...',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF1A1A2E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      enabled: agent.hasApiKey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: agent.hasApiKey ? () => _startAgent(context, agent) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KodairTheme.primaryGreen,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(44, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _startAgent(BuildContext context, AiAgentProvider agent) {
    final browser = context.read<BrowserProvider>();
    final controller = browser.activeTab.webViewController;
    agent.start(_promptCtrl.text, controller);
    _promptCtrl.clear();
  }

  Color _stateColor(AgentState state) {
    switch (state) {
      case AgentState.idle:
        return Colors.white38;
      case AgentState.thinking:
        return const Color(0xFF00E5FF);
      case AgentState.acting:
        return KodairTheme.primaryGreen;
      case AgentState.paused:
        return const Color(0xFFFFAB00);
      case AgentState.stopped:
        return const Color(0xFFFF1744);
      case AgentState.error:
        return const Color(0xFFFF1744);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_agent_provider.dart';
import '../providers/browser_provider.dart';
import '../theme/kodair_theme.dart';

/// The AI Agent panel — NO API key needed. Just type a command.
class AiAgentPanel extends StatefulWidget {
  const AiAgentPanel({super.key});

  @override
  State<AiAgentPanel> createState() => _AiAgentPanelState();
}

class _AiAgentPanelState extends State<AiAgentPanel> {
  final _promptCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _promptCtrl.dispose();
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
              gradient: LinearGradient(colors: [Color(0xFF1A1A3E), Color(0xFF0D0D1A)]),
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
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: KodairTheme.primaryGreen.withAlpha(40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('FREE', style: TextStyle(color: Color(0xFF66FF88), fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                  onPressed: () => context.read<BrowserProvider>().togglePanel(PanelType.aiAgent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Help / examples when empty
          if (agent.log.isEmpty)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.smart_toy_outlined, size: 40, color: Colors.white.withAlpha(40)),
                    const SizedBox(height: 12),
                    Text('Tell me what to do.', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Text('Examples:', style: TextStyle(color: Colors.white.withAlpha(50), fontSize: 12)),
                    const SizedBox(height: 8),
                    _exampleChip('"Go to youtube.com"'),
                    _exampleChip('"Search for flutter tutorials"'),
                    _exampleChip('"Click the login button"'),
                    _exampleChip('"Type hello in the search box"'),
                    _exampleChip('"Scroll down"'),
                    _exampleChip('"Go back"'),
                  ],
                ),
              ),
            ),

          // Action Log
          if (agent.log.isNotEmpty)
            Expanded(
              child: ListView.builder(
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
                          width: 4, height: 16,
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
                              color: entry.message.startsWith('   ') ? Colors.white54 : Colors.white.withAlpha(200),
                              fontSize: 12,
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

          // Emergency Stop (when running)
          if (isRunning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF0D0D1A),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => agent.emergencyStop(),
                  icon: const Icon(Icons.stop_circle, size: 20),
                  label: const Text('EMERGENCY STOP', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1744),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),

          // Prompt Input (when idle/stopped/error)
          if (!isRunning)
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
                        hintText: 'e.g. "Click login" or "Go to google.com"',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF1A1A2E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _startAgent(context, agent),
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

  Widget _exampleChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () {
          _promptCtrl.text = text.replaceAll('"', '');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withAlpha(20)),
          ),
          child: Text(text, style: TextStyle(color: Colors.white.withAlpha(60), fontSize: 12)),
        ),
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
      case AgentState.idle: return Colors.white38;
      case AgentState.thinking: return const Color(0xFF00E5FF);
      case AgentState.acting: return KodairTheme.primaryGreen;
      case AgentState.paused: return const Color(0xFFFFAB00);
      case AgentState.stopped: return const Color(0xFFFF1744);
      case AgentState.error: return const Color(0xFFFF1744);
    }
  }
}

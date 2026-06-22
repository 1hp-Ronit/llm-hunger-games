import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/websocket_service.dart';
import '../widgets/agent_circle.dart';
import '../widgets/battle_log.dart';
import '../widgets/eliminated_panel.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final WebSocketService _wsService = WebSocketService();

  List<String> activeAgents = [
    "Analyst",
    "Poet",
    "Engineer",
    "Philosopher",
    "Pragmatist",
    "Contrarian",
    "Optimist",
    "Minimalist",
  ];
  List<String> eliminatedAgents = [];
  List<Map<String, dynamic>> battleLogEvents = [];
  String currentQuestion = "Press Start Game to begin";
  int? currentGameId;
  bool gameRunning = false;

  final Map<String, String> agentEmojis = {
    "Analyst": "🤖",
    "Poet": "🧚",
    "Engineer": "👷",
    "Philosopher": "🧙",
    "Pragmatist": "👩‍💼",
    "Contrarian": "😈",
    "Optimist": "😊",
    "Minimalist": "👻",
  };

  Future<void> startGame() async {
    final response = await http.post(
      Uri.parse('http://localhost:8000/game/start'),
    );
    final data = jsonDecode(response.body);
    currentGameId = data['game_id'];

    setState(() {
      gameRunning = true;
      activeAgents = agentEmojis.keys.toList();
      eliminatedAgents = [];
      battleLogEvents = [];
      currentQuestion = "Game starting...";
    });

    _wsService
        .connect(currentGameId!)
        .listen(
          (event) {
            if (event['event'] == 'game_over') {
              setState(() {
                gameRunning = false;
                currentQuestion = "Winner: ${event['winner'] ?? 'No winner'}";
              });
              return;
            }
            if (event['event'] == 'round_start') {
              setState(() {
                currentQuestion = event['question'];
              });
              return;
            }

            setState(() {
              currentQuestion = event['question'];
              if (event['eliminated'] != null) {
                activeAgents.remove(event['eliminated']);
                eliminatedAgents.add(event['eliminated']);
              }
              battleLogEvents.insert(0, event);
            });
          },
          onError: (error) {
            print('Stream error: $error');
          },
          onDone: () {
            print('WebSocket closed');
          },
        );
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1A0E),
      body: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "AI HUNGER GAMES",
                  style: GoogleFonts.jersey10(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "Analytics",
                    style: GoogleFonts.jersey10(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Left — Arena
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        Expanded(
                          child: AgentCircle(
                            activeAgents: activeAgents,
                            agentEmojis: agentEmojis,
                            currentQuestion: currentQuestion,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: gameRunning ? null : startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5C2D0E),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            gameRunning ? "GAME RUNNING..." : "START GAME",
                            style: GoogleFonts.jersey10(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right panel
                  SizedBox(
                    width: 220,
                    child: Column(
                      children: [
                        Expanded(child: BattleLog(events: battleLogEvents)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: EliminatedPanel(
                            eliminatedAgents: eliminatedAgents,
                            agentEmojis: agentEmojis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

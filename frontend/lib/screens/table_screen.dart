import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const _bg = Color(0xFF0D1117);
const _card = Color(0xFF161B22);
const _border = Color(0xFF30363D);
const _textPrimary = Color(0xFFE6EDF3);
const _textSecondary = Color(0xFF8B949E);
const _green = Color(0xFF238636);
const _orange = Color(0xFFF78166);
const _selected = Color(0xFF1F6FEB);

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  List<Map<String, dynamic>> games = [];
  List<Map<String, dynamic>> rounds = [];
  Map<String, dynamic>? selectedRound;
  int? selectedGameId;
  int? selectedRoundIndex;
  bool loadingGames = true;
  bool loadingRounds = false;

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  Future<void> fetchGames() async {
    final res = await http.get(Uri.parse('http://localhost:8000/games'));
    setState(() {
      games = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      loadingGames = false;
    });
  }

  Future<void> fetchRounds(int gameId) async {
    setState(() {
      loadingRounds = true;
      selectedGameId = gameId;
      selectedRound = null;
      selectedRoundIndex = null;
    });
    final res =
        await http.get(Uri.parse('http://localhost:8000/game/$gameId/results'));
    setState(() {
      rounds = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      loadingRounds = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Top bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: _bg,
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("AI HUNGER GAMES",
                    style: GoogleFonts.jersey10(
                        color: _textPrimary, fontSize: 22)),
                Row(
                  children: [
                    Text("Data Explorer",
                        style: GoogleFonts.jersey10(
                            color: _textSecondary, fontSize: 16)),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text("← Back",
                            style: GoogleFonts.jersey10(
                                color: _textPrimary, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Three column layout
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1 — Games
                Container(
                  width: 180,
                  decoration: const BoxDecoration(
                    border:
                        Border(right: BorderSide(color: _border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text("Games",
                            style: GoogleFonts.jersey10(
                                color: _textSecondary, fontSize: 12)),
                      ),
                      Expanded(
                        child: loadingGames
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: _green))
                            : ListView.builder(
                                itemCount: games.length,
                                itemBuilder: (context, i) {
                                  final g = games[i];
                                  final isSelected =
                                      selectedGameId == g['id'];
                                  return GestureDetector(
                                    onTap: () => fetchRounds(g['id']),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? _selected.withOpacity(0.2)
                                            : Colors.transparent,
                                        border: isSelected
                                            ? const Border(
                                                left: BorderSide(
                                                    color: _selected,
                                                    width: 2))
                                            : null,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("Game ${g['id']}",
                                              style: GoogleFonts.jersey10(
                                                  color: isSelected
                                                      ? _textPrimary
                                                      : _textSecondary,
                                                  fontSize: 13)),
                                          Text(
                                            g['winner'] != null
                                                ? "🏆 ${g['winner']}"
                                                : g['status'],
                                            style: GoogleFonts.jersey10(
                                                color: g['winner'] != null
                                                    ? _green
                                                    : _textSecondary,
                                                fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                // Column 2 — Rounds
                Container(
                  width: 160,
                  decoration: const BoxDecoration(
                    border:
                        Border(right: BorderSide(color: _border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text("Rounds",
                            style: GoogleFonts.jersey10(
                                color: _textSecondary, fontSize: 12)),
                      ),
                      Expanded(
                        child: loadingRounds
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: _green))
                            : rounds.isEmpty
                                ? Center(
                                    child: Text("Select a game",
                                        style: GoogleFonts.jersey10(
                                            color: _textSecondary,
                                            fontSize: 12)))
                                : ListView.builder(
                                    itemCount: rounds.length,
                                    itemBuilder: (context, i) {
                                      final r = rounds[i];
                                      final isSelected =
                                          selectedRoundIndex == i;
                                      final roundData =
                                          r['round'] as Map<String, dynamic>;
                                      final votes =
                                          r['votes'] as List? ?? [];
                                      // find eliminated from votes
                                      final eliminated = _findEliminated(votes);
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedRound = r;
                                            selectedRoundIndex = i;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? _selected.withOpacity(0.2)
                                                : Colors.transparent,
                                            border: isSelected
                                                ? const Border(
                                                    left: BorderSide(
                                                        color: _selected,
                                                        width: 2))
                                                : null,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  "Round ${roundData['round_number']}",
                                                  style: GoogleFonts.jersey10(
                                                      color: isSelected
                                                          ? _textPrimary
                                                          : _textSecondary,
                                                      fontSize: 13)),
                                              if (eliminated != null)
                                                Text("💀 $eliminated",
                                                    style:
                                                        GoogleFonts.jersey10(
                                                            color: _orange,
                                                            fontSize: 10)),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
                // Column 3 — Round detail
                Expanded(
                  child: selectedRound == null
                      ? Center(
                          child: Text("Select a round to view data",
                              style: GoogleFonts.jersey10(
                                  color: _textSecondary, fontSize: 14)))
                      : _RoundDetail(roundData: selectedRound!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _findEliminated(List votes) {
    final regularVotes =
        votes.where((v) => v['is_jury'] == 0).toList();
    if (regularVotes.isEmpty) return null;
    final counts = <String, int>{};
    for (final v in regularVotes) {
      final target = v['voted_for'];
      if (target != null) counts[target] = (counts[target] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

class _RoundDetail extends StatelessWidget {
  final Map<String, dynamic> roundData;

  const _RoundDetail({required this.roundData});

  @override
  Widget build(BuildContext context) {
    final round = roundData['round'] as Map<String, dynamic>;
    final answers = roundData['answers'] as List? ?? [];
    final votes = roundData['votes'] as List? ?? [];
    final conversations = roundData['conversations'] as List? ?? [];
    final regularVotes = votes.where((v) => v['is_jury'] == 0).toList();
    final juryVotes = votes.where((v) => v['is_jury'] == 1).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round header
          Text("Round ${round['round_number']}",
              style: GoogleFonts.jersey10(
                  color: _textPrimary, fontSize: 24)),
          const SizedBox(height: 4),
          Text(round['question'] ?? "",
              style: GoogleFonts.jersey10(
                  color: _textSecondary, fontSize: 14)),
          const SizedBox(height: 20),

          // Answers
          _SectionHeader(title: "Answers", count: answers.length),
          const SizedBox(height: 8),
          ...answers.map((a) => _AnswerCard(answer: a)),
          const SizedBox(height: 20),

          // Conversations
          if (conversations.isNotEmpty) ...[
            _SectionHeader(
                title: "Private Conversations",
                count: conversations.length),
            const SizedBox(height: 8),
            ...conversations.map((c) => _ConversationCard(convo: c)),
            const SizedBox(height: 20),
          ],

          // Votes
          _SectionHeader(title: "Votes", count: regularVotes.length),
          const SizedBox(height: 8),
          ...regularVotes.map((v) => _VoteCard(vote: v, isJury: false)),
          const SizedBox(height: 20),

          // Jury votes
          if (juryVotes.isNotEmpty) ...[
            _SectionHeader(
                title: "Jury Votes", count: juryVotes.length),
            const SizedBox(height: 8),
            ...juryVotes.map((v) => _VoteCard(vote: v, isJury: true)),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: GoogleFonts.jersey10(
                color: _textPrimary, fontSize: 16)),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _border,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text("$count",
              style: GoogleFonts.jersey10(
                  color: _textSecondary, fontSize: 11)),
        ),
      ],
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final Map<String, dynamic> answer;

  const _AnswerCard({required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(answer['agent'] ?? "",
              style: GoogleFonts.jersey10(
                  color: _green, fontSize: 13)),
          const SizedBox(height: 4),
          Text(answer['answer'] ?? "",
              style: GoogleFonts.jersey10(
                  color: _textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final Map<String, dynamic> convo;

  const _ConversationCard({required this.convo});

  @override
  Widget build(BuildContext context) {
    List transcript = [];
    try {
      transcript = jsonDecode(convo['transcript'] ?? '[]');
    } catch (_) {}

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              "${convo['agent_a']} ↔ ${convo['agent_b']}",
              style: GoogleFonts.jersey10(
                  color: _selected, fontSize: 13)),
          const SizedBox(height: 8),
          ...transcript.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(msg['agent'] ?? "",
                        style: GoogleFonts.jersey10(
                            color: _textPrimary, fontSize: 11)),
                    Text(msg['message'] ?? "",
                        style: GoogleFonts.jersey10(
                            color: _textSecondary, fontSize: 11)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _VoteCard extends StatelessWidget {
  final Map<String, dynamic> vote;
  final bool isJury;

  const _VoteCard({required this.vote, required this.isJury});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(
            color: isJury ? _orange.withOpacity(0.4) : _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${vote['voter']}",
              style: GoogleFonts.jersey10(
                  color: isJury ? _orange : _textPrimary,
                  fontSize: 12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text("→",
                style: GoogleFonts.jersey10(
                    color: _textSecondary, fontSize: 12)),
          ),
          Text("${vote['voted_for']}",
              style: GoogleFonts.jersey10(
                  color: _orange, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(vote['reason'] ?? "",
                style: GoogleFonts.jersey10(
                    color: _textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BattleLog extends StatefulWidget {
  final List<Map<String, dynamic>> events;

  const BattleLog({super.key, required this.events});

  @override
  State<BattleLog> createState() => _BattleLogState();
}

class _BattleLogState extends State<BattleLog> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "≡ Battle Log",
            style: GoogleFonts.jersey10(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.events.isEmpty
                ? Center(
                    child: Text(
                      "No events yet",
                      style: GoogleFonts.jersey10(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.events.length,
                    itemBuilder: (context, i) {
                      final e = widget.events[i];
                      final isExpanded = expandedIndex == i;
                      return _RoundEntry(
                        event: e,
                        isExpanded: isExpanded,
                        onTap: () {
                          setState(() {
                            expandedIndex = isExpanded ? null : i;
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RoundEntry extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isExpanded;
  final VoidCallback onTap;

  const _RoundEntry({
    required this.event,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final round = event['round'];
    final eliminated = event['eliminated'];
    final question = event['question'];
    final answers = event['answers'] as List? ?? [];
    final votes = event['votes'] as List? ?? [];
    final conversations = event['conversations'] as List? ?? [];
    final wasTie = event['was_tie'] ?? false;
    final juryVotes = event['jury_votes'] as List? ?? [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Round header — always visible
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Round $round",
                    style: GoogleFonts.jersey10(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    children: [
                      if (eliminated != null)
                        Text(
                          "💀 $eliminated",
                          style: GoogleFonts.jersey10(
                            color: const Color(0xFFFF6B6B),
                            fontSize: 11,
                          ),
                        ),

                      if (wasTie)
                        Text(
                          "  ⚖️ TIE",
                          style: GoogleFonts.jersey10(
                            color: Colors.orange,
                            fontSize: 11,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Expanded details
            if (isExpanded) ...[
              _Divider(),
              // Question
              _Section(
                title: "Question",
                child: Text(
                  question ?? "",
                  style: GoogleFonts.jersey10(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ),
              _Divider(),
              // Answers
              _Section(
                title: "Answers",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: answers.map((a) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['agent'] ?? "",
                            style: GoogleFonts.jersey10(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            a['answer'] ?? "",
                            style: GoogleFonts.jersey10(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Conversations
              if (conversations.isNotEmpty) ...[
                _Divider(),
                _Section(
                  title: "Private Talks",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: conversations.map((c) {
                      return Text(
                        "${c['agent_a']} ↔ ${c['agent_b']}",
                        style: GoogleFonts.jersey10(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              _Divider(),
              // Votes
              _Section(
                title: "Votes",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: votes.map((v) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "${v['voter']} → ${v['voted_for']}: ${v['reason'] ?? ''}",
                        style: GoogleFonts.jersey10(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (juryVotes.isNotEmpty) ...[
                _Divider(),
                _Section(
                  title: "Jury Votes",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: juryVotes.map((v) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          "${v['voter']} → ${v['voted_for']}: ${v['reason'] ?? ''}",
                          style: GoogleFonts.jersey10(
                            color: Colors.orange.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.jersey10(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Colors.white10);
  }
}

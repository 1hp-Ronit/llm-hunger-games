import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BattleLog extends StatelessWidget {
  final List<Map<String, dynamic>> events;

  const BattleLog({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3D1F0D),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "≡ Battle Log",
            style: GoogleFonts.jersey10(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: events.isEmpty
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
                    itemCount: events.length,
                    itemBuilder: (context, i) {
                      final e = events[i];
                      final eliminated = e['eliminated'];
                      final round = e['round'];
                      final convos = (e['conversations'] as List?)?.length ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5C2D0E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Round $round",
                              style: GoogleFonts.jersey10(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            if (convos > 0)
                              Text(
                                "$convos pair(s) talked privately",
                                style: GoogleFonts.jersey10(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            if (eliminated != null)
                              Text(
                                "💀 $eliminated eliminated",
                                style: GoogleFonts.jersey10(
                                  color: const Color(0xFFFF6B6B),
                                  fontSize: 12,
                                ),
                              )
                            else
                              Text(
                                "No elimination",
                                style: GoogleFonts.jersey10(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
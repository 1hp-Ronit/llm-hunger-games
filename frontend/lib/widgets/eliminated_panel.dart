import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EliminatedPanel extends StatelessWidget {
  final List<String> eliminatedAgents;
  final Map<String, String> agentEmojis;

  const EliminatedPanel({
    super.key,
    required this.eliminatedAgents,
    required this.agentEmojis,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "💀 Eliminated",
            style: GoogleFonts.jersey10(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          eliminatedAgents.isEmpty
              ? Center(
                child: Text(
                    "None yet",
                    style: GoogleFonts.jersey10(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
              )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: eliminatedAgents.map((agent) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C2D0E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        "${agentEmojis[agent]} $agent",
                        style: GoogleFonts.jersey10(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class AgentCircle extends StatelessWidget {
  final List<String> activeAgents;
  final Map<String, String> agentEmojis;
  final String currentQuestion;

  const AgentCircle({
    super.key,
    required this.activeAgents,
    required this.agentEmojis,
    required this.currentQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final center = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );
        final radius = min(constraints.maxWidth, constraints.maxHeight) * 0.38;

        return Stack(
          children: [
            // Circle outline
            Positioned.fill(
              child: CustomPaint(painter: _CirclePainter(center, radius)),
            ),
            // Question in center
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 200,
                  child: Text(
                    currentQuestion,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jersey10(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            // Agents around circle
            ...List.generate(activeAgents.length, (i) {
              final angle = (2 * pi / activeAgents.length) * i - pi / 2;
              final x = center.dx + radius * cos(angle) - 30;
              final y = center.dy + radius * sin(angle) - 30;

              return Positioned(
                left: x,
                top: y,
                child: _AgentAvatar(
                  name: activeAgents[i],
                  emoji: agentEmojis[activeAgents[i]] ?? "❓",
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _AgentAvatar extends StatelessWidget {
  final String name;
  final String emoji;

  const _AgentAvatar({required this.name, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: GoogleFonts.jersey10(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _CirclePainter extends CustomPainter {
  final Offset center;
  final double radius;

  _CirclePainter(this.center, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

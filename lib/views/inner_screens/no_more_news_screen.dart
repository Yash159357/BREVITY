import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoMoreNewsScreen extends StatelessWidget {
  
  const NoMoreNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Color(0xFF041036),
                    Color(0xFF1E2462),
                    Color(0xFF24035F),
                  ]
                : [
                    Colors.blue.shade100,
                    Colors.blue.shade200,
                    Colors.blue.shade300,
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                "You're done for the day",
                textAlign: TextAlign.center,
                style: GoogleFonts.frankRuhlLibre(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}

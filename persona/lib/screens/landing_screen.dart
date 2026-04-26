import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'main_navigation.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.school_rounded, size: 64, color: Color(0xFF8B5CF6))
                  .animate().scale(duration: 600.ms, delay: 200.ms),
                const SizedBox(height: 32),
                const Text(
                  'Master your\nExams faster.',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, height: 1.1),
                ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),
                const Text(
                  'Upload notes, generate AI flashcards, and let the smart spaced repetition algorithm handle your study schedule.',
                  style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                ).animate().fade(delay: 600.ms).slideY(begin: 0.1),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainNavigation())
                      );
                    },
                    child: const Text('Get Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ).animate().fade(delay: 800.ms).slideY(begin: 0.1),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

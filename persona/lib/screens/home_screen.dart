import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'stats_screen.dart';
import 'subjects_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('StudyRAG', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('🔥 Study Streak', style: TextStyle(fontSize: 16, color: Colors.white70)),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('5 Days', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ).animate().fade(duration: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),
            const Text('Next Exams', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                .animate().fade(delay: 200.ms),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: const ListTile(
                contentPadding: EdgeInsets.all(16),
                title: Text('Software Engineering', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('In 7 days • 3 topics to review'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
              ),
            ).animate().fade(delay: 300.ms).slideX(begin: 0.05),

            const SizedBox(height: 24),
            const Text('Weak Topics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                .animate().fade(delay: 400.ms),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildBentoCard(context, 'Design Patterns', Icons.warning_amber_rounded, Colors.orange)
                      .animate().fade(delay: 500.ms).scale(begin: const Offset(0.95, 0.95)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBentoCard(context, 'SQL Joins', Icons.query_stats, Colors.blue)
                      .animate().fade(delay: 600.ms).scale(begin: const Offset(0.95, 0.95)),
                ),
              ],
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SubjectsScreen()));
                    },
                    child: const Text('Quick Quiz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ).animate().fade(delay: 700.ms).slideY(begin: 0.1),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SubjectsScreen()));
                    },
                    child: Text('Review Cards', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor)),
                  ),
                ).animate().fade(delay: 800.ms).slideY(begin: 0.1),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard(BuildContext context, String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Needs review', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

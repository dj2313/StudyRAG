import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodels/quiz_viewmodel.dart';
import '../models/models.dart';

class QuizScreen extends ConsumerWidget {
  final int subjectId;
  const QuizScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(quizQuestionsProvider(subjectId));
    final currentIndex = ref.watch(currentQuestionIndexProvider);
    final score = ref.watch(quizScoreProvider);
    final finished = ref.watch(quizFinishedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(child: Text('Score: $score', style: const TextStyle(fontWeight: FontWeight.bold))),
          )
        ],
      ),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) return const Center(child: Text('No questions generated.'));
          if (finished) return _buildResult(context, ref, score, questions.length);

          final q = questions[currentIndex];
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: (currentIndex + 1) / questions.length,
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 8,
                ),
                const SizedBox(height: 32),
                Text(
                  'Question ${currentIndex + 1}/${questions.length}',
                  style: const TextStyle(color: Colors.white54, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Text(
                  q.question,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
                ).animate().fade().slideX(),
                const SizedBox(height: 40),
                ...List.generate(q.options.length, (index) {
                  return _buildOption(context, ref, q, index, questions.length);
                }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildOption(BuildContext context, WidgetRef ref, QuizQuestion q, int index, int total) {
    return GestureDetector(
      onTap: () {
        if (index == q.correctIndex) {
          ref.read(quizScoreProvider.notifier).state++;
        }
        
        final current = ref.read(currentQuestionIndexProvider);
        if (current + 1 < total) {
          ref.read(currentQuestionIndexProvider.notifier).state++;
        } else {
          ref.read(quizFinishedProvider.notifier).state = true;
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white.withOpacity(0.1),
              child: Text(
                String.fromCharCode(65 + index),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                q.options[index],
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ).animate().fade(delay: (index * 100).ms).slideY(begin: 0.1),
    );
  }

  Widget _buildResult(BuildContext context, WidgetRef ref, int score, int total) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
          const SizedBox(height: 24),
          const Text('Quiz Completed!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('You scored $score out of $total', style: const TextStyle(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              ref.read(quizScoreProvider.notifier).state = 0;
              ref.read(currentQuestionIndexProvider.notifier).state = 0;
              ref.read(quizFinishedProvider.notifier).state = false;
            },
            child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Subject', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ).animate().fade().scale(),
    );
  }
}

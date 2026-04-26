import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodels/subject_viewmodel.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Exam Planner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: subjectsAsync.when(
        data: (subs) {
          final exams = subs.where((s) => s.examDate != null).toList();
          if (exams.isEmpty) {
            return const Center(
              child: Text(
                'No exams scheduled.',
                style: TextStyle(color: Colors.white54),
              ),
            ).animate().fade();
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 100,
            ),
            itemCount: exams.length,
            itemBuilder: (ctx, i) {
              final s = exams[i];
              final days = s.daysRemaining ?? 0;
              Color urgencyColor = Colors.green;
              if (days < 7) {
                urgencyColor = Colors.red;
              } else if (days < 30) {
                urgencyColor = Colors.orange;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$days',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: urgencyColor,
                            ),
                          ),
                          Text(
                            'days',
                            style: TextStyle(
                              fontSize: 12,
                              color: urgencyColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.examDate ?? '',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                      onPressed: () {},
                    ),
                  ],
                ),
              ).animate().fade(delay: (i * 100).ms).slideX(begin: 0.05);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudyStats {
  final List<double> weeklyHours;
  final int totalCardsMastered;
  final double averageQuizScore;

  StudyStats({
    required this.weeklyHours,
    required this.totalCardsMastered,
    required this.averageQuizScore,
  });
}

final statsProvider = Provider<StudyStats>((ref) {
  return StudyStats(
    weeklyHours: [2.5, 3.8, 1.2, 4.5, 2.8, 5.0, 3.2],
    totalCardsMastered: 124,
    averageQuizScore: 88.5,
  );
});

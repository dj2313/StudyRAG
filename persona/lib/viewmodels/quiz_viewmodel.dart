import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/models.dart';

final quizQuestionsProvider = FutureProvider.family<List<QuizQuestion>, int>((ref, subjectId) async {
  final res = await apiService.get('/quiz/generate/$subjectId');
  return (res.data as List).map((e) => QuizQuestion(
    id: e['id'],
    question: e['question'],
    options: List<String>.from(e['options']),
    correctIndex: e['correct_index'],
  )).toList();
});

final quizScoreProvider = StateProvider<int>((ref) => 0);
final currentQuestionIndexProvider = StateProvider<int>((ref) => 0);
final quizFinishedProvider = StateProvider<bool>((ref) => false);

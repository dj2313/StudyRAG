import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/models.dart';

final fcSelectedSubjectProvider = StateProvider<int?>((ref) => null);

final dueCardsProvider = FutureProvider.family<List<Flashcard>, int>((ref, subjectId) async {
  final res = await apiService.get('/flashcards/$subjectId');
  return (res.data as List).map((e) => Flashcard(id: e['id'], question: e['question'], answer: e['answer'])).toList();
});

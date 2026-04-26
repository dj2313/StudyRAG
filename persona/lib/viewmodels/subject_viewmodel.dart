import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/models.dart';

final subjectsProvider = FutureProvider<List<PlannerItem>>((ref) async {
  final res = await apiService.get('/planner');
  List<dynamic> data = res.data;
  return data.map((e) => PlannerItem(
    subjectId: e['subject_id'], 
    name: e['name'],
    examDate: e['exam_date'],
    daysRemaining: e['days_remaining'],
  )).toList();
});

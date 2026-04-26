import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../viewmodels/subject_viewmodel.dart';
import 'quiz_screen.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subjects', style: TextStyle(fontWeight: FontWeight.bold))),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(child: Text('No subjects yet. Add one!'))
                .animate().fade();
          }
          return ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final sub = subjects[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(
                    sub.examDate != null ? 'Exam: ${sub.examDate}' : 'No exam date',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).primaryColor),
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectDetailScreen(subject: sub)));
                  },
                ),
              ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.05);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _showAddSubjectDialog(context, ref),
        ).animate().scale(delay: 500.ms),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Subject'),
        content: TextField(
          controller: ctrl, 
          decoration: InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              ref.invalidate(subjectsProvider);
              Navigator.pop(ctx);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white))
          )
        ],
      )
    );
  }
}

class SubjectDetailScreen extends StatelessWidget {
  final PlannerItem subject;
  const SubjectDetailScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(subject.name),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFF8B5CF6),
            tabs: [
              Tab(text: 'Notes'),
              Tab(text: 'Topics'),
              Tab(text: 'Flashcards'),
              Tab(text: 'Quiz'),
              Tab(text: 'Past Papers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const Center(child: Text('Notes List')),
            const Center(child: Text('Topics List')),
            const Center(child: Text('Flashcards List')),
            QuizScreen(subjectId: subject.subjectId),
            const Center(child: Text('Past Papers')),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.upload_file, color: Colors.white),
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles();
            if (result != null && context.mounted) {
              final path = result.files.single.path;
              if (path != null) {
                FormData formData = FormData.fromMap({
                  "subject_id": subject.subjectId,
                  "file": await MultipartFile.fromFile(path, filename: result.files.single.name),
                });
                await apiService.post('/ingest/file', data: formData);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File uploaded successfully!')));
                }
              }
            }
          },
        ),
      ),
    );
  }
}

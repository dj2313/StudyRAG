import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../viewmodels/subject_viewmodel.dart';

class ChatScreen extends ConsumerWidget {
  ChatScreen({super.key});
  final TextEditingController _msgCtrl = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider);
    final examMode = ref.watch(examModeProvider);
    final selectedSubject = ref.watch(selectedSubjectProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Row(
            children: [
              const Text('Exam Mode', style: TextStyle(fontSize: 12, color: Colors.white70)),
              Switch(
                value: examMode,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (v) => ref.read(examModeProvider.notifier).state = v,
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: const Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: subjectsAsync.when(
              data: (subs) => DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                  hint: const Text('Select Subject to Filter'),
                  value: selectedSubject,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Subjects')),
                    ...subs.map((s) => DropdownMenuItem(value: s.subjectId, child: Text(s.name))),
                  ],
                  onChanged: (v) => ref.read(selectedSubjectProvider.notifier).state = v,
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading subjects'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final m = messages[index];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: m.isUser ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(m.isUser ? 20 : 4),
                        bottomRight: Radius.circular(m.isUser ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 15)),
                  ).animate().slideY(begin: 0.2, duration: 300.ms).fade(),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.mic, color: Colors.white70),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice input started...')));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  )
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () async {
                      if (_msgCtrl.text.isEmpty) return;
                      final q = _msgCtrl.text;
                      _msgCtrl.clear();
                      
                      ref.read(messagesProvider.notifier).update((state) => [...state, ChatMessage(q, true)]);
                      
                      try {
                        final res = await apiService.post('/query', data: {
                          "question": q,
                          "subject_id": selectedSubject,
                          "exam_mode": examMode
                        });
                        final ans = res.data['answer'];
                        ref.read(messagesProvider.notifier).update((state) => [...state, ChatMessage(ans, false)]);
                      } catch (e) {
                        ref.read(messagesProvider.notifier).update((state) => [...state, ChatMessage('Error: $e', false)]);
                      }
                    },
                  ),
                )
              ],
            )
          )
        ],
      )
    );
  }
}

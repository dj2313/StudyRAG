import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../viewmodels/flashcard_viewmodel.dart';
import '../viewmodels/subject_viewmodel.dart';

class FlashcardScreen extends ConsumerWidget {
  const FlashcardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSubject = ref.watch(fcSelectedSubjectProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards', style: TextStyle(fontWeight: FontWeight.bold))),
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
                  hint: const Text('Select Subject'),
                  value: selectedSubject,
                  items: subs.map((s) => DropdownMenuItem(value: s.subjectId, child: Text(s.name))).toList(),
                  onChanged: (v) => ref.read(fcSelectedSubjectProvider.notifier).state = v,
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading subjects'),
            ),
          ),
          if (selectedSubject != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Due', '10', Colors.orange),
                  _buildStatCard('Total', '45', Colors.blue),
                  _buildStatCard('Mastered', '32', Colors.green),
                ],
              ).animate().fade().slideY(begin: -0.1),
            ),
          Expanded(
            child: selectedSubject == null 
              ? const Center(child: Text('Please select a subject', style: TextStyle(color: Colors.white54)))
              : _buildCardSwiper(context, ref, selectedSubject),
          ),
          if (selectedSubject != null)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 100),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating cards...')));
                  try {
                    await apiService.post('/flashcards/generate/$selectedSubject');
                    ref.invalidate(dueCardsProvider(selectedSubject));
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text('Generate AI Cards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))
              ).animate().scale(delay: 300.ms),
            )
        ],
      )
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }

  Widget _buildCardSwiper(BuildContext context, WidgetRef ref, int subjectId) {
    final cardsAsync = ref.watch(dueCardsProvider(subjectId));
    return cardsAsync.when(
      data: (cards) {
        if (cards.isEmpty) {
          return const Center(child: Text('You are all caught up! 🎉', style: TextStyle(fontSize: 18))).animate().scale();
        }
        return CardSwiper(
          cardsCount: cards.length,
          cardBuilder: (context, index, x, y) {
            return _FlashcardWidget(card: cards[index], onRate: (rating) async {
               await apiService.post('/flashcards/review', data: {"card_id": cards[index].id, "rating": rating});
            });
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _FlashcardWidget extends StatefulWidget {
  final Flashcard card;
  final Function(int rating) onRate;
  const _FlashcardWidget({required this.card, required this.onRate});
  @override
  __FlashcardWidgetState createState() => __FlashcardWidgetState();
}

class __FlashcardWidgetState extends State<_FlashcardWidget> {
  bool showAnswer = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => showAnswer = !showAnswer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: showAnswer 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Theme.of(context).primaryColor, const Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15))
          ],
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                showAnswer ? "Answer" : "Question", 
                style: TextStyle(color: showAnswer ? Colors.white54 : Colors.white70, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.w600)
              ),
              const SizedBox(height: 24),
              Text(
                showAnswer ? widget.card.answer : widget.card.question, 
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3, color: Colors.white), 
                textAlign: TextAlign.center
              ),
              if (showAnswer) ...[
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRateBtn('Again', Colors.red, 1),
                    _buildRateBtn('Hard', Colors.orange, 2),
                    _buildRateBtn('Good', Colors.green, 3),
                    _buildRateBtn('Easy', Colors.blue, 4),
                  ],
                ).animate().fade().slideY(begin: 0.2),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRateBtn(String label, Color color, int rating) {
    return InkWell(
      onTap: () {
        widget.onRate(rating);
        // Note: the swiper doesn't auto-swipe on this tap in this basic impl.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rated $label. Swipe to continue.', style: TextStyle(color: color))));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}

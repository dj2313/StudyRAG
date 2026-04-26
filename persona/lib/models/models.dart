class Subject {
  final int id;
  final String name;

  Subject({required this.id, required this.name});
  
  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'],
    name: json['name'],
  );
}

class Note {
  final int id;
  final String title;
  final String content;
  
  Note({required this.id, required this.title, required this.content});
}

class Flashcard {
  final int id;
  final String question;
  final String answer;
  
  Flashcard({required this.id, required this.question, required this.answer});
}

class QuizSession {
  final int id;
  final double? score;
  
  QuizSession({required this.id, this.score});
}

class PlannerItem {
  final int subjectId;
  final String name;
  final String? examDate;
  final int? daysRemaining;
  
  PlannerItem({required this.subjectId, required this.name, this.examDate, this.daysRemaining});
}

class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

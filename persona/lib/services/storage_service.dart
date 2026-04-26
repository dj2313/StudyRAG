import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('flashcards');
    await Hive.openBox('subjects');
    await Hive.openBox('stats');
  }

  static Box get flashcardBox => Hive.box('flashcards');
  static Box get subjectBox => Hive.box('subjects');
  static Box get statsBox => Hive.box('stats');
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, this.isUser);
}

final messagesProvider = StateProvider<List<ChatMessage>>((ref) => []);
final examModeProvider = StateProvider<bool>((ref) => false);
final selectedSubjectProvider = StateProvider<int?>((ref) => null);

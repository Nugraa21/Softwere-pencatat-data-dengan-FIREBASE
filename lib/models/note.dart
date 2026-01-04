import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  String id, title, content;
  DateTime createdAt;
  bool isPinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'isPinned': isPinned,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        createdAt: DateTime.parse(
            json['createdAt'] ?? DateTime.now().toIso8601String()),
        isPinned: json['isPinned'] ?? false,
      );
}

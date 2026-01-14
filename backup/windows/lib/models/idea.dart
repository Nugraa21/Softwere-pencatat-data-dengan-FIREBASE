import 'package:cloud_firestore/cloud_firestore.dart';

class Idea {
  String id, title, description, tag;
  DateTime createdAt;

  Idea({
    required this.id,
    required this.title,
    required this.description,
    this.tag = 'Ide',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'tag': tag,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Idea.fromJson(Map<String, dynamic> json) => Idea(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        tag: json['tag'] ?? 'Ide',
        createdAt: DateTime.parse(
            json['createdAt'] ?? DateTime.now().toIso8601String()),
      );
}

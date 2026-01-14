import 'package:cloud_firestore/cloud_firestore.dart';

class Bookmark {
  String id, title, url, category;
  DateTime createdAt;

  Bookmark({
    required this.id,
    required this.title,
    required this.url,
    required this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        url: json['url'] ?? '',
        category: json['category'] ?? 'Umum',
        createdAt: DateTime.parse(
            json['createdAt'] ?? DateTime.now().toIso8601String()),
      );
}

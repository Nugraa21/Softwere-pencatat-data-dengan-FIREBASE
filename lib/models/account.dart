class Account {
  String id, title, user, pass, phone, note;
  bool isVisible;

  Account({
    required this.id,
    required this.title,
    required this.user,
    required this.pass,
    required this.phone,
    required this.note,
    this.isVisible = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'user': user,
        'pass': pass,
        'phone': phone,
        'note': note,
        'isVisible': isVisible,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        user: json['user'] ?? '',
        pass: json['pass'] ?? '',
        phone: json['phone'] ?? '',
        note: json['note'] ?? '',
        isVisible: json['isVisible'] ?? false,
      );
}

class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  // Helper: aman untuk null, tipe salah, maupun angka dalam bentuk String.
  static int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Helper: aman untuk null maupun tipe selain String.
  static String _parseString(dynamic value) {
    if (value is String) return value;
    if (value == null) return '';
    return value.toString();
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: _parseInt(json['postId']),
      id: _parseInt(json['id']),
      name: _parseString(json['name']),
      email: _parseString(json['email']),
      body: _parseString(json['body']),
    );
  }

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };
}
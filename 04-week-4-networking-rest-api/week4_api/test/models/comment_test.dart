import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart'; // Sesuaikan nama_project

void main() {
  group('Comment Model Tests', () {
    test('fromJson menangani field yang hilang dan null dengan memberikan nilai default', () {
      final Map<String, dynamic> incompleteJson = {
        'postId': 1,
        'name': null, 
        // 'id', 'email', dan 'body' hilang
      };

      final comment = Comment.fromJson(incompleteJson);

      expect(comment.postId, 1);
      expect(comment.id, 0); 
      expect(comment.name, ''); 
      expect(comment.email, ''); 
      expect(comment.body, ''); 
    });
  });
}
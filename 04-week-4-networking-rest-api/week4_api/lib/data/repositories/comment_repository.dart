import 'package:dio/dio.dart';
import '../models/comment.dart';

class CommentRepository {
  final Dio _dio;

  CommentRepository(this._dio);

  Future<List<Comment>> fetchComments(int postId) async {
    try {
      final response = await _dio.get(
        '/comments',
        queryParameters: {'postId': postId},
      );

      final List<dynamic> data = response.data;
      return data.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      rethrow; 
    }
  }
}
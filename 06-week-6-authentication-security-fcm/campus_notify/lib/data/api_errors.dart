import 'dart:io';
import 'package:dio/dio.dart';

/// Exception yang pesannya memang boleh tampil ke user.
class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

/// UI cukup memanggil ini, tidak perlu tahu DioException.
String friendlyMessage(Object error) {
  if (error is AppException) return error.message;
  if (error is DioException) return _fromDio(error);
  return 'Terjadi kesalahan. Silakan coba lagi.';
}

String _fromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Koneksi terlalu lama. Periksa sinyal lalu coba lagi.';
    case DioExceptionType.connectionError:
      return 'Tidak ada koneksi internet.';
    case DioExceptionType.badResponse:
      return switch (e.response?.statusCode) {
        401 => 'Sesi login berakhir. Silakan masuk lagi.',
        403 => 'Kamu tidak punya akses ke fitur ini.',
        404 => 'Data tidak ditemukan.',
        final c? when c >= 500 => 'Server sedang bermasalah. Coba beberapa saat lagi.',
        _ => 'Permintaan gagal. Silakan coba lagi.',
      };
    case DioExceptionType.cancel:
      return 'Permintaan dibatalkan.';
    default:
      if (e.error is SocketException) return 'Tidak ada koneksi internet.';
      return 'Terjadi kesalahan jaringan. Silakan coba lagi.';
  }
}
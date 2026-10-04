import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/data/api_errors.dart';
import 'package:campus_notify/messaging/route_from_message.dart';

DioException _dio(DioExceptionType t, {int? status}) => DioException(
      requestOptions: RequestOptions(path: '/'),
      type: t,
      response: status == null
          ? null
          : Response(requestOptions: RequestOptions(path: '/'), statusCode: status),
    );

void main() {
  group('routeFromMessage', () {
    test('rute valid dipakai', () {
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });
    test('hanya id -> rute pengumuman', () {
      expect(routeFromMessage({'id': '7'}), '/pengumuman/7');
    });
    test('kosong atau tidak dikenal -> home', () {
      expect(routeFromMessage({}), '/');
      expect(routeFromMessage({'route': '/login'}), '/');
      expect(routeFromMessage({'route': 'https://evil.test'}), '/');
    });
    test('route tanpa slash dinormalisasi', () {
     expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
   });
  });

  group('friendlyMessage', () {
    test('401', () {
      expect(friendlyMessage(_dio(DioExceptionType.badResponse, status: 401)),
          contains('Sesi login berakhir'));
    });
    test('timeout', () {
      expect(friendlyMessage(_dio(DioExceptionType.receiveTimeout)),
          contains('terlalu lama'));
    });
    test('offline', () {
      expect(friendlyMessage(_dio(DioExceptionType.connectionError)),
          contains('Tidak ada koneksi'));
    });
  });
}
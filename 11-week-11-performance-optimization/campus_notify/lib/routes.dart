import 'core/format.dart';

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const home = '/';
  static const notes = '/notes';

  /// Pola untuk GoRouter.
  static const announcementPattern = '/pengumuman/:id';

  /// Path nyata untuk navigasi dan deep link FCM.
  static String announcement(String id) => '/pengumuman/$id';

  /// Hanya rute yang dikenal yang boleh dibuka dari notifikasi.
  static bool isDeepLinkAllowed(String route) =>
      route == home || announcementIdFromRoute(route) != null;
}
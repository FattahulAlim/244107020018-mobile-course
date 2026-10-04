class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const home = '/';

  /// Pola untuk GoRouter.
  static const announcementPattern = '/pengumuman/:id';

  /// Path nyata untuk navigasi dan deep link FCM.
  static String announcement(String id) => '/pengumuman/$id';

  static final _announcementPath = RegExp(r'^/pengumuman/[A-Za-z0-9_-]+$');

  /// Hanya rute yang dikenal yang boleh dibuka dari notifikasi.
  static bool isDeepLinkAllowed(String route) =>
      route == home || _announcementPath.hasMatch(route);
}
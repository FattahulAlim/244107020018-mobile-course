const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String formatTanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

final _announcementRoute = RegExp(r'^/pengumuman/([A-Za-z0-9_-]+)$');

/// '/pengumuman/12' -> '12'. Selain itu -> null.
String? announcementIdFromRoute(String route) =>
    _announcementRoute.firstMatch(route)?.group(1);
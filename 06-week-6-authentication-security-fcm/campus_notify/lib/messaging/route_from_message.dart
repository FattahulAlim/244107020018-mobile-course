import '../routes.dart';

String routeFromMessage(Map<String, dynamic> data) {
  var route = data['route'];
  if (route is String && route.isNotEmpty) {
    if (!route.startsWith('/')) route = '/$route';
    if (AppRoutes.isDeepLinkAllowed(route)) return route;
  }

  // kalau hanya id yang dikirim.
  final id = data['id'];
  if (id is String && id.isNotEmpty) {
    final candidate = AppRoutes.announcement(id);
    if (AppRoutes.isDeepLinkAllowed(candidate)) return candidate;
  }
  return AppRoutes.home;
}
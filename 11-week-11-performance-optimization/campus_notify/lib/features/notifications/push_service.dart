import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'route_from_message.dart';

/// Token terpotong untuk halaman Debug (HomePage). Jangan simpan token penuh.
final fcmTokenPreview = ValueNotifier<String?>(null);

// [TANPA BuildContext] Wajib top-level, berjalan di isolate terpisah.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) debugPrint('BG message id: ${message.messageId}');
}

class PushService {
  PushService({
    required this.onToken,
    required this.onNavigate,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? local,
  })  : _fcm = messaging ?? FirebaseMessaging.instance,
        _local = local ?? FlutterLocalNotificationsPlugin();

  /// Kirim token ke backend. HARUS melempar error kalau gagal
  /// (jangan ditelan), supaya token bisa dicoba kirim ulang.
  final Future<void> Function(String token) onToken;

  /// Navigasi lewat callback, jadi service ini tidak memegang BuildContext.
  final void Function(String route) onNavigate;

  final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _local;

  static const topic = 'pengumuman-kampus';
  static const _channel = AndroidNotificationChannel(
    'pengumuman',
    'Pengumuman Kampus',
    importance: Importance.high,
  );

  String? _pendingToken;
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Listener dipasang DULU, supaya tetap jalan walau token/topik gagal.
    await _initLocalNotifications();
    _listenForeground();
    _listenOpenedFromBackground();

    await requestPermission();
    try {
      await _initToken();
      await subscribeTopic();
    } catch (e) {
      if (kDebugMode) debugPrint('Init FCM sebagian gagal: $e');
    }
  }

  Future<bool> requestPermission() async {
    // [ANDROID 13+] Izin runtime POST_NOTIFICATIONS (juga harus ada di
    // AndroidManifest.xml). [iOS] Selalu minta izin runtime.
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // [iOS] Biar sistem yang menampilkan banner saat foreground.
    if (_isIOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _initToken() async {
    // [iOS] getToken butuh APNs token lebih dulu.
    if (_isIOS) {
      for (var i = 0; i < 10 && await _fcm.getAPNSToken() == null; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    final token = await _fcm.getToken();
    if (token != null) await _send(token);

    // WAJIB: token baru juga dikirim ke backend.
    _fcm.onTokenRefresh.listen(_send);
  }

  Future<void> _send(String token) async {
    _pendingToken = token;
    fcmTokenPreview.value = '${token.substring(0, 12)}...';
    try {
      await onToken(token);
      _pendingToken = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Kirim token gagal, akan dicoba lagi: $e');
    }
  }

  /// Panggil setelah login berhasil (atau saat app aktif kembali).
  Future<void> flushPendingToken() async {
    final t = _pendingToken;
    if (t != null) await _send(t);
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null && route.isNotEmpty) onNavigate(route);
      },
    );
    // [ANDROID 8+] Channel harus dibuat dulu.
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((message) async {
      if (_isIOS) return; // iOS sudah ditampilkan sistem, hindari dobel.

      // [ANDROID] Foreground tidak ada banner otomatis, tampilkan manual.
      await _local.show(
        id: message.hashCode,
        title: message.notification?.title ?? 'Pengumuman',
        body: message.notification?.body ?? '',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: routeFromMessage(message.data),
      );
    });
  }

  void _listenOpenedFromBackground() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNavigate(routeFromMessage(message.data));
    });
  }

  /// Panggil SETELAH runApp dan status login selesai dimuat.
  Future<void> handleInitialMessage() async {
    final initial = await _fcm.getInitialMessage();
    if (initial != null) onNavigate(routeFromMessage(initial.data));
  }

  Future<void> subscribeTopic() => _fcm.subscribeToTopic(topic);
  Future<void> unsubscribeTopic() => _fcm.unsubscribeFromTopic(topic);
}
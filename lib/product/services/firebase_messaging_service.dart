import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:just_audio/just_audio.dart';
import 'package:foomoons/featured/tab/tab_mobile_view.dart';
import 'package:foomoons/featured/tab/tab_view.dart';

// Add GlobalKey for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NoTransitionRoute<T> extends MaterialPageRoute<T> {
  NoTransitionRoute({required WidgetBuilder builder})
      : super(builder: builder, maintainState: true);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return child;
  }

  @override
  Duration get transitionDuration => Duration.zero;
}

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AudioPlayer _player = AudioPlayer();
  final Ref _ref;

  FirebaseMessagingService(this._ref);

  Future<void> initialize() async {
    final authService = _ref.read(authServiceProvider);
    final businessId = await authService.getValidatedBusinessId();
    print('businessId: $businessId');
    try {
      // Bildirim izinlerini platform bağımsız olarak ayarla
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('${Platform.operatingSystem}: Bildirim izni alındı');

        // Topic subscription with dynamic businessId
        final topicName = 'kafe_$businessId';
        await _messaging.subscribeToTopic(topicName);
        debugPrint('Topic\'e abone olundu: $topicName');

        // iOS ve macOS için APNS token kontrolü
        if (Platform.isIOS || Platform.isMacOS) {
          await _checkAPNSToken();
        }

        // FCM token al ve logla
        String? token = await _messaging.getToken();
        if (token != null) {
          debugPrint('FCM Token: $token');
        } else {
          debugPrint('FCM token alınamadı');
        }

        // Bildirim dinleyicilerini ayarla
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp
            .listen(_handleBackgroundMessageClick);
      } else {
        debugPrint('${Platform.operatingSystem}: Bildirim izni reddedildi');
      }
    } catch (e) {
      debugPrint('Firebase Messaging başlatma hatası: $e');
    }
  }

  Future<void> _checkAPNSToken() async {
    for (int i = 0; i < 10; i++) {
      String? apnsToken = await _messaging.getAPNSToken();
      debugPrint('APNS Token Denemesi ${i + 1}: $apnsToken');

      if (apnsToken != null) {
        debugPrint('APNS token başarıyla alındı: $apnsToken');
        break;
      }

      if (i < 9) {
        debugPrint('APNS token bekleniyor... Deneme: ${i + 1}');
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Ön planda bildirim geldi!');
    debugPrint('Bildirim verisi: ${message.data}');

    if (message.notification != null) {
      debugPrint('Başlık: ${message.notification?.title}');
      debugPrint('İçerik: ${message.notification?.body}');

      // Siparişleri yenile
      if (message.notification?.title == 'Yeni Sipariş!') {
        await _ref.read(adminProvider.notifier).fetchAndLoad();
      }

      // Play notification sound
      try {
        await _player.setAsset('assets/sounds/notification.mp3');
        await _player.play();
      } catch (e) {
        debugPrint('Bildirim sesi çalma hatası: $e');
      }
    }
  }

  void _handleBackgroundMessageClick(RemoteMessage message) async {
    debugPrint('Arka plandaki bildirime tıklandı!');
    debugPrint('Bildirim verisi: ${message.data}');
    debugPrint('Platform: ${Platform.operatingSystem}');
    debugPrint(
        'Ekran genişliği: ${MediaQuery.of(navigatorKey.currentContext!).size.width}');

    // Önce siparişleri güncelle
    await _ref.read(adminProvider.notifier).fetchAndLoad();

    // Sonra navigasyonu yap
    final width = MediaQuery.of(navigatorKey.currentContext!).size.width;

    // Eğer ekran genişliği 600'den büyükse TabView'ı kullan
    if (width > 600) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const TabView(
            initialTabIndex: 1,
          ),
        ),
        (route) => false,
      );
    } else {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const TabMobileView(
            initialTabIndex: 1,
          ),
        ),
        (route) => false,
      );
    }
  }

  void _handleNotificationClick() {
    final width = MediaQuery.of(navigatorKey.currentContext!).size.width;

    // Eğer ekran genişliği 600'den büyükse TabView'ı kullan
    if (width > 600) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const TabView(
            initialTabIndex: 1,
          ),
        ),
        (route) => false,
      );
    } else {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const TabMobileView(
            initialTabIndex: 1,
          ),
        ),
        (route) => false,
      );
    }
  }

  Future<String?> getFCMToken() async {
    return await _messaging.getToken();
  }

  Future<void> unsubscribeFromTopic() async {
    try {
      // Önce mevcut token'ı temizle
      await _messaging.deleteToken();
      
      // Sonra topic'ten çıkış yap
      final authService = _ref.read(authServiceProvider);
      final businessId = await authService.getBusinessId(); // getValidatedBusinessId yerine getBusinessId kullanıyoruz
      
      if (businessId != null) {
        final topicName = 'kafe_$businessId';
        await _messaging.unsubscribeFromTopic(topicName);
        debugPrint('Topic\'ten çıkış yapıldı: $topicName');
      } else {
        debugPrint('BusinessId bulunamadı, topic\'ten çıkış yapılamadı');
      }
      
      // Yeni token oluştur
      await _messaging.getToken();
    } catch (e) {
      debugPrint('Topic\'ten çıkış yapılırken hata oluştu: $e');
    }
  }
}

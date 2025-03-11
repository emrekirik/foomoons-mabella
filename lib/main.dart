import 'package:foomoons/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:foomoons/featured/splash/splash_screen.dart';
import 'package:foomoons/featured/tab/tab_mobile_view.dart';
import 'package:foomoons/featured/auth/login_view.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/product/services/firebase_messaging_service.dart';
import 'package:flutter/services.dart';
import 'package:foomoons/product/init/application_init.dart';

// FirebaseMessagingService'deki navigatorKey'i kullanan provider
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return navigatorKey;
});

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AppEnvironment first
  await initialize();

  // Then initialize Firebase
  debugPrint("Firebase başlatılıyor...");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Firebase başlatıldı");

  // Ekran yönünü dikey olarak sabitle
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      final messagingService = ref.read(firebaseMessagingServiceProvider);
      await messagingService.initialize();
    } catch (e) {
      debugPrint('❌ Uygulama başlatma hatası: $e');
      if (mounted && e.toString().contains('BusinessId bulunamadı')) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'FooMoons',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => LoginView(),
        '/tab': (context) => Consumer(builder: (context, ref, child) {
              final providedIndex =
                  ModalRoute.of(context)?.settings.arguments as int?;
              final defaultIndex = ref.read(initialIndexProvider);
              return TabMobileView(
                initialTabIndex: providedIndex ?? defaultIndex,
              );
            }),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', ''),
      ],
      locale: const Locale('tr'),
    );
  }
}

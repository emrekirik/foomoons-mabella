import 'package:flutter/material.dart';
import 'package:foomoons/featured/auth/auth_wrapper.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Önce login durumunu kontrol et
      final authService = ref.read(authServiceProvider);
      final isLoggedIn = await authService.isLoggedIn();

      if (isLoggedIn) {
        // Firebase Messaging servisini al
        final messagingService = ref.read(firebaseMessagingServiceProvider);
        await messagingService.initialize();

        final listenerService = ref.read(firestoreListenerServiceProvider);
        await listenerService.initialize();

        // Sadece giriş yapılmışsa verileri çek
        final tablesNotifier = ref.read(tablesProvider.notifier);
        final menuNotifier = ref.read(menuProvider.notifier);
        final profileNotifier = ref.read(profileProvider.notifier);

        print('🔍 Splash Screen - Loading initial data...');

        await Future.wait([
          tablesNotifier.fetchAndLoad(),
          menuNotifier.fetchAndLoad(),
          profileNotifier.fetchAndLoad(),
        ]);

        // Verilerin yüklendiğinden emin ol
        final tablesState = ref.read(tablesProvider);
        final menuState = ref.read(menuProvider);
        final profileState = ref.read(profileProvider);

        print(
            '🔍 Splash Screen - Profile State: ${profileState.isSelfService}');

        if (tablesState.tables == null || tablesState.areas == null) {
          throw Exception('Masa verileri yüklenemedi');
        }

        if (menuState.products == null || menuState.categories == null) {
          throw Exception('Menü verileri yüklenemedi');
        }
      }

      if (mounted) {
        await Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthWrapper(),
            transitionDuration: Duration.zero,
          ),
        );
      }
    } catch (e) {
      print('❌ Uygulama başlatma hatası: $e');
      // Hata durumunda kullanıcıya bilgi ver veya yeniden deneme seçeneği sun
    }
  }

  @override
  Widget build(BuildContext context) {
    print('splash screen girildi');
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        color: Colors.white,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Image(
                        image: AssetImage('assets/images/logo.png'),
                        width: 150,
                        height: 150,
                      ),
                      const SizedBox(height: 30),
                      LoadingAnimationWidget.flickr(
                        leftDotColor: const Color(0xFFFF8A00),
                        rightDotColor: const Color(0xFF00B761),
                        size: 45,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

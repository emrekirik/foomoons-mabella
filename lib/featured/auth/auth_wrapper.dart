import 'package:foomoons/featured/auth/login_view.dart';
import 'package:foomoons/featured/providers/login_notifier.dart';
import 'package:foomoons/featured/responsive/responsive_layout.dart';
import 'package:foomoons/featured/tab/tab_mobile_view.dart';
import 'package:foomoons/featured/tab/tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  late Future<bool> _loginCheckFuture;

  @override
  void initState() {
    super.initState();
    _loginCheckFuture = ref.read(authServiceProvider).isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    print('auth wrapper girildi');
    return FutureBuilder<bool>(
      future: _loginCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isLoggedIn = snapshot.data ?? false;

        return Container(
          color: Colors.white,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isLoggedIn
                ? const ResponsiveLayout(
                    key: ValueKey('home'),
                    desktopBody: TabView(),
                    mobileBody: TabMobileView(),
                  )
                : LoginView(key: const ValueKey('login')),
          ),
        );
      },
    );
  }
}

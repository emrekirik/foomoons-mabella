import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/services/auth_service.dart';
import 'package:foomoons/product/providers/app_providers.dart';

final authServiceProvider = Provider((ref) => AuthService(ref));

class LoginNotifier extends StateNotifier<LoginState> {
  final AuthService _authService;
  final Ref ref;

  LoginNotifier({required AuthService authService, required this.ref})
      : _authService = authService,
        super(LoginState());

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    if (!mounted) return null;
    state = state.copyWith(isLoading: true);
    
    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result['success']) {
        // Login başarılı olduğunda kullanıcı bilgilerini çek
        if (mounted) {
          await _authService.getUserByEmail(email);
          
          // Firebase Messaging servisini başlat
          final messagingService = ref.read(firebaseMessagingServiceProvider);
          await messagingService.initialize();

          final listenerService = ref.read(firestoreListenerServiceProvider);
          await listenerService.initialize();
        }
      }

      return result['message'];
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> signOut() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      // Firebase messaging topic'ten çıkış yap
      final messagingService = ref.read(firebaseMessagingServiceProvider);
      await messagingService.unsubscribeFromTopic();
      
      // Firestore listener'ı sonlandır
      final listenerService = ref.read(firestoreListenerServiceProvider);
      listenerService.dispose();
      
      await _authService.logout();
      
      // Reset all states
      ref.read(adminProvider.notifier).resetState();
      ref.read(menuProvider.notifier).resetState();
      ref.read(profileProvider.notifier).resetProfile();
      ref.read(reportsProvider.notifier).resetState();
      ref.read(tablesProvider.notifier).resetState();
      
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void toggleObscureText() {
    state = state.copyWith(isObscured: !state.isObscured);
  }
}

class LoginState {
  final bool isLoading;
  final bool isObscured;

  LoginState({
    this.isLoading = false,
    this.isObscured = true,
  });

  LoginState copyWith({
    bool? isLoading,
    bool? isObscured,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      isObscured: isObscured ?? this.isObscured,
    );
  }
}

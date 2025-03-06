import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/featured/providers/loading_notifier.dart';
import 'package:foomoons/featured/providers/profile_notifier.dart';
import 'package:foomoons/featured/providers/reports_notifier.dart';
import 'package:foomoons/featured/providers/tables_notifier.dart';
import 'package:foomoons/featured/providers/menu_notifier.dart';
import 'package:foomoons/featured/providers/login_notifier.dart';
import 'package:foomoons/featured/providers/admin_notifier.dart';
import 'package:foomoons/product/services/area_service.dart';
import 'package:foomoons/product/services/auth_service.dart';
import 'package:foomoons/product/services/report_service.dart';
import 'package:foomoons/product/services/table_service.dart';
import 'package:foomoons/product/services/product_service.dart';
import 'package:foomoons/product/services/category_service.dart';
import 'package:foomoons/product/services/firebase_messaging_service.dart';
import 'package:foomoons/product/services/firestore_listener_service.dart';
import 'package:foomoons/product/services/order_service.dart';
import 'package:foomoons/product/services/settings_service.dart';

// Service Provider Factory
class ServiceProvider {
  const ServiceProvider._(); // private constructor

  // AuthService gerektiren servisler için
  static Provider<T> withAuth<T>(T Function(AuthService) creator) {
    return Provider<T>((ref) {
      final auth = ref.watch(authServiceProvider);
      return creator(auth);
    });
  }

  // Sadece Ref gerektiren servisler için
  static Provider<T> withRef<T>(T Function(Ref) creator) {
    return Provider<T>((ref) => creator(ref));
  }
}

// Auth providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref));

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(
    authService: ref.read(authServiceProvider),
    ref: ref,
  );
});

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});

// Settings provider
final settingsServiceProvider = Provider((ref) => SettingsService());

// Other global providers
final adminProvider = StateNotifierProvider<AdminNotifier, HomeState>((ref) {
  return AdminNotifier(ref);
});

final tablesProvider =
    StateNotifierProvider<TablesNotifier, TablesState>((ref) {
  return TablesNotifier(ref);
});

final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  return MenuNotifier(ref);
});

final reportsProvider =
    StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  return ReportsNotifier(ref);
});

// Service providers with factory
final reportServiceProvider =
    ServiceProvider.withAuth((auth) => ReportService(authService: auth));

final tableServiceProvider =
    ServiceProvider.withAuth((auth) => TableService(authService: auth));

final productServiceProvider =
    ServiceProvider.withAuth((auth) => ProductService(authService: auth));

final categoryServiceProvider =
    ServiceProvider.withAuth((auth) => CategoryService(authService: auth));

final areaServiceProvider =
    ServiceProvider.withAuth((auth) => AreaService(authService: auth));

final firebaseMessagingServiceProvider =
    ServiceProvider.withRef((ref) => FirebaseMessagingService(ref));

final firestoreListenerServiceProvider =
    ServiceProvider.withRef((ref) => FirestoreListenerService(ref));

final orderServiceProvider =
    ServiceProvider.withAuth((auth) => OrderService(authService: auth));

final loadingProvider =
    StateNotifierProvider<LoadingNotifier, LoadingState>((ref) {
  return LoadingNotifier();
});

// User type provider
final userTypeProvider = FutureProvider<String>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final userType = await authService.getUserType();
  return userType ?? 'kafe'; // Default to 'kafe' if not set
});

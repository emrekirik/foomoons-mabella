import 'package:foomoons/main.dart';
import 'package:foomoons/product/model/order.dart' as app;
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:foomoons/product/utility/firebase/firebase_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:foomoons/product/model/order.dart';

class AdminNotifier extends StateNotifier<HomeState> with FirebaseUtility {
  final Ref _ref;
  final uuid = const Uuid();
  Timer? _centralTimer;
  StreamSubscription? _orderSubscription;
  final player = AudioPlayer();

  DateTime? _lastFetchTime;
  static const _cacheValidityDuration = Duration(minutes: 30);

  AdminNotifier(this._ref) : super(const HomeState()) {
    _setupMessageListeners();
  }

  void _setupMessageListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification?.title == 'Yeni Sipariş!' ||
          message.data['type'] == 'new_order') {
        fetchAndLoad(forceRefresh: true);
        playNotificationSound();
        showOrderAlert();
      }
    });
  }

  String? _selectedValue;
  String? get selectedValue => _selectedValue;

  @override
  void dispose() {
    _centralTimer?.cancel();
    _orderSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchOrdersStream() async {
    try {
      final orderService = _ref.read(orderServiceProvider);
      final orders = await orderService.fetchOrders();
      final menuState = _ref.read(menuProvider);
      
      final updatedOrders = orders.map((order) {
        final originalProduct = menuState.products
            ?.where((menu) => menu.id == order.productId)
            .firstOrNull;
            
        if (originalProduct != null) {
          return order.copyWith(
            title: originalProduct.title,
            price: originalProduct.price ?? order.price,
          );
        }
        return order;
      }).toList();

      final sortedOrders = List<Order>.from(updatedOrders)
        ..sort((a, b) {
          final aDate = a.orderDate;
          final bDate = b.orderDate;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.toDate().compareTo(aDate.toDate());
        });

      state = state.copyWith(orders: sortedOrders);
    } catch (e) {
      print('Siparişleri getirirken hata oluştu: $e');
    }
  }

  Future<void> fetchAndLoad({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration &&
        state.orders != null) {
      return;
    }

    _ref.read(loadingProvider.notifier).setLoading('admin', true);
    try {
      await fetchOrdersStream();
      _lastFetchTime = DateTime.now();
      print('Siparişler güncellendi: ${state.orders?.length} adet sipariş var');
    } catch (e) {
      print('Veri yükleme hatası: $e');
    } finally {
      _ref.read(loadingProvider.notifier).setLoading('admin', false);
    }
  }

  Future<void> updateOrderStatus(Order order, String status, {String? orderType}) async {
    try {
      final orderService = _ref.read(orderServiceProvider);
      final updatedOrder = order.copyWith(
        status: status,
        orderType: orderType,
      );
      final (success, resultOrder) = await orderService.updateOrder(updatedOrder, status);

      if (success && resultOrder != null) {
        if (status == 'teslim edildi' && order.tableTitle != null) {
          try {
            final tableService = _ref.read(tableServiceProvider);
            final tableId = await tableService.getTableIdByTitle(order.tableTitle!);

            if (tableId != null) {
              final menuState = _ref.read(menuProvider);
              final originalProduct = menuState.products
                  ?.where((menu) => menu.id == order.productId)
                  .firstOrNull;

              final menuItem = Menu(
                title: originalProduct?.title ?? order.title,
                price: originalProduct?.price ?? order.price?.toDouble(),
                piece: order.piece,
                tableId: tableId,
                category: originalProduct?.category ?? 'Sipariş',
                status: status,
                isAmount: null,
                isCredit: null,
                createdAt: order.orderDate?.toDate(),
              );

              await tableService.addItemToBill(menuItem);
            }
          } catch (e) {
            print('Adisyon işlemi başarısız: $e');
          }
        }

        final currentOrders = List<Order>.from(state.orders ?? []);
        final orderIndex = currentOrders.indexWhere((o) => o.id == order.id);

        if (orderIndex != -1) {
          currentOrders[orderIndex] = resultOrder;
          state = state.copyWith(orders: currentOrders);
        }
      } else {
        print('❌ HATA: Sipariş durumu güncellenemedi');
      }
    } catch (e) {
      print('Sipariş durumu güncellenirken hata oluştu: $e');
    }
  }

  void playNotificationSound() async {
    try {
      await player.setUrl('assets/assets/sounds/notification.mp3');
      player.play();
    } catch (e) {
      print('Ses çalınamadı: $e');
    }
  }

  void showOrderAlert() {
    final context = _ref.read(navigatorKeyProvider).currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Yeni bir sipariş var.'),
          action: SnackBarAction(
            label: 'Tamam',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void resetState() {
    state = const HomeState();
  }
}

class HomeState extends Equatable {
  const HomeState({
    this.orders,
    this.selectedValue,
  });

  final List<app.Order>? orders;
  final String? selectedValue;

  @override
  List<Object?> get props => [orders, selectedValue];

  HomeState copyWith({
    List<app.Order>? orders,
    String? selectedValue,
  }) {
    return HomeState(
      orders: orders ?? this.orders,
      selectedValue: selectedValue ?? this.selectedValue,
    );
  }
}

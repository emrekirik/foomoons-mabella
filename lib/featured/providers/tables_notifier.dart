import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:foomoons/product/model/area.dart';
import 'package:foomoons/product/model/category.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:foomoons/product/model/table.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/model/order.dart' as app;
import 'package:uuid/uuid.dart';


class TablesNotifier extends StateNotifier<TablesState> {
  static const String allCategories = 'Tüm Kategoriler';
  static const String allTables = 'Masalar';
  final Ref ref; // Ref instance to manage the global provider
  final uuid = const Uuid();
  StreamSubscription? _orderSubscription;
  bool isLoading = false;
  DateTime? _lastFetchTime;
  static const _cacheValidityDuration = Duration(minutes: 30);
  
  // İşlem kuyruğu için gerekli değişkenler
  final Queue<Future<void> Function()> _queue = Queue();
  bool _processing = false;
  final Map<String, bool> _pendingItems = {};

  TablesNotifier(this.ref) : super(const TablesState());

  // Kuyruğu işleyecek metod
  Future<void> _processQueue() async {
    if (_processing) return;
    _processing = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();
      try {
        await task();
      } catch (e) {
        print('Error processing queue item: $e');
      }
    }

    _processing = false;
  }

  // Kuyruklu addItemToBill metodu
  Future<void> addItemToBillQueued(Menu item) async {
    final itemKey = '${item.id}_${item.tableId}';
    _pendingItems[itemKey] = true;
    state = state.copyWith(pendingItems: Map.from(_pendingItems));
    
    _queue.add(() async {
      try {
        await _addItemToBill(item);
      } finally {
        _pendingItems.remove(itemKey);
        state = state.copyWith(pendingItems: Map.from(_pendingItems));
      }
    });
    _processQueue();
  }

  // Asıl işlemi yapan private metod
  Future<void> _addItemToBill(Menu item) async {
    try {
      print('🔍 Masa slm #${item.tableId} için mevcut adisyon kontrol ediliyor...');
      final currentBillItems = state.tableBills[item.tableId!] ?? [];
      final tableService = ref.read(tableServiceProvider);
      final addedItem = await tableService.addItemToBill(item, currentBillItems);
      state = state.copyWith(
        tableBills: {
          ...state.tableBills,
          item.tableId!: [...currentBillItems, addedItem],
        },
      );
    } catch (e, stackTrace) {
      print('Error: $e');
      print('Stack trace: $stackTrace');
      _handleError(e, 'Hesaba ürün ekleme hatası');
      rethrow;
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel(); // Firestore dinleyicisini iptal et
    super.dispose(); // StateNotifier'ın dispose metodunu çağır
  }

  Future<void> fetchAndLoad() async {
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration &&
        state.tables != null &&
        state.areas != null) {
      print('🔄 Tables cache geçerli, veriler yüklü. Fetch atlanıyor.');
      return;
    }

    print('📥 Tables verileri fetch ediliyor...');
    ref.read(loadingProvider.notifier).setLoading('tables', true);
    try {
      await Future.wait([
        fetchTables(),
        fetchAreas(),
      ]);
      _lastFetchTime = DateTime.now();
      print('✅ Tables verileri başarıyla yüklendi ve cache güncellendi.');
    } catch (e) {
      print('❌ Tables veri yükleme hatası: $e');
      _lastFetchTime = null;
    } finally {
      ref.read(loadingProvider.notifier).setLoading('tables', false);
    }
  }

  Future<void> fetchTables() async {
    final tableService = ref.read(tableServiceProvider);
    final tables = await tableService.fetchTables();
    state = state.copyWith(tables: tables);
  }

  Future<void> addTable(CoffeTable table) async {
    final tableService = ref.read(tableServiceProvider);
    final addedTable = await tableService.addTable(table);
    state = state.copyWith(tables: [...?state.tables, addedTable]);
    invalidateCache(); // Cache'i temizle çünkü veri değişti
  }

  Future<void> fetchAreas() async {
    final areaService = ref.read(areaServiceProvider);
    final areas = await areaService.fetchAreas();
    state = state.copyWith(areas: areas);
  }

  Future<void> addArea(Area newArea) async {
    final areaService = ref.read(areaServiceProvider);
    final addedArea = await areaService.addArea(newArea);
    state = state.copyWith(areas: [...?state.areas, addedArea]);
  }

  Future<void> fetchTableBillApi(int tableId) async {
    try {
      final tableService = ref.read(tableServiceProvider);
      final tableBill = await tableService.fetchTableBill(tableId);
      state = state.copyWith(
        tableBills: {
          ...state.tableBills,
          tableId: tableBill,
        },
      );
    } catch (e) {
      _handleError(e, 'Masa adisyonu çekerken hata oluştu');
    }
  }

  Future<String> generateQRCode(String tableId) async {
    try {
      final authService = ref.read(authServiceProvider);
      final businessId = await authService.getBusinessId();
      // businessId ve tableId'yi şifreliyoruz
      final String token =
          base64Encode(utf8.encode('businessId:$businessId,tableId:$tableId'));

      final Uri menuUrl = Uri(
        scheme: 'http',
        host: 'foomoons.com', // veya IP adresi
        path: '/menu/', // API'nin path kısmı
      );
      final String finalUrl = '$menuUrl#/?token=$token';
      print(finalUrl);

      return finalUrl;
    } catch (e) {
      print('QR kod oluşturma hatası: $e');
      rethrow;
    }
  }

  void selectArea(String? areaName) {
    state = state.copyWith(selectedValue: areaName);
  }

  Future<bool> hesabiKapat(int tableId) async {
    ref.read(loadingProvider.notifier).setLoading('table_$tableId', true);
    try {
      final tableService = ref.read(tableServiceProvider);
      final result = await tableService.closeBill(tableId);
      
      if (result) {
        // Update local state - masanın adisyonunu state'den temizle
        state = state.copyWith(
          tableBills: {...state.tableBills}..remove(tableId),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Hesap kapatma hatası: $e');
      return false;
    } finally {
      ref.read(loadingProvider.notifier).setLoading('table_$tableId', false);
    }
  }

  /// Helper method to handle errors
  void _handleError(Object e, String message) {
    print('$message: $e');
  }

  void invalidateCache() {
    _lastFetchTime = null;
  }

  void resetState() {
    state = const TablesState();
  }

  Future<bool> deleteTable(int tableId) async {
    try {
      final tableService = ref.read(tableServiceProvider);
      final result = await tableService.deleteTable(tableId);
      
      if (result) {
        // Update local state - remove the table from state
        state = state.copyWith(
          tables: state.tables?.where((table) => table.id != tableId).toList(),
          tableBills: {...state.tableBills}..remove(tableId),
        );
        invalidateCache(); // Cache'i temizle çünkü veri değişti
      }
      return result;
    } catch (e) {
      print('Masa silme hatası: $e');
      return false;
    }
  }

  Future<bool> mergeTables({required int sourceTableId, required int targetTableId}) async {
    try {
      final tableService = ref.read(tableServiceProvider);
      final result = await tableService.mergeTables(sourceTableId, targetTableId);
      
      if (result) {
        // Kaynak masanın adisyonunu state'den temizle
        state = state.copyWith(
          tableBills: {...state.tableBills}..remove(sourceTableId),
        );
        
        // Hedef masanın adisyonunu güncelle
        await fetchTableBillApi(targetTableId);
        
        invalidateCache(); // Cache'i temizle çünkü veri değişti
      }
      return result;
    } catch (e) {
      print('Masa birleştirme hatası: $e');
      return false;
    }
  }

  // Sadece frontend için adisyon güncellemesi
  void updateTableBill(int tableId, List<Menu> items) {
    final currentBills = Map<int, List<Menu>>.from(state.tableBills);
    currentBills[tableId] = items;
    state = state.copyWith(tableBills: currentBills);
  }
}

class TablesState extends Equatable {
  const TablesState({
    this.menus,
    this.orders,
    this.categories,
    this.selectedValue,
    this.tables,
    this.tableBills = const {},
    this.isLoading = false,
    this.areas,
    this.pendingItems = const {},
  });

  final List<app.Order>? orders;
  final List<Menu>? menus;
  final List<Category>? categories;
  final String? selectedValue;
  final List<CoffeTable>? tables;
  final Map<int, List<Menu>> tableBills;
  final bool isLoading;
  final List<Area>? areas;
  final Map<String, bool> pendingItems;

  @override
  List<Object?> get props =>
      [orders, categories, selectedValue, tables, tableBills, menus, isLoading, pendingItems];

  TablesState copyWith({
    List<app.Order>? orders,
    List<Menu>? menus,
    List<Category>? categories,
    String? selectedValue,
    List<CoffeTable>? tables,
    Map<int, List<Menu>>? tableBills,
    bool? isLoading,
    List<Area>? areas,
    Map<String, bool>? pendingItems,
  }) {
    return TablesState(
      orders: orders ?? this.orders,
      menus: menus ?? this.menus,
      categories: categories ?? this.categories,
      selectedValue: selectedValue ?? this.selectedValue,
      tables: tables ?? this.tables,
      tableBills: tableBills ?? this.tableBills,
      isLoading: isLoading ?? this.isLoading,
      areas: areas ?? this.areas,
      pendingItems: pendingItems ?? this.pendingItems,
    );
  }

  List<Menu> getTableBill(int tableId) {
    return tableBills[tableId] ?? [];
  }
}

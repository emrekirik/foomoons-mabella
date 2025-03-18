import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/product/services/settings_service.dart';

class ReportsNotifier extends StateNotifier<ReportsState> {
  static const String allCategories = 'Tüm Kategoriler';
  final Ref ref;
  final SettingsService _settingsService = SettingsService();

  ReportsNotifier(this.ref) : super(const ReportsState());

  DateTime _getAdjustedDateTime(DateTime date) {
    // Eğer saat 00:00 ile 05:59 arasındaysa, bir önceki güne ait sayılır
    if (date.hour < 6) {
      return date.subtract(const Duration(days: 1));
    }
    return date;
  }

  Future<void> fetchPastBillItemsAndCalculate(String period) async {
    try {
      final reportService = ref.read(reportServiceProvider);
      final responseData = await reportService.fetchPastBillItems();

      final DateTime now = DateTime.now();
      // Şu anki zamanı gün başlangıcına göre ayarla
      final DateTime adjustedNow = _getAdjustedDateTime(now);

      // Periyoda göre toplam değerler için filtreleme
      final List<dynamic> filteredDataForTotals = responseData.where((item) {
        if (item['preparationTime'] == null) return false;

        final DateTime itemDate = DateTime.parse(item['preparationTime']);
        final DateTime adjustedItemDate = _getAdjustedDateTime(itemDate);

        switch (period) {
          case 'Günlük':
            return adjustedItemDate.year == adjustedNow.year &&
                   adjustedItemDate.month == adjustedNow.month &&
                   adjustedItemDate.day == adjustedNow.day;

          case 'Haftalık':
            final difference = adjustedNow.difference(adjustedItemDate).inDays;
            return difference <= 7;

          case 'Aylık':
            return adjustedItemDate.year == adjustedNow.year &&
                   adjustedItemDate.month == adjustedNow.month;

          default:
            return true;
        }
      }).toList();

      // Son 30 gün için ayrı filtreleme (grafik için)
      final List<dynamic> lastThirtyDaysData = responseData.where((item) {
        if (item['preparationTime'] == null) return false;

        final DateTime itemDate = DateTime.parse(item['preparationTime']);
        final DateTime adjustedItemDate = _getAdjustedDateTime(itemDate);
        final difference = adjustedNow.difference(adjustedItemDate).inDays;

        // Son 30 günü kontrol et
        return difference <= 30;
      }).toList();

      // Toplam değerler için hesaplama
      int totalRevenues = 0;
      int totalCredit = 0;
      int totalCash = 0;
      int totalOrder = 0;
      int totalEntry = 0;

      for (var item in filteredDataForTotals) {
        final price = (item['price'] as num).toInt();
        totalRevenues += price;

        // Giriş kategorisinde olmayan itemları say
        if (item['category'] != 'Giriş') {
          totalOrder++;
        }

        // Giriş Ücreti ve TUSTIME KARABUK sayısını hesapla
        if (item['title'] == 'Giriş Ücreti' ||
            item['title'] == 'TUSTIME KARABUK' ||
            item['title'] == 'Deneme Sonrası Giriş' ||
            item['title'] == 'Giriş ve Sınırsız Çay/Filtre Kahve' ||
            item['title'] == 'Deneme Sonrası Giriş') {
          totalEntry++;
        }

        if (item['isCredit'] == true) {
          totalCredit += price;
        } else {
          totalCash += price;
        }
      }

      // Son 30 gün için grafik verilerini hesaplama
      Map<String, DailyStats> dailyStats = {};

      // Son 30 günün tarihlerini oluştur
      for (int i = 0; i < 30; i++) {
        final date = adjustedNow.subtract(Duration(days: i));
        final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        dailyStats[dateStr] = DailyStats(
          totalRevenue: 0,
          creditTotal: 0,
          cashTotal: 0,
          orderCount: 0,
          entryCount: 0,
          date: date,
        );
      }

      // Her işlemi uygun güne ekle
      for (var item in lastThirtyDaysData) {
        if (item['preparationTime'] != null) {
          final DateTime preparationTime = DateTime.parse(item['preparationTime']);
          final DateTime adjustedDate = _getAdjustedDateTime(preparationTime);
          final dateStr = "${adjustedDate.year}-${adjustedDate.month.toString().padLeft(2, '0')}-${adjustedDate.day.toString().padLeft(2, '0')}";
          
          if (dailyStats.containsKey(dateStr)) {
            final price = (item['price'] as num).toInt();
            final isCredit = item['isCredit'] == true;
            final isEntry = item['title'] == 'Giriş Ücreti' ||
                item['title'] == 'TUSTIME KARABUK' ||
                item['title'] == 'Deneme Sonrası Giriş' ||
                item['title'] == 'Giriş ve Sınırsız Çay/Filtre Kahve';
            
            final currentStats = dailyStats[dateStr]!;
            dailyStats[dateStr] = DailyStats(
              totalRevenue: currentStats.totalRevenue + price,
              creditTotal: currentStats.creditTotal + (isCredit ? price : 0),
              cashTotal: currentStats.cashTotal + (isCredit ? 0 : price),
              orderCount: currentStats.orderCount + (isEntry ? 0 : 1),
              entryCount: currentStats.entryCount + (isEntry ? 1 : 0),
              date: currentStats.date,
            );
          }
        }
      }

      state = state.copyWith(
        totalRevenues: totalRevenues,
        totalCredit: totalCredit,
        totalCash: totalCash,
        totalOrder: totalOrder,
        totalEntry: totalEntry,
        dailyStats: dailyStats,
      );
    } catch (e) {
      _handleError(e, 'API\'den geçmiş fatura öğelerini çekerken hata oluştu');
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return "Pazartesi";
      case 2:
        return "Salı";
      case 3:
        return "Çarşamba";
      case 4:
        return "Perşembe";
      case 5:
        return "Cuma";
      case 6:
        return "Cumartesi";
      case 7:
        return "Pazar";
      default:
        return "";
    }
  }

  Future<void> fetchAndLoad(String period) async {
    if (!mounted) return;

    try {
      ref.read(loadingProvider.notifier).setLoading('reports', true);
      await Future.microtask(() async {
        await fetchPastBillItemsAndCalculate(period);
      });
    } catch (e) {
      _handleError(e, 'Veri yükleme hatası');
    } finally {
      if (mounted) {
        ref.read(loadingProvider.notifier).setLoading('reports', false);
      }
    }
  }

  void _handleError(Object e, String message) {
    print('$message: $e');
  }

  void resetState() {
    state = const ReportsState();
  }

  /* Future<void> fetchEmployees() async {
    try {
      final responseData = await _reportService.fetchEmployees();
      final List<dynamic> data = responseData['data'];
      state = state.copyWith(employees: data.cast<Map<String, dynamic>>());
    } catch (e) {
      _handleError(e, 'Çalışanları getirme hatası');
    }
  } */
}

class ReportsState extends Equatable {
  const ReportsState({
    this.totalOrder,
    this.totalRevenues,
    this.totalProduct,
    this.totalCredit,
    this.totalCash,
    this.totalEntry = 0,
    this.dailyStats = const {},
    this.employees = const [],
    this.pastBillItems = const [],
  });

  final int? totalOrder;
  final int? totalRevenues;
  final int? totalProduct;
  final int? totalCredit;
  final int? totalCash;
  final int totalEntry;
  final Map<String, DailyStats> dailyStats;
  final List<Map<String, dynamic>> employees;
  final List<dynamic> pastBillItems;

  @override
  List<Object?> get props => [
        totalOrder,
        totalRevenues,
        totalProduct,
        employees,
        dailyStats,
        totalCredit,
        totalCash,
        totalEntry,
        pastBillItems
      ];

  ReportsState copyWith({
    int? totalOrder,
    int? totalRevenues,
    int? totalProduct,
    int? totalCredit,
    int? totalCash,
    int? totalEntry,
    Map<String, DailyStats>? dailyStats,
    List<Map<String, dynamic>>? employees,
    List<dynamic>? pastBillItems,
  }) {
    return ReportsState(
        totalOrder: totalOrder ?? this.totalOrder,
        totalRevenues: totalRevenues ?? this.totalRevenues,
        totalProduct: totalProduct ?? this.totalProduct,
        dailyStats: dailyStats ?? this.dailyStats,
        employees: employees ?? this.employees,
        totalCredit: totalCredit ?? this.totalCredit,
        totalCash: totalCash ?? this.totalCash,
        totalEntry: totalEntry ?? this.totalEntry,
        pastBillItems: pastBillItems ?? this.pastBillItems);
  }
}

class DailyStats {
  final int totalRevenue;
  final int creditTotal;
  final int cashTotal;
  final int orderCount;
  final int entryCount;
  final DateTime date;

  DailyStats({
    required this.totalRevenue,
    required this.creditTotal,
    required this.cashTotal,
    required this.orderCount,
    required this.entryCount,
    required this.date,
  });
}

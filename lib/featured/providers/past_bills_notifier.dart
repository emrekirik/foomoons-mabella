import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';

class PastBillsState extends Equatable {
  final List<Map<String, dynamic>>? pastBills;
  final Map<String, dynamic>? selectedBillDetails;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? startDate;
  final DateTime? endDate;

  const PastBillsState({
    this.pastBills,
    this.selectedBillDetails,
    this.isLoading = false,
    this.errorMessage,
    this.startDate,
    this.endDate,
  });

  PastBillsState copyWith({
    List<Map<String, dynamic>>? pastBills,
    Map<String, dynamic>? selectedBillDetails,
    bool? isLoading,
    String? errorMessage,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return PastBillsState(
      pastBills: pastBills ?? this.pastBills,
      selectedBillDetails: selectedBillDetails,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [
        pastBills,
        selectedBillDetails,
        isLoading,
        errorMessage,
        startDate,
        endDate,
      ];
}

class PastBillsNotifier extends StateNotifier<PastBillsState> {
  final Ref ref;
  DateTime? _lastFetchTime;
  static const _cacheValidityDuration = Duration(minutes: 15);

  PastBillsNotifier(this.ref) : super(const PastBillsState());

  Future<void> fetchPastBills({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    // Aynı tarih aralığı için kısa süre önce çağrı yapılmışsa ve forceRefresh değilse, önbellekli verileri kullan
    if (!forceRefresh && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration &&
        state.pastBills != null &&
        state.startDate == startDate &&
        state.endDate == endDate) {
      print('🔄 Geçmiş adisyonlar önbelleği geçerli, veri yüklü. Fetch atlanıyor.');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      startDate: startDate,
      endDate: endDate,
    );

    try {
      final pastBillsService = ref.read(pastBillsServiceProvider);
      final pastBills = await pastBillsService.fetchPastBills(
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        pastBills: pastBills,
        isLoading: false,
      );

      _lastFetchTime = DateTime.now();
      
    } catch (e) {
      print('❌ Geçmiş adisyonlar alınırken hata: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Geçmiş adisyonlar alınırken hata oluştu: $e',
      );
    }
  }

  Future<void> fetchPastBillDetails(int billId) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final pastBillsService = ref.read(pastBillsServiceProvider);
      final billDetails = await pastBillsService.fetchPastBillDetails(billId);

      state = state.copyWith(
        selectedBillDetails: billDetails,
        isLoading: false,
      );
    } catch (e) {
      print('❌ Adisyon detayları alınırken hata: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Adisyon detayları alınırken hata oluştu: $e',
      );
    }
  }

  void resetSelectedBill() {
    state = state.copyWith(
      selectedBillDetails: null,
    );
  }

  void selectBill(Map<String, dynamic> bill) {
    // Adisyon verilerini doğru formata dönüştür
    final formattedBillDetails = {
      'data': {
        'closedBill': bill['rawData'],
        'pastBillItems': bill['pastBillItems'],
      }
    };
    
    state = state.copyWith(
      selectedBillDetails: formattedBillDetails,
    );
  }

  void invalidateCache() {
    _lastFetchTime = null;
  }

  void resetState() {
    state = const PastBillsState();
    _lastFetchTime = null;
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:foomoons/featured/providers/past_bills_notifier.dart';
import 'package:foomoons/product/constants/color_constants.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/product/model/table.dart';
import 'package:intl/intl.dart';

class PastBillsView extends ConsumerStatefulWidget {
  const PastBillsView({super.key});

  @override
  ConsumerState<PastBillsView> createState() => _PastBillsViewState();
}

class _PastBillsViewState extends ConsumerState<PastBillsView> {
  String selectedPeriod = 'Günlük';
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  // Masa ID'lerine göre masa isimlerini al
  String getTableName(int tableId) {
    final tablesState = ref.read(tablesProvider);
    final table = tablesState.tables?.firstWhere(
      (table) => table.id == tableId,
      orElse: () =>
          CoffeTable(id: tableId, tableTitle: 'Masa #$tableId', area: ''),
    );
    return table?.tableTitle ?? 'Masa #$tableId';
  }

  // Açılış ve kapanış arasındaki süreyi hesapla
  String getDurationText(DateTime openedAt, DateTime closedAt) {
    final duration = closedAt.difference(openedAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return minutes > 0 ? '$hours sa $minutes dk' : '$hours saat';
    } else {
      return '$minutes dakika';
    }
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // Başlangıçta günlük veriye göre filtrele
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);

    Future.microtask(() {
      if (mounted) {
        ref.read(pastBillsProvider.notifier).fetchPastBills(
              startDate: startDate,
              endDate: now,
            );
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onPeriodChanged(String? value) {
    if (value != null && value != selectedPeriod) {
      setState(() {
        selectedPeriod = value;
      });

      // Periyoda göre tarih aralığını ayarla
      final now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate;

      switch (value) {
        case 'Günlük':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = now;
          break;
        case 'Haftalık':
          startDate = now.subtract(const Duration(days: 7));
          endDate = now;
          break;
        case 'Aylık':
          startDate = DateTime(now.year, now.month, 1);
          endDate = now;
          break;
      }

      if (mounted && startDate != null && endDate != null) {
        ref.read(pastBillsProvider.notifier).fetchPastBills(
              startDate: startDate,
              endDate: endDate,
              forceRefresh: true,
            );
      }
    }
  }

  // Arama filtresini uygula
  List<Map<String, dynamic>> _getFilteredBills(List<Map<String, dynamic>> pastBills) {
    var filteredList = [...pastBills];

    // Tarihe göre sırala (en yeniden eskiye)
    filteredList.sort((a, b) {
      final aClosedAt = DateTime.parse(a['rawData']['closedAt'] ?? '');
      final bClosedAt = DateTime.parse(b['rawData']['closedAt'] ?? '');
      return bClosedAt.compareTo(aClosedAt); // Yeniden eskiye sıralama için b'den a'yı çıkar
    });

    if (searchQuery.isEmpty) {
      return filteredList;
    }

    final query = searchQuery.toLowerCase();
    return filteredList.where((bill) {
      final closedBill = bill['rawData'] ?? {};
      final tableId = closedBill['tableId']?.toString() ?? '';
      final tableTitle = getTableName(int.tryParse(tableId) ?? 0).toLowerCase();
      final totalAmount = closedBill['totalAmount']?.toString() ?? '';

      return tableTitle.contains(query) ||
          totalAmount.contains(query);
    }).toList();
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 100,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 200,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pastBillsState = ref.watch(pastBillsProvider);
    final tablesState = ref.watch(tablesProvider);
    final isLoading = pastBillsState.isLoading;
    final pastBills = pastBillsState.pastBills ?? [];
    final filteredBills = _getFilteredBills(pastBills);
    final startDate = pastBillsState.startDate ??
        DateTime.now().subtract(const Duration(days: 7));
    final endDate = pastBillsState.endDate ?? DateTime.now();
    final selectedBillDetails = pastBillsState.selectedBillDetails;

    return Scaffold(
      backgroundColor: ColorConstants.appbackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Geçmiş Adisyonlar',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[100]!),
                      ),
                      child: Text(
                        '${filteredBills.length} Adisyon',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search and filter row
                Row(
                  children: [
                    // Arama alanı
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Icon(Icons.search, size: 18, color: Colors.grey[400]),
                            ),
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  height: 1,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Masa adı veya toplam tutara göre ara...',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    height: 1,
                                    color: Colors.grey[400],
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value;
                                  });
                                },
                              ),
                            ),
                            if (searchQuery.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                                onPressed: () {
                                  setState(() {
                                    searchQuery = '';
                                    searchController.clear();
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                splashRadius: 16,
                              ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Periyot seçimi
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: selectedPeriod,
                            underline: const SizedBox(),
                            items: ['Günlük', 'Haftalık', 'Aylık']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: _onPeriodChanged,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Yenile butonu
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: isLoading
                            ? null
                            : () {
                                ref
                                    .read(pastBillsProvider.notifier)
                                    .fetchPastBills(
                                      startDate: startDate,
                                      endDate: endDate,
                                      forceRefresh: true,
                                    );
                              },
                        icon: AnimatedRotation(
                          duration: const Duration(milliseconds: 1000),
                          turns: isLoading ? 1 : 0,
                          child: Icon(Icons.refresh,
                              size: 18, color: Colors.grey[600]),
                        ),
                        tooltip: 'Yenile',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tarih aralığı göstergesi
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.date_range,
                          size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('dd.MM.yyyy').format(startDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Adisyon listesi
                Expanded(
                  child: isLoading
                      ? _buildShimmerLoading()
                      : selectedBillDetails != null
                          ? _buildBillDetailsView(selectedBillDetails)
                          : filteredBills.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Geçmiş adisyon bulunamadı',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredBills.length,
                                  itemBuilder: (context, index) {
                                    final bill = filteredBills[index];
                                    final closedBill = bill['rawData'] ?? {};
                                    final pastBillItems = bill['pastBillItems']
                                            as List<dynamic>? ??
                                        [];

                                    final tableId =
                                        closedBill['tableId']?.toString() ??
                                            'N/A';
                                    final totalAmount =
                                        (closedBill['totalAmount'] ?? 0)
                                            .toString();
                                    final cashTotal =
                                        (closedBill['cashTotal'] ?? 0)
                                            .toString();
                                    final creditCardTotal =
                                        (closedBill['creditCardTotal'] ?? 0)
                                            .toString();
                                    final openedAt = closedBill['openedAt'] !=
                                            null
                                        ? DateTime.parse(closedBill['openedAt'])
                                        : null;
                                    final closedAt = closedBill['closedAt'] !=
                                            null
                                        ? DateTime.parse(closedBill['closedAt'])
                                        : null;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          onTap: () {
                                            ref
                                                .read(
                                                    pastBillsProvider.notifier)
                                                .selectBill(bill);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .orange[50],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                            border: Border.all(
                                                                color: Colors
                                                                        .orange[
                                                                    100]!),
                                                          ),
                                                          child: Text(
                                                            getTableName(
                                                                int.parse(
                                                                    tableId)),
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: Colors
                                                                  .orange[700],
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          '#${closedBill['id']}',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      '₺$totalAmount',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Colors.orange[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.access_time,
                                                            size: 14,
                                                            color: Colors.grey[500]),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Hesap Açılış: ',
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            color: Colors.grey[500],
                                                          ),
                                                        ),
                                                        Text(
                                                          DateFormat('HH:mm').format(openedAt!),
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                            color: Colors.grey[700],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Icon(Icons.event_available,
                                                            size: 14,
                                                            color: Colors.grey[500]),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Hesap Kapanış: ',
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            color: Colors.grey[500],
                                                          ),
                                                        ),
                                                        Text(
                                                          DateFormat('HH:mm').format(closedAt!),
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                            color: Colors.grey[700],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Icon(Icons.timer_outlined,
                                                            size: 14,
                                                            color: Colors.grey[500]),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Açık Kalma Süresi: ',
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            color: Colors.grey[500],
                                                          ),
                                                        ),
                                                        Text(
                                                          getDurationText(openedAt, closedAt),
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                            color: Colors.grey[700],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          'Nakit: ₺$cashTotal',
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          'K.Kartı: ₺$creditCardTotal',
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey[100],
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            '${pastBillItems.length} Ürün',
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 11,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillDetailsView(Map<String, dynamic> billDetails) {
    final closedBill = billDetails['data']['closedBill'] ?? {};
    final pastBillItems =
        billDetails['data']['pastBillItems'] as List<dynamic>? ?? [];

    final openedAt = closedBill['openedAt'] != null
        ? DateFormat('dd.MM.yyyy HH:mm')
            .format(DateTime.parse(closedBill['openedAt']))
        : '-';
    final closedAt = closedBill['closedAt'] != null
        ? DateFormat('dd.MM.yyyy HH:mm')
            .format(DateTime.parse(closedBill['closedAt']))
        : '-';
    final tableId = closedBill['tableId']?.toString() ?? 'N/A';
    final totalAmount = (closedBill['totalAmount'] ?? 0).toDouble();
    final cashTotal = (closedBill['cashTotal'] ?? 0).toDouble();
    final creditCardTotal = (closedBill['creditCardTotal'] ?? 0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Üst bilgiler
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange[100]!),
                        ),
                        child: Text(
                          getTableName(int.parse(tableId)),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#${closedBill['id']}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      ref.read(pastBillsProvider.notifier).resetSelectedBill();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _infoItem(
                    Icons.access_time,
                    'Açılış',
                    openedAt,
                  ),
                  const SizedBox(width: 24),
                  _infoItem(
                    Icons.event_available,
                    'Kapanış',
                    closedAt,
                  ),
                  const SizedBox(width: 24),
                  _infoItem(
                    Icons.timer_outlined,
                    'Süre',
                    getDurationText(
                      DateTime.parse(closedBill['openedAt']),
                      DateTime.parse(closedBill['closedAt']),
                    ),
                  ),
                  const SizedBox(width: 24),
                  _infoItem(
                    Icons.receipt,
                    'Toplam',
                    '${totalAmount.toStringAsFixed(2)} ₺',
                    valueColor: Colors.orange[700],
                  ),
                  const SizedBox(width: 24),
                  _infoItem(
                    Icons.payments_outlined,
                    'Nakit',
                    '${cashTotal.toStringAsFixed(2)} ₺',
                  ),
                  const SizedBox(width: 24),
                  _infoItem(
                    Icons.credit_card,
                    'K. Kartı',
                    '${creditCardTotal.toStringAsFixed(2)} ₺',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Adisyon Detayları',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        // Detay tablosu
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                // Tablo başlığı
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _tableHeader('Ürün')),
                      Expanded(flex: 1, child: _tableHeader('Kategori')),
                      Expanded(flex: 1, child: _tableHeader('Adet')),
                      Expanded(flex: 1, child: _tableHeader('Tutar')),
                      Expanded(flex: 1, child: _tableHeader('Ödeme')),
                      Expanded(flex: 1, child: _tableHeader('Durum')),
                    ],
                  ),
                ),
                // Tablo içeriği
                Expanded(
                  child: pastBillItems.isEmpty
                      ? Center(
                          child: Text(
                            'Adisyon detayı bulunamadı',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: pastBillItems.length,
                          itemBuilder: (context, index) {
                            final item = pastBillItems[index];
                            final piece = item['piece'] ?? 1;
                            final price = (item['price'] ?? 0).toDouble();
                            final isCredit = item['isCredit'] ?? false;

                            return Container(
                              decoration: BoxDecoration(
                                color: index % 2 == 0
                                    ? Colors.white
                                    : Colors.grey[50],
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[100]!),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                        flex: 3,
                                        child: _tableCell(item['title'] ??
                                            'Bilinmeyen Ürün')),
                                    Expanded(
                                        flex: 1,
                                        child: _tableCell(
                                            item['category'] ?? '-')),
                                    Expanded(
                                        flex: 1, child: _tableCell('$piece')),
                                    Expanded(
                                        flex: 1,
                                        child: _tableCell(
                                          '${price.toStringAsFixed(2)} ₺',
                                          fontWeight: FontWeight.w500,
                                        )),
                                    Expanded(
                                        flex: 1,
                                        child: _tableCell(
                                          isCredit ? 'K.Kartı' : 'Nakit',
                                          color: Colors.orange[700],
                                        )),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(item['status'])
                                              ?.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item['status'] ?? '-',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color:
                                                _getStatusColor(item['status']),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoItem(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _tableCell(String text, {FontWeight? fontWeight, Color? color}) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: color ?? Colors.grey[800],
        fontWeight: fontWeight ?? FontWeight.normal,
      ),
    );
  }

  Color? _getStatusColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status.toLowerCase()) {
      case 'ödendi':
        return Colors.orange[700];
      case 'beklemede':
        return Colors.orange;
      case 'iptal':
        return Colors.red;
      case 'hazırlanıyor':
        return Colors.orange;
      default:
        return Colors.grey[700];
    }
  }
}

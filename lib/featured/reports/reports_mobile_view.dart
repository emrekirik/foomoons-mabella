import 'package:foomoons/featured/providers/reports_notifier.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/product/widget/analysys_card_mobile.dart';
import 'package:foomoons/product/widget/chart_mobile_section.dart';
import 'package:foomoons/product/widget/person_mobile_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/services/settings_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class ReportsMobileView extends ConsumerStatefulWidget {
  const ReportsMobileView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ReportsMobileViewState();
}

class _ReportsMobileViewState extends ConsumerState<ReportsMobileView> {
  String selectPeriod = 'Günlük';
  int? _businessId;

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
    Future.microtask(() {
      if (mounted) {
        ref.read(reportsProvider.notifier).fetchAndLoad(selectPeriod);
      }
    });
  }

  Future<void> _loadBusinessId() async {
    final authService = ref.read(authServiceProvider);
    final businessId = await authService.getBusinessId();
    if (mounted) {
      setState(() {
        _businessId = businessId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();
    
    final reportsState = ref.watch(reportsProvider);
    final employees = reportsState.employees;
    final sizeWidth = MediaQuery.of(context).size.width;
    final dailyStats = reportsState.dailyStats;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16), 
              color: Colors.white
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Zaman ayarları ve periyot seçici
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '06:00 - 05:59',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  height: 28,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectPeriod,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey.shade700,
                                        size: 16,
                                      ),
                                      isDense: true,
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade800,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            selectPeriod = newValue;
                                          });
                                          ref.read(reportsProvider.notifier).fetchAndLoad(newValue);
                                        }
                                      },
                                      items: <String>['Aylık', 'Haftalık', 'Günlük']
                                          .map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getPeriodRangeText(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  gridAnalysisCard(reportsState, sizeWidth, employees, constraints, dailyStats),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getPeriodRangeText() {
    switch (selectPeriod) {
      case 'Aylık':
        return '(01 - 30/31)';
      case 'Haftalık':
        return 'Son 7 Gün';
      case 'Günlük':
        return '(Bugün)';
      default:
        return '';
    }
  }

  Column gridAnalysisCard(
      ReportsState reportsState,
      double sizeWidth,
      List<Map<String, dynamic>> employees,
      BoxConstraints constraints,
      Map<String, DailyStats> dailyStats) {
    return Column(
      children: [
        if (_businessId != 14) ...[
          // İlk satır: Toplam Hasılat ve Toplam Sipariş yan yana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: AnalysysCardMobile(
                  cardTitle: 'Toplam Hasılat',
                  assetImage: 'assets/images/dolar_icon.png',
                  cardSubtitle: selectPeriod,
                  subTitleIcon: const Icon(Icons.graphic_eq),
                  cardPiece: '${reportsState.totalRevenues}₺',
                  businessId: _businessId,
                ),
              ),
              SizedBox(width: sizeWidth * 0.015),
              Expanded(
                child: AnalysysCardMobile(
                  assetImage: 'assets/images/order_icon.png',
                  cardSubtitle: selectPeriod,
                  cardPiece: reportsState.totalOrder.toString(),
                  cardTitle: 'Toplam Sipariş',
                  subTitleIcon: const Icon(Icons.graphic_eq),
                  businessId: _businessId,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // İkinci satır: Nakit ve Kredi yan yana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: AnalysysCardMobile(
                  assetImage: 'assets/images/cash.png',
                  cardSubtitle: selectPeriod,
                  cardPiece: '${reportsState.totalCash}₺',
                  cardTitle: 'Nakit Ödeme',
                  subTitleIcon: const Icon(Icons.graphic_eq),
                  businessId: _businessId,
                ),
              ),
              SizedBox(width: sizeWidth * 0.015),
              Expanded(
                child: AnalysysCardMobile(
                  assetImage: 'assets/images/credit.png',
                  cardSubtitle: selectPeriod,
                  cardPiece: '${reportsState.totalCredit}₺',
                  cardTitle: 'Kredi ile Ödeme',
                  subTitleIcon: const Icon(Icons.graphic_eq),
                  businessId: _businessId,
                ),
              ),
            ],
          ),
        ] else ...[
          // Giriş bilgisi olan işletme için orijinal düzen
          // Toplam Hasılat kartı en üstte
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: AnalysysCardMobile(
                  cardTitle: 'Toplam Hasılat',
                  assetImage: 'assets/images/dolar_icon.png',
                  cardSubtitle: selectPeriod,
                  subTitleIcon: const Icon(Icons.graphic_eq),
                  cardPiece: '${reportsState.totalRevenues}₺',
                  businessId: _businessId,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: AnalysysCardMobile(
                  assetImage: 'assets/images/cash.png',
                  cardSubtitle: selectPeriod,
                  cardPiece: '${reportsState.totalCash}₺',
                  cardTitle: 'Nakit Ödeme',
                  subTitleIcon: const Icon(Icons.graphic_eq),
                  businessId: _businessId,
                ),
              ),
              SizedBox(width: sizeWidth * 0.015),
              Expanded(
                child: AnalysysCardMobile(
                  assetImage: 'assets/images/credit.png',
                  cardSubtitle: selectPeriod,
                  cardPiece: '${reportsState.totalCredit}₺',
                  cardTitle: 'Kredi ile Ödeme',
                  subTitleIcon: const Icon(Icons.graphic_eq),
                  businessId: _businessId,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: AnalysysCardMobile(
                  assetImage: 'assets/images/order_icon.png',
                  cardSubtitle: selectPeriod,
                  cardPiece: reportsState.totalOrder.toString(),
                  cardTitle: 'Toplam Sipariş',
                  subTitleIcon: const Icon(Icons.graphic_eq),
                  businessId: _businessId,
                ),
              ),
              SizedBox(width: sizeWidth * 0.015),
              Expanded(
                child: AnalysysCardMobile(
                  assetImage: 'assets/images/order_icon.png',
                  cardSubtitle: selectPeriod,
                  cardPiece: reportsState.totalEntry.toString(),
                  cardTitle: 'Giriş',
                  subTitleIcon: const Icon(Icons.graphic_eq),
                  businessId: _businessId,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChartMobileSection(
              selectedPeriod: selectPeriod,
              onPeriodChanged: (newPeriod) {
                setState(() {
                  selectPeriod = newPeriod;
                });
                ref.read(reportsProvider.notifier).fetchAndLoad(newPeriod);
              },
              dailyStats: dailyStats,
            ),
            const SizedBox(height: 20),
            PersonMobileSection(
              employees: employees,
              constraints: constraints,
            ),
          ],
        )
      ],
    );
  }
}

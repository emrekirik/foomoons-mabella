import 'package:foomoons/featured/providers/reports_notifier.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/product/widget/analysis_card.dart';
import 'package:foomoons/product/widget/chart_section.dart';
import 'package:foomoons/product/widget/person_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/services/settings_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class ReportsView extends ConsumerStatefulWidget {
  const ReportsView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<ReportsView> {
  String selectedPeriod = 'Günlük';
  int? _businessId;
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchData();
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

  void _fetchData() {
    if (!mounted) return;
    ref.read(reportsProvider.notifier).fetchAndLoad(selectedPeriod);
  }

  Widget _buildTimeSettings(bool isSmallScreen) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    size: isSmallScreen ? 16 : 18,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gün Aralığı: 06:00 - 05:59',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: isSmallScreen ? 16 : 18,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Periyot:',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                        value: selectedPeriod,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade700,
                          size: isSmallScreen ? 16 : 18,
                        ),
                        isDense: true,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade800,
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedPeriod = newValue;
                            });
                            _fetchData();
                          }
                        },
                        items: ['Aylık', 'Haftalık', 'Günlük']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getPeriodRangeText(),
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 11 : 12,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();
    
    final reportsState = ref.watch(reportsProvider);
    final employees = reportsState.employees;
    final sizeWidth = MediaQuery.of(context).size.width;
    final dailyStats = reportsState.dailyStats;
    final isSmallScreen = sizeWidth < 1200;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _buildTimeSettings(isSmallScreen),
              const SizedBox(height: 12),
              Expanded(
                child: isSmallScreen
                    ? gridAnalysisCard(reportsState, sizeWidth, employees,
                        constraints, dailyStats)
                    : reportsContent(
                        reportsState, sizeWidth, constraints, dailyStats),
              ),
            ],
          ),
        );
      },
    );
  }

  Column gridAnalysisCard(
      ReportsState reportsState,
      double sizeWidth,
      List<Map<String, dynamic>> employees,
      BoxConstraints constraints,
      Map<String, DailyStats> dailyStats) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AnalysisCard(
                assetImage: 'assets/images/cash.png',
                cardSubtitle: selectedPeriod,
                cardPiece: '${reportsState.totalCash}₺',
                cardTitle: 'Nakit Ödeme',
                subTitleIcon: const Icon(Icons.graphic_eq),
              ),
              SizedBox(
                width: sizeWidth * 0.015,
              ),
              AnalysisCard(
                  cardTitle: 'Toplam Hasılat',
                  assetImage: 'assets/images/dolar_icon.png',
                  cardSubtitle: selectedPeriod,
                  subTitleIcon: const Icon(Icons.graphic_eq),
                  cardPiece: reportsState.totalRevenues.toString()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AnalysisCard(
                  assetImage: 'assets/images/order_icon.png',
                  cardSubtitle: selectedPeriod,
                  cardPiece: reportsState.totalOrder.toString(),
                  cardTitle: 'Toplam Sipariş',
                  subTitleIcon: const Icon(Icons.graphic_eq),
                ),
                if (_businessId == 14) ...[
                  SizedBox(
                    width: sizeWidth * 0.015,
                  ),
                  AnalysisCard(
                    assetImage: 'assets/images/order_icon.png',
                    cardSubtitle: selectedPeriod,
                    cardPiece: reportsState.totalEntry.toString(),
                    cardTitle: 'Giriş',
                    subTitleIcon: const Icon(Icons.graphic_eq),
                  ),
                ],
                SizedBox(
                  width: sizeWidth * 0.015,
                ),
                AnalysisCard(
                  assetImage: 'assets/images/credit.png',
                  cardSubtitle: selectedPeriod,
                  cardPiece: '${reportsState.totalCredit}₺',
                  cardTitle: 'Kredi ile Ödeme',
                  subTitleIcon: const Icon(Icons.graphic_eq),
                ),
              ],
            )),
        const SizedBox(height: 12),
        Expanded(
          flex: 4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              PersonSection(
                constraints: constraints,
              ),
              const SizedBox(
                width: 20,
              ),
              ChartSection(
                selectedPeriod: selectedPeriod,
                onPeriodChanged: (newPeriod) {
                  setState(() {
                    selectedPeriod = newPeriod;
                  });
                  ref.read(reportsProvider.notifier).fetchAndLoad(newPeriod);
                },
                dailyStats: dailyStats,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Column reportsContent(ReportsState reportsState, double sizeWidth,
      BoxConstraints constraints, Map<String, DailyStats> dailyStats) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AnalysisCard(
                assetImage: 'assets/images/order_icon.png',
                cardSubtitle: selectedPeriod,
                cardPiece: reportsState.totalOrder.toString(),
                cardTitle: 'Sipariş',
                subTitleIcon: const Icon(Icons.graphic_eq),
              ),
              if (_businessId == 14) ...[
                SizedBox(
                  width: sizeWidth * 0.015,
                ),
                AnalysisCard(
                  assetImage: 'assets/images/order_icon.png',
                  cardSubtitle: selectedPeriod,
                  cardPiece: reportsState.totalEntry.toString(),
                  cardTitle: 'Giriş',
                  subTitleIcon: const Icon(Icons.graphic_eq),
                ),
              ],
              SizedBox(
                width: sizeWidth * 0.015,
              ),
              AnalysisCard(
                assetImage: 'assets/images/credit.png',
                cardSubtitle: selectedPeriod,
                cardPiece: '${reportsState.totalCredit}₺',
                cardTitle: 'Kredi ile Ödeme',
                subTitleIcon: const Icon(Icons.graphic_eq),
              ),
              SizedBox(
                width: sizeWidth * 0.015,
              ),
              AnalysisCard(
                assetImage: 'assets/images/cash.png',
                cardSubtitle: selectedPeriod,
                cardPiece: '${reportsState.totalCash}₺',
                cardTitle: 'Nakit Ödeme',
                subTitleIcon: const Icon(Icons.graphic_eq),
              ),
              SizedBox(
                width: sizeWidth * 0.015,
              ),
              AnalysisCard(
                  cardTitle: 'Toplam',
                  assetImage: 'assets/images/dolar_icon.png',
                  cardSubtitle: selectedPeriod,
                  subTitleIcon: const Icon(Icons.graphic_eq),
                  cardPiece: '${reportsState.totalRevenues}₺'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: 4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              PersonSection(
                constraints: constraints,
              ),
              const SizedBox(
                width: 20,
              ),
              ChartSection(
                selectedPeriod: selectedPeriod,
                onPeriodChanged: (newPeriod) {
                  setState(() {
                    selectedPeriod = newPeriod;
                  });
                  ref.read(reportsProvider.notifier).fetchAndLoad(newPeriod);
                },
                dailyStats: dailyStats,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPeriodRangeText() {
    switch (selectedPeriod) {
      case 'Aylık':
        return '(01 - 30/31)';
      case 'Haftalık':
        return '(Pzt - Paz)';
      case 'Günlük':
        return '(Bugün)';
      default:
        return '';
    }
  }
}

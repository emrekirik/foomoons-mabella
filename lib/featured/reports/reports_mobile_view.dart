import 'package:foomoons/featured/providers/reports_notifier.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/product/widget/analysys_card_mobile.dart';
import 'package:foomoons/product/widget/chart_mobile_section.dart';
import 'package:foomoons/product/widget/person_mobile_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/services/settings_service.dart';

class ReportsMobileView extends ConsumerStatefulWidget {
  const ReportsMobileView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ReportsMobileViewState();
}

class _ReportsMobileViewState extends ConsumerState<ReportsMobileView> {
  String selectPeriod = 'Günlük';
  final SettingsService _settingsService = SettingsService();
  String? dayStartTime;
  String? dayEndTime;
  int? _businessId;

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
    _loadTimeSettings();
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

  Future<void> _loadTimeSettings() async {
    final startTime = await _settingsService.getDayStartTime();
    final endTime = await _settingsService.getDayEndTime();
    if (mounted) {
      setState(() {
        dayStartTime = startTime;
        dayEndTime = endTime;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime 
          ? TimeOfDay.fromDateTime(DateTime.parse('2024-01-01 ${dayStartTime ?? "00:00"}:00'))
          : TimeOfDay.fromDateTime(DateTime.parse('2024-01-01 ${dayEndTime ?? "23:59"}:00')),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: Colors.grey[200],
              hourMinuteTextColor: Colors.black,
              dialHandColor: Colors.orange,
              dialBackgroundColor: Colors.grey[200],
              dialTextColor: Colors.black,
              entryModeIconColor: Colors.black,
              dayPeriodTextColor: Colors.black,
              helpTextStyle: const TextStyle(color: Colors.black),
              dayPeriodBorderSide: const BorderSide(color: Colors.black),
              dayPeriodColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
              onBackground: Colors.black,
              onSecondary: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
            ),
          ),
          child: child!,
        );
      },
      cancelText: "İPTAL",
      confirmText: "TAMAM",
      hourLabelText: "Saat",
      minuteLabelText: "Dakika",
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isStartTime) {
        await _settingsService.setDayStartTime(timeString);
        setState(() => dayStartTime = timeString);
      } else {
        await _settingsService.setDayEndTime(timeString);
        setState(() => dayEndTime = timeString);
      }
      ref.read(reportsProvider.notifier).fetchAndLoad(selectPeriod);
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
                  const SizedBox(height: 20),
                  // Zaman ayarları ve periyot seçici
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Zaman ayarları
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _selectTime(context, true),
                            icon: const Icon(Icons.access_time, size: 16, color: Colors.black),
                            label: Text(
                              dayStartTime ?? 'Başlangıç',
                              style: const TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ),
                          const Text('-', style: TextStyle(fontSize: 12, color: Colors.black)),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _selectTime(context, false),
                            icon: const Icon(Icons.access_time, size: 16, color: Colors.black),
                            label: Text(
                              dayEndTime ?? 'Bitiş',
                              style: const TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Periyot seçici
                      Container(
                        width: 120,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: Colors.grey.shade100,
                            value: selectPeriod,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.blue,
                              size: 20,
                            ),
                            isDense: true,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
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
                    ],
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

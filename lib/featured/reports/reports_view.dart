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
  String? dayStartTime;
  String? dayEndTime;

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
    _loadTimeSettings();
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
    TimeOfDay currentTime;
    bool isNextDay = false;

    if (isStartTime) {
      if (dayStartTime != null) {
        final parts = dayStartTime!.split(' ');
        currentTime = TimeOfDay.fromDateTime(
          DateTime.parse('2024-01-01 ${parts[0]}:00')
        );
        isNextDay = parts.length > 1 && parts[1] == '(+1)';
      } else {
        currentTime = const TimeOfDay(hour: 0, minute: 0);
      }
    } else {
      if (dayEndTime != null) {
        final parts = dayEndTime!.split(' ');
        currentTime = TimeOfDay.fromDateTime(
          DateTime.parse('2024-01-01 ${parts[0]}:00')
        );
        isNextDay = parts.length > 1 && parts[1] == '(+1)';
      } else {
        currentTime = const TimeOfDay(hour: 23, minute: 59);
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
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
            colorScheme: ColorScheme.light(
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
      bool? shouldBeNextDay = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Gün Seçimi',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Bu saat hangi güne ait?',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Aynı Gün',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(
                  'Ertesi Gün',
                  style: GoogleFonts.poppins(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (shouldBeNextDay != null) {
        final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}${shouldBeNextDay ? ' (+1)' : ''}';
        if (isStartTime) {
          await _settingsService.setDayStartTime(timeString);
          setState(() => dayStartTime = timeString);
        } else {
          await _settingsService.setDayEndTime(timeString);
          setState(() => dayEndTime = timeString);
        }
        _fetchData();
      }
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
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _buildTimeSection(isSmallScreen),
                VerticalDivider(
                  color: Colors.grey.shade300,
                  width: 24,
                  thickness: 1,
                  indent: 4,
                  endIndent: 4,
                ),
                _buildPeriodSection(isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSection(bool isSmallScreen) {
    return Expanded(
      flex: 3,
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: isSmallScreen ? 16 : 18,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            'Zaman:',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 12 : 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildTimeButton(context, true, isSmallScreen),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.arrow_forward,
                    size: isSmallScreen ? 14 : 16,
                    color: Colors.grey.shade400,
                  ),
                ),
                _buildTimeButton(context, false, isSmallScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSection(bool isSmallScreen) {
    return Expanded(
      flex: 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
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
        ],
      ),
    );
  }

  Widget _buildTimeButton(BuildContext context, bool isStartTime, bool isSmallScreen) {
    String timeText = '';
    Color timeColor = Colors.grey.shade800;
    
    if (isStartTime) {
      if (dayStartTime != null) {
        final parts = dayStartTime!.split(' ');
        timeText = parts[0];
        if (parts.length > 1) {
          timeColor = Colors.orange.shade700;
        }
      } else {
        timeText = '00:00';
      }
    } else {
      if (dayEndTime != null) {
        final parts = dayEndTime!.split(' ');
        timeText = parts[0];
        if (parts.length > 1) {
          timeColor = Colors.orange.shade700;
        }
      } else {
        timeText = '23:59';
      }
    }

    return InkWell(
      onTap: () => _selectTime(context, isStartTime),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timeText,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 11 : 12,
                color: timeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if ((isStartTime && dayStartTime?.contains('(+1)') == true) ||
                (!isStartTime && dayEndTime?.contains('(+1)') == true)) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_forward,
                size: isSmallScreen ? 10 : 12,
                color: Colors.orange.shade700,
              ),
            ],
          ],
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
}

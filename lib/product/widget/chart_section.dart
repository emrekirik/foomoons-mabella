import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:foomoons/featured/providers/reports_notifier.dart';
import 'package:foomoons/product/services/settings_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ChartSection extends StatefulWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;
  final Map<String, DailyStats> dailyStats;
  const ChartSection(
      {required this.dailyStats,
      required this.onPeriodChanged,
      required this.selectedPeriod,
      super.key});

  @override
  State<ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<ChartSection> {
  late String dropdownValue;
  int touchedIndex = -1;
  final SettingsService _settingsService = SettingsService();
  String? dayStartTime;
  String? dayEndTime;
  late DateTime currentStartDate;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.selectedPeriod;
    _loadTimeSettings();
    _initializeWeekStart();
  }

  void _initializeWeekStart() {
    // Bugünün tarihini al
    final now = DateTime.now();
    // Bu haftanın pazartesi gününü bul (1 = Pazartesi, 7 = Pazar)
    final daysUntilMonday = (now.weekday - 1) % 7;
    currentStartDate = now.subtract(Duration(days: daysUntilMonday));
  }

  Future<void> _loadTimeSettings() async {
    final startTime = await _settingsService.getDayStartTime();
    final endTime = await _settingsService.getDayEndTime();
    setState(() {
      dayStartTime = startTime;
      dayEndTime = endTime;
    });
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
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isStartTime) {
        await _settingsService.setDayStartTime(timeString);
        setState(() => dayStartTime = timeString);
      } else {
        await _settingsService.setDayEndTime(timeString);
        setState(() => dayEndTime = timeString);
      }
      widget.onPeriodChanged(widget.selectedPeriod);
    }
  }

  void _navigateWeek(bool isNext) {
    setState(() {
      if (isNext) {
        final nextWeekStart = currentStartDate.add(const Duration(days: 7));
        if (nextWeekStart.isBefore(DateTime.now().add(const Duration(days: 1)))) {
          currentStartDate = nextWeekStart;
        }
      } else {
        final previousWeekStart = currentStartDate.subtract(const Duration(days: 7));
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        // Önceki haftaya geçiş için 30 günlük sınır kontrolü
        if (previousWeekStart.isAfter(thirtyDaysAgo.subtract(const Duration(days: 7)))) {
          currentStartDate = previousWeekStart;
        }
      }
    });
  }

  Map<String, DailyStats> _getCurrentWeekStats() {
    Map<String, DailyStats> weekStats = {};
    
    // Pazartesiden başlayarak 7 günü oluştur
    for (int i = 0; i < 7; i++) {
      final date = currentStartDate.add(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      // Eğer bu tarih için veri varsa onu kullan, yoksa 0 değerlerle oluştur
      weekStats[dateStr] = widget.dailyStats[dateStr] ?? DailyStats(
        totalRevenue: 0,
        creditTotal: 0,
        cashTotal: 0,
        orderCount: 0,
        entryCount: 0,
        date: date,
      );
    }
    
    return weekStats;
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final currentWeekStats = _getCurrentWeekStats();
    final bool isSmallScreen = deviceWidth < 900;
    
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Sol taraf - Başlık ve zaman seçiciler
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Hasılat',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTimeButton(context, true, isSmallScreen),
                          Text(
                            '-',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.black,
                            ),
                          ),
                          _buildTimeButton(context, false, isSmallScreen),
                        ],
                      ),
                    ],
                  ),
                  // Sağ taraf - Navigasyon ve istatistikler
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildWeekNavigation(isSmallScreen),
                      _buildTotalRevenue(currentWeekStats, isSmallScreen),
                      _buildPeriodDropdown(isSmallScreen),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: currentWeekStats.values.isNotEmpty
                        ? currentWeekStats.values
                                .map((stats) => stats.totalRevenue)
                                .reduce((a, b) => a > b ? a : b) *
                            1.2
                        : 100,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final date = currentWeekStats.keys.elementAt(groupIndex);
                          final stats = currentWeekStats[date]!;
                          return BarTooltipItem(
                            '$date\n',
                            GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: '${stats.totalRevenue}₺',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              barTouchResponse == null ||
                              barTouchResponse.spot == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex =
                              barTouchResponse.spot!.touchedBarGroupIndex;
                        });
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final days = ["Pzt", "Sal", "Çrş", "Prş", "Cum", "Cmt", "Paz"];
                            return Text(
                              days[value.toInt()],
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                          reservedSize: 20,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              value.toInt().toString(),
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    barGroups: List.generate(
                      7, // Sabit 7 gün
                      (index) {
                        final dayStats = currentWeekStats.entries
                            .where((entry) => DateTime.parse(entry.key).weekday == index + 1)
                            .firstOrNull;
                            
                        final double revenue = dayStats?.value.totalRevenue.toDouble() ?? 0;
                        
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: revenue,
                              color: touchedIndex == index
                                  ? Colors.orange.shade700
                                  : Colors.orange.shade400,
                              width: 24,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(BuildContext context, bool isStartTime, bool isSmallScreen) {
    return TextButton.icon(
      onPressed: () => _selectTime(context, isStartTime),
      icon: Icon(Icons.access_time, size: isSmallScreen ? 16 : 18, color: Colors.black),
      label: Text(
        isStartTime ? (dayStartTime ?? 'Başlangıç') : (dayEndTime ?? 'Bitiş'),
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 11 : 12,
          color: Colors.black,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildWeekNavigation(bool isSmallScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios, size: isSmallScreen ? 14 : 16),
          onPressed: () => _navigateWeek(false),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ),
        Text(
          '${currentStartDate.day}/${currentStartDate.month} - ${currentStartDate.add(const Duration(days: 6)).day}/${currentStartDate.add(const Duration(days: 6)).month}',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 12 : 13,
            color: Colors.black,
          ),
        ),
        IconButton(
          icon: Icon(Icons.arrow_forward_ios, size: isSmallScreen ? 14 : 16),
          onPressed: () => _navigateWeek(true),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildTotalRevenue(Map<String, DailyStats> currentWeekStats, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: isSmallScreen ? 4 : 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_outlined,
            size: isSmallScreen ? 14 : 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            '${currentWeekStats.values.fold(0, (sum, stats) => sum + stats.totalRevenue)}₺',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodDropdown(bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? 90 : 100,
      height: isSmallScreen ? 28 : 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(7),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Colors.grey.shade100,
          value: dropdownValue,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.blue,
            size: isSmallScreen ? 16 : 18,
          ),
          iconSize: isSmallScreen ? 16 : 18,
          elevation: 16,
          isDense: true,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: isSmallScreen ? 12 : 13,
          ),
          onChanged: (String? newValue) {
            setState(() {
              dropdownValue = newValue!;
            });
            widget.onPeriodChanged(newValue!);
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
    );
  }
}

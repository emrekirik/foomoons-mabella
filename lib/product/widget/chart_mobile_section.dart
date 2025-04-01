import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:foomoons/featured/providers/reports_notifier.dart';
import 'package:foomoons/product/services/settings_service.dart';

class ChartMobileSection extends StatefulWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;
  final Map<String, DailyStats> dailyStats;

  const ChartMobileSection({
    required this.dailyStats,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    super.key,
  });

  @override
  State<ChartMobileSection> createState() => _ChartMobileSectionState();
}

class _ChartMobileSectionState extends State<ChartMobileSection> {
  int touchedIndex = -1;
  late DateTime currentStartDate;
  final SettingsService _settingsService = SettingsService();
  String? dayStartTime;
  String? dayEndTime;

  @override
  void initState() {
    super.initState();
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

  void _navigateWeek(bool isNext) {
    setState(() {
      if (isNext) {
        final nextWeekStart = currentStartDate.add(const Duration(days: 7));
        if (nextWeekStart
            .isBefore(DateTime.now().add(const Duration(days: 1)))) {
          currentStartDate = nextWeekStart;
        }
      } else {
        final previousWeekStart =
            currentStartDate.subtract(const Duration(days: 7));
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        // Önceki haftaya geçiş için 30 günlük sınır kontrolü
        if (previousWeekStart
            .isAfter(thirtyDaysAgo.subtract(const Duration(days: 7)))) {
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
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      // Eğer bu tarih için veri varsa onu kullan, yoksa 0 değerlerle oluştur
      weekStats[dateStr] = widget.dailyStats[dateStr] ??
          DailyStats(
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

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return "Pzt";
      case 2:
        return "Sal";
      case 3:
        return "Çrş";
      case 4:
        return "Prş";
      case 5:
        return "Cum";
      case 6:
        return "Cmt";
      case 7:
        return "Paz";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWeekStats = _getCurrentWeekStats();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time picker ve navigasyon butonları
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed: () => _navigateWeek(false),
            ),
            Text(
              '${currentStartDate.day}/${currentStartDate.month} - ${currentStartDate.add(const Duration(days: 6)).day}/${currentStartDate.add(const Duration(days: 6)).month}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () => _navigateWeek(true),
            ),
            const SizedBox(width: 16),
            // Haftanın toplam hasılatı
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on_outlined,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${currentWeekStats.values.fold(0, (sum, stats) => sum + stats.totalRevenue)}₺',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Grafik
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
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
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        children: [
                          TextSpan(
                            text: 'Toplam: ${stats.totalRevenue}₺\n',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: 'Kredi: ${stats.creditTotal}₺\n',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'Nakit: ${stats.cashTotal}₺',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
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
                        final days = [
                          "Pzt",
                          "Sal",
                          "Çrş",
                          "Prş",
                          "Cum",
                          "Cmt",
                          "Paz"
                        ];
                        return Text(days[value.toInt()]);
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        final num = value.toInt();
                        if (num >= 1000) {
                          return Text('${(num / 1000).toStringAsFixed(1)}k');
                        }
                        return Text(num.toString());
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
                    final date = currentStartDate.add(Duration(days: index));
                    final dateStr =
                        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                    final stats = currentWeekStats[dateStr];

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: stats?.totalRevenue.toDouble() ?? 0,
                          color: touchedIndex == index
                              ? Colors.redAccent
                              : Colors.blue,
                          width: 32,
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
    );
  }
}

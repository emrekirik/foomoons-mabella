import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:foomoons/featured/providers/reports_notifier.dart';
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
  int touchedIndex = -1;
  late DateTime currentStartDate;

  @override
  void initState() {
    super.initState();
    _initializeWeekStart();
  }

  void _initializeWeekStart() {
    final now = DateTime.now();
    final daysUntilMonday = (now.weekday - 1) % 7;
    currentStartDate = now.subtract(Duration(days: daysUntilMonday));
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
        if (previousWeekStart.isAfter(thirtyDaysAgo.subtract(const Duration(days: 7)))) {
          currentStartDate = previousWeekStart;
        }
      }
    });
  }

  Map<String, DailyStats> _getCurrentWeekStats() {
    Map<String, DailyStats> weekStats = {};
    
    for (int i = 0; i < 7; i++) {
      final date = currentStartDate.add(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    children: [
                      _buildWeekNavigation(isSmallScreen),
                      const SizedBox(width: 12),
                      _buildTotalRevenue(currentWeekStats, isSmallScreen),
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
                      7,
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
}

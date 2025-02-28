import 'package:foomoons/featured/providers/reports_notifier.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/product/widget/analysis_card.dart';
import 'package:foomoons/product/widget/chart_section.dart';
import 'package:foomoons/product/widget/person_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsView extends ConsumerStatefulWidget {
  const ReportsView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<ReportsView> {
  String selectedPeriod = 'Günlük';
  int? _businessId;

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: sizeWidth < 1200
                ? gridAnalysisCard(reportsState, sizeWidth, employees,
                    constraints, dailyStats)
                : reportsContent(
                    reportsState, sizeWidth, constraints, dailyStats));
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

import 'package:foomoons/featured/bill/bill_mobile_view.dart';
import 'package:foomoons/featured/bill/bill_view.dart';
import 'package:foomoons/featured/responsive/responsive_layout.dart';
import 'package:foomoons/featured/tables/dialogs/add_area_bottomsheet.dart';
import 'package:foomoons/featured/tables/dialogs/add_table_bottomsheet.dart';
import 'package:foomoons/product/constants/color_constants.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/product/enums/table_sort_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// MenuView Widget
class TablesMobileView extends ConsumerStatefulWidget {
  final String? successMessage;
  final bool isSelfService;
  const TablesMobileView({this.successMessage, required this.isSelfService, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TablesMobileViewState();
}

class _TablesMobileViewState extends ConsumerState<TablesMobileView> {
  late bool allItemsPaid;
  late double remainingAmount;
  final Set<int> processedTables = {};
  bool isRefreshing = false;
  TableSortType currentSortType = TableSortType.defaultSort;
  static const String _sortPreferenceKey = 'table_sort_preference';

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
    _fetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchData();
    // Tüm masaların verilerini yeniden çek
    processedTables.clear(); // İşlenmiş masaları temizle
  }

  Future<void> _loadSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSort = prefs.getString(_sortPreferenceKey);
    if (savedSort != null) {
      setState(() {
        currentSortType = TableSortType.values.firstWhere(
          (type) => type.toString() == savedSort,
          orElse: () => TableSortType.defaultSort,
        );
      });
    }
  }

  Future<void> _saveSortPreference(TableSortType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortPreferenceKey, type.toString());
  }

  void _fetchData() {
    Future.microtask(() async {
      if (mounted) {
        final tablesState = ref.read(tablesProvider);
        
        // Veriler null ise fetch yap
        if (tablesState.tables == null || tablesState.areas == null) {
          await ref.read(tablesProvider.notifier).fetchAndLoad();
        }
        
        // Bölge seçimini kontrol et
        if (mounted) {
          final currentState = ref.read(tablesProvider);
          if (currentState.areas != null && 
              currentState.areas!.isNotEmpty && 
              currentState.selectedValue == null) {
            ref.read(tablesProvider.notifier).selectArea(currentState.areas!.first.title);
          }
        }
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      isRefreshing = true;
    });
    await ref.read(tablesProvider.notifier).fetchAndLoad();
    
    // Tüm masaların adisyon bilgilerini yenile
    final tables = ref.read(tablesProvider).tables ?? [];
    for (final table in tables) {
      if (table.id != null) {
        await ref.read(tablesProvider.notifier).fetchTableBillApi(table.id!);
      }
    }
    
    processedTables.clear(); // İşlenmiş masaları temizle
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      isRefreshing = false;
    });
  }

  void fetchTableOnce(int tableId) {
    if (!processedTables.contains(tableId)) {
      processedTables.add(tableId);
      ref.read(tablesProvider.notifier).fetchTableBillApi(tableId);
    }
  }

  List<dynamic> _sortTables(List<dynamic> tables) {
    switch (currentSortType) {
      case TableSortType.tableNumber:
        return tables..sort((a, b) {
          final aTitle = a.tableTitle ?? '';
          final bTitle = b.tableTitle ?? '';
          
          // Farklı formatlardaki sayısal kısımları ayıkla
          final regexPatterns = [
            RegExp(r'C(\d+)$'),           // C1, C2 formatı için
            RegExp(r'A-(\d+)$'),          // A-1, A-2 formatı için
            RegExp(r'(\d+)$'),            // Sadece sayı olan format için
          ];
          
          int? getNumber(String title) {
            for (final pattern in regexPatterns) {
              final match = pattern.firstMatch(title);
              if (match != null) {
                return int.parse(match.group(1)!);
              }
            }
            return null;
          }
          
          final aNum = getNumber(aTitle);
          final bNum = getNumber(bTitle);
          
          if (aNum != null && bNum != null) {
            // Her iki masada da sayısal kısım varsa, sayısal olarak karşılaştır
            return aNum.compareTo(bNum);
          }
          
          // Sayısal kısım yoksa veya karşılaştırılamıyorsa alfabetik sırala
          return aTitle.compareTo(bTitle);
        });
      case TableSortType.totalAmount:
        return tables..sort((a, b) {
          final aBill = ref.read(tablesProvider.select((state) => state.getTableBill(a.id)))
              .where((item) => item.isAmount != true)
              .toList();
          final bBill = ref.read(tablesProvider.select((state) => state.getTableBill(b.id)))
              .where((item) => item.isAmount != true)
              .toList();
          
          final aTotal = aBill.fold(0.0, (sum, item) => sum + ((item.price ?? 0) * (item.piece ?? 1)));
          final bTotal = bBill.fold(0.0, (sum, item) => sum + ((item.price ?? 0) * (item.piece ?? 1)));
          
          return bTotal.compareTo(aTotal); // En yüksek tutardan en düşüğe
        });
      case TableSortType.defaultSort:
      default:
        return tables;
    }
  }

  @override
  Widget build(BuildContext context) {
    // final authState = ref.watch(authStateProvider);
    final isLoading = ref.watch(loadingProvider).isLoading('tables');
    final tablesNotifier = ref.read(tablesProvider.notifier);
    final productItem = ref.watch(menuProvider).products ?? [];
    final tables = ref.watch(tablesProvider).tables ?? [];
    final areas = ref.watch(tablesProvider).areas ?? [];
    final selectedArea = ref.watch(tablesProvider).selectedValue;

    final filteredTables = _sortTables(tables.where((item) {
      final isAreaMatch = item.area?.trim().toLowerCase() == selectedArea?.trim().toLowerCase();
      return isAreaMatch;
    }).toList());

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final area = areas[index];
                          return Container(
                            width: 120,
                            decoration: BoxDecoration(
                              border: Border(
                                left: const BorderSide(
                                    color: Colors.black12, width: 1),
                                bottom: BorderSide(
                                  color: selectedArea == area.title
                                      ? Colors.orange
                                      : Colors
                                          .transparent, // Seçili kategori altına çizgi ekle
                                  width: 5, // Çizginin kalınlığı
                                ),
                              ),
                            ),
                            child: Material(
                              color: ColorConstants.white,
                              child: InkWell(
                                splashColor:
                                    Colors.orange.withOpacity(0.6),
                                onTap: () {
                                  tablesNotifier.selectArea(area.title);
                                },
                                child: Center(
                                  child: Text(
                                    area.title ?? '',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        itemCount: areas.length),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: AnimatedRotation(
                        duration: const Duration(milliseconds: 1000),
                        turns: isRefreshing ? 1 : 0,
                        child: Icon(Icons.refresh, size: 20, color: Colors.grey[600]),
                      ),
                      onPressed: isRefreshing ? null : _refreshData,
                    ),
                    PopupMenuButton<TableSortType>(
                      onSelected: (TableSortType value) {
                        setState(() {
                          currentSortType = value;
                        });
                        _saveSortPreference(value);
                      },
                      itemBuilder: (BuildContext context) {
                        return TableSortType.values.map((type) {
                          String title;
                          switch (type) {
                            case TableSortType.tableNumber:
                              title = 'Masa Numarası';
                              break;
                            case TableSortType.totalAmount:
                              title = 'Toplam Tutar';
                              break;
                            case TableSortType.defaultSort:
                              title = 'Varsayılan';
                              break;
                          }
                          return PopupMenuItem<TableSortType>(
                            value: type,
                            child: Text(title),
                          );
                        }).toList();
                      },
                      icon: const Icon(Icons.sort),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        switch (value) {
                          case 'Masa Ekle':
                            addTableBottomSheet(
                                context, tablesNotifier, selectedArea!);
                            break;
                          case 'Bölge Ekle':
                            addAreaBottomSheet(context, tablesNotifier);
                            break;
                          default:
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem<String>(
                            value: 'Masa Ekle',
                            child: Text('Masa Ekle'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'Bölge Ekle',
                            child: Text('Bölge Ekle'),
                          ),
                        ];
                      },
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
              ],
            ),
            // Masaların Listesi
            if (isLoading == false)
              Expanded(
                child: Container(
                  color: ColorConstants.tablePageBackgroundColor,
                  child: GridView.builder(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (constraints.maxWidth / 130).floor(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: filteredTables.length,
                    itemBuilder: (BuildContext context, int index) {
                      final tableId = filteredTables[index].id;
                      // Fetch table bill only once
                      if (tableId != null) {
                        fetchTableOnce(tableId);
                      }
                      final tableBill = ref
                          .watch(tablesProvider.select(
                              (state) => state.getTableBill(tableId!)))
                          .where((item) =>
                              item.isAmount !=
                              true) // `isAmount == true` olanlar filtrelenir
                          .toList();
                      final totalAmount = tableBill.fold(
                          0.0,
                          (sum, item) =>
                              sum + ((item.price ?? 0) * (item.piece ?? 1)));
                      calculateAmount(tableBill, totalAmount, tableId!);
                      final odenenToplamTutar = totalAmount - remainingAmount;
                      return InkWell(
                        onTap: () async {
                          final tableId = filteredTables[index].id;
                          final tableQrUrl = filteredTables[index].qrUrl;
                          if (tableId != null) {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ResponsiveLayout(
                                    desktopBody: BillView(
                                      isSelfService: widget.isSelfService,
                                      qrUrl: tableQrUrl,
                                      tableId: tableId,
                                      tableTitle: filteredTables[index].tableTitle ?? '',
                                    ),
                                    mobileBody: BillMobileView(
                                      tableTitle:
                                          filteredTables[index].tableTitle ??
                                              '',
                                      tableId: tableId,
                                      orderItems: productItem,
                                      qrUrl: tableQrUrl,
                                    ))));
                          }
                        },
                        child: Container(
                          decoration: tableBill.isNotEmpty
                              ? BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(12)),
                                  color: (allItemsPaid &&
                                          tableBill.isNotEmpty)
                                      ? ColorConstants.tableItemPaymentColor
                                      : // Adisyon boş değil ve tüm öğeler ödendi mi?
                                      ColorConstants.tableItemColor,
                      /*             boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                      offset: const Offset(0, 3),
                                    ),
                                  ], */
                                )
                              : BoxDecoration(
                                color: Colors.white,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(12)),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                       /*            boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                      offset: const Offset(0, 3),
                                    ),
                                  ], */
                                ),
                          child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: tableBill.isNotEmpty
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Text(
                                          '${filteredTables[index].tableTitle}',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                          ),
                                        ),
                                        Center(
                                          child: odenenToplamTutar != 0
                                              ? Text(
                                                  '₺$totalAmount / ₺$odenenToplamTutar',
                                                  style: TextStyle(
                                                    decoration: (allItemsPaid &&
                                                            tableBill
                                                                .isNotEmpty)
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : TextDecoration.none,
                                                    fontSize: 20.0,
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                )
                                              : Text(
                                                  '₺$totalAmount',
                                                  style: TextStyle(
                                                    decoration: (allItemsPaid &&
                                                            tableBill
                                                                .isNotEmpty)
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : TextDecoration.none,
                                                    fontSize: 20.0,
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${filteredTables[index].tableTitle}',
                                          style: const TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    )),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void calculateAmount(List<Menu> tableBill, double totalAmount, int tableId) {
    final tableBillAmount = _getTableBillAmount(tableId);
    final negativeAmount = _calculateTotal(tableBillAmount);

    final urunBazliOdenenler =
        tableBill.where((item) => item.status == 'ödendi').toList();
    final urunBazliOdenenToplam = _calculateTotal(urunBazliOdenenler);

    allItemsPaid = _checkIfAllItemsPaid(
      tableBill,
      negativeAmount,
      urunBazliOdenenToplam,
      totalAmount,
    );

    remainingAmount = _calculateRemainingAmount(
      totalAmount,
      negativeAmount,
      urunBazliOdenenToplam,
    );
  }

  List<Menu> _getTableBillAmount(int tableId) {
    return ref
        .watch(tablesProvider.select((state) => state.getTableBill(tableId)))
        .where((item) => item.isAmount == true)
        .toList();
  }

  double _calculateTotal(List<Menu> items) {
    return items.fold(
        0.0, (sum, item) => sum + ((item.price ?? 0) * (item.piece ?? 1)));
  }

  bool _checkIfAllItemsPaid(List<Menu> tableBill, double negativeAmount,
      double urunBazliOdenenToplam, double totalAmount) {
    return tableBill.every((item) => item.status == 'ödendi') ||
        (negativeAmount != 0 && negativeAmount == totalAmount) ||
        urunBazliOdenenToplam + negativeAmount == totalAmount;
  }

  double _calculateRemainingAmount(
      double totalAmount, double negativeAmount, double urunBazliOdenenToplam) {
    return totalAmount - negativeAmount - urunBazliOdenenToplam;
  }
}

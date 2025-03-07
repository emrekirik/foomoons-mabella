import 'package:foomoons/featured/bill/bill_mobile_view.dart';
import 'package:foomoons/featured/bill/bill_view.dart';
import 'package:foomoons/featured/responsive/responsive_layout.dart';
import 'package:foomoons/featured/tables/dialogs/add_area_dialog.dart';
import 'package:foomoons/featured/tables/dialogs/add_table_dialog.dart';
import 'package:foomoons/product/constants/color_constants.dart';
import 'package:foomoons/product/model/area.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:foomoons/featured/providers/tables_notifier.dart';

/// Menu Provider

/// MenuView Widget
class TablesView extends ConsumerStatefulWidget {
  final String? successMessage;
  final bool isSelfService;
  const TablesView(
      {this.successMessage, required this.isSelfService, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TablesViewState();
}

class _TablesViewState extends ConsumerState<TablesView>
    with SingleTickerProviderStateMixin {
  late bool allItemsPaid;
  late double remainingAmount;
  final Set<int> processedTables = {};
  bool isRefreshing = false;
  bool isEditMode = false;
  late AnimationController _rotationController;
  int? draggedTableId;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fetchData();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchData();
    processedTables.clear(); // İşlenmiş masaları temizle
  }

  Future<void> _fetchData() async {
    await Future.microtask(() async {
      if (mounted) {
        final tablesState = ref.read(tablesProvider);
        if (tablesState.tables == null || tablesState.areas == null) {
          await ref.read(tablesProvider.notifier).fetchAndLoad().then((_) {
            if (mounted) {
              final areas = ref.read(tablesProvider).areas;
              if (areas != null && areas.isNotEmpty) {
                ref.read(tablesProvider.notifier).selectArea(areas.first.title);
              }
            }
          });
        } else if (tablesState.areas != null &&
            tablesState.areas!.isNotEmpty &&
            tablesState.selectedValue == null) {
          ref
              .read(tablesProvider.notifier)
              .selectArea(tablesState.areas!.first.title);
        }
      }
    });
  }

  Future<bool> _showDeleteConfirmationDialog(
      BuildContext context, String tableTitle) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Masa Silme',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context, false),
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '$tableTitle masasını silmek istediğinizden emin misiniz?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'İptal',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'Sil',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  void fetchTableOnce(int tableId) {
    if (!processedTables.contains(tableId)) {
      processedTables.add(tableId);
      ref.read(tablesProvider.notifier).fetchTableBillApi(tableId);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isRefreshing = true;
    });
    _rotationController.repeat();

    final tables = ref.read(tablesProvider).tables ?? [];
    for (final table in tables) {
      if (table.id != null) {
        await ref.read(tablesProvider.notifier).fetchTableBillApi(table.id!);
      }
    }

    processedTables.clear();
    await Future.delayed(const Duration(milliseconds: 300));

    _rotationController.stop();
    setState(() {
      isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider).isLoading('tables');
    final tablesNotifier = ref.read(tablesProvider.notifier);
    final productItem = ref.watch(menuProvider).products ?? [];
    final tables = ref.watch(tablesProvider).tables ?? [];
    final areas = ref.watch(tablesProvider).areas ?? [];
    final selectedArea = ref.watch(tablesProvider).selectedValue;

    final filteredTables = tables.where((item) {
      final isAreaMatch =
          item.area?.trim().toLowerCase() == selectedArea?.trim().toLowerCase();
      return isAreaMatch;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            decoration: BoxDecoration(
              color: ColorConstants.tablePageBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.black12, width: 1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                final area = areas[index];
                                return Container(
                                  width: 140,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: const BorderSide(
                                          color: Colors.black12, width: 1),
                                      bottom: BorderSide(
                                        color: selectedArea == area.title
                                            ? Colors.orange
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Material(
                                    color: ColorConstants.white,
                                    child: Stack(
                                      children: [
                                        InkWell(
                                          splashColor:
                                              Colors.orange.withOpacity(0.6),
                                          onTap: () {
                                            tablesNotifier.selectArea(area.title);
                                          },
                                          child: Center(
                                            child: Text(
                                              area.title ?? '',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ),
                                        if (isEditMode)
                                          Positioned(
                                            right: 4,
                                            top: 4,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: IconButton(
                                                padding: const EdgeInsets.all(4),
                                                constraints: const BoxConstraints(),
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                  color: Colors.orange,
                                                ),
                                                onPressed: () {
                                                  _showEditAreaDialog(context, area, tablesNotifier);
                                                },
                                                tooltip: 'Bölge Adını Düzenle',
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              itemCount: areas.length),
                        ),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: isEditMode ? Colors.orange.withOpacity(0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  isEditMode ? Icons.close : Icons.edit,
                                  size: 20,
                                  color: isEditMode ? Colors.orange : Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    isEditMode = !isEditMode;
                                  });
                                },
                                tooltip: isEditMode ? 'Düzenleme Modunu Kapat' : 'Düzenleme Modunu Aç',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: isRefreshing ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                                icon: RotationTransition(
                                  turns: _rotationController,
                                  child: Icon(
                                    Icons.refresh,
                                    size: 20,
                                    color: isRefreshing ? Colors.blue : Colors.grey[600],
                                  ),
                                ),
                                onPressed: isRefreshing ? null : _refreshData,
                                tooltip: 'Yenile',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: PopupMenuButton<String>(
                                padding: const EdgeInsets.all(8),
                                tooltip: 'Daha Fazla',
                                onSelected: (String value) {
                                  switch (value) {
                                    case 'Masa Ekle':
                                      addTableDialog(
                                          context, tablesNotifier, selectedArea!);
                                      break;
                                    case 'Bölge Ekle':
                                      addAreaDialog(context, tablesNotifier);
                                      break;
                                    default:
                                      break;
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  return [
                                    PopupMenuItem<String>(
                                      value: 'Masa Ekle',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.add_box_outlined, size: 20),
                                          const SizedBox(width: 8),
                                          Text('Masa Ekle',
                                              style: GoogleFonts.poppins()),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'Bölge Ekle',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.add_location_alt_outlined, size: 20),
                                          const SizedBox(width: 8),
                                          Text('Bölge Ekle',
                                              style: GoogleFonts.poppins()),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
                                icon: const Icon(Icons.more_vert, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Masaların Listesi
                if (isLoading == false)
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: (constraints.maxWidth / 140).floor(),
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
                            .where((item) => item.isAmount != true)
                            .toList();
                        final totalAmount = tableBill.fold(
                            0.0,
                            (sum, item) =>
                                sum + ((item.price ?? 0) * (item.piece ?? 1)));
                        calculateAmount(tableBill, totalAmount, tableId!);
                        final odenenToplamTutar = totalAmount - remainingAmount;

                        Widget tableWidget = Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: tableBill.isNotEmpty
                                  ? BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(12)),
                                      color: (allItemsPaid &&
                                              tableBill.isNotEmpty)
                                          ? ColorConstants.tableItemPaymentColor
                                          : ColorConstants.tableItemColor,
                                      border: isEditMode
                                          ? Border.all(
                                              color: Colors.orange,
                                              width: 2,
                                            )
                                          : null,
                                      boxShadow: null,
                                    )
                                  : BoxDecoration(
                                      color: ColorConstants.white,
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(12)),
                                      border: isEditMode
                                          ? Border.all(
                                              color: Colors.orange,
                                              width: 2,
                                            )
                                          : null,
                                      boxShadow: null,
                                      image: const DecorationImage(
                                        image: AssetImage(
                                            "assets/images/table_icon.png"),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                              child: Stack(
                                children: [
                                  if (isEditMode)
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Icon(
                                        Icons.drag_indicator,
                                        size: 20,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: tableBill.isNotEmpty
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const SizedBox(height: 8),
                                              Text(
                                                '${filteredTables[index].tableTitle}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: odenenToplamTutar != 0
                                                      ? Text(
                                                          '₺$totalAmount / ₺$odenenToplamTutar',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            decoration: (allItemsPaid &&
                                                                    tableBill
                                                                        .isNotEmpty)
                                                                ? TextDecoration
                                                                    .lineThrough
                                                                : TextDecoration
                                                                    .none,
                                                            fontSize: 16.0,
                                                            color: Colors.black,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        )
                                                      : Text(
                                                          '₺$totalAmount',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            decoration: (allItemsPaid &&
                                                                    tableBill
                                                                        .isNotEmpty)
                                                                ? TextDecoration
                                                                    .lineThrough
                                                                : TextDecoration
                                                                    .none,
                                                            fontSize: 16.0,
                                                            color: Colors.black,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Center(
                                                child: Text(
                                                  '${filteredTables[index].tableTitle}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 18.0,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            if (isEditMode)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.black54),
                                  onSelected: (String value) async {
                                    switch (value) {
                                      case 'Sil':
                                        final tableId =
                                            filteredTables[index].id;
                                        final tableTitle =
                                            filteredTables[index].tableTitle;
                                        if (tableId != null) {
                                          final shouldDelete =
                                              await _showDeleteConfirmationDialog(
                                                  context,
                                                  tableTitle ?? 'Seçili masa');

                                          if (shouldDelete) {
                                            final result = await ref
                                                .read(tablesProvider.notifier)
                                                .deleteTable(tableId);
                                            if (result) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Masa başarıyla silindi',
                                                    style:
                                                        GoogleFonts.poppins(),
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                              await _fetchData();
                                            } else {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Masa silinirken bir hata oluştu',
                                                    style:
                                                        GoogleFonts.poppins(),
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                        break;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    PopupMenuItem<String>(
                                      value: 'Sil',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.delete, size: 20),
                                          const SizedBox(width: 8),
                                          Text('Sil',
                                              style: GoogleFonts.poppins()),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );

                        return isEditMode
                            ? DragTarget<int>(
                                onWillAccept: (data) => data != tableId,
                                onAccept: (draggedId) async {
                                  final draggedTable = filteredTables
                                      .firstWhere((t) => t.id == draggedId);
                                  final targetTable = filteredTables[index];

                                  // Onay dialogu göster
                                  final shouldMerge = await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Container(
                                              width: 400,
                                              padding: const EdgeInsets.all(32),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Masaları Birleştir',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 24,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.black,
                                                          letterSpacing: -0.5,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                        icon: Icon(
                                                          Icons.close,
                                                          color:
                                                              Colors.grey[400],
                                                          size: 24,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 24),
                                                  Text(
                                                    '${draggedTable.tableTitle} masasını ${targetTable.tableTitle} masası ile birleştirmek istediğinizden emin misiniz?',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 32),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                        child: Text(
                                                          'İptal',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 16,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.orange,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 24,
                                                            vertical: 12,
                                                          ),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                        child: Text(
                                                          'Birleştir',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 16,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ) ??
                                      false;

                                  if (shouldMerge) {
                                    try {
                                      // Yükleme animasyonunu göster
                                      if (!context.mounted) return;
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => Center(
                                          child: LoadingAnimationWidget.flickr(
                                            leftDotColor:
                                                const Color(0xFFFF8A00),
                                            rightDotColor:
                                                const Color(0xFF00B761),
                                            size: 45,
                                          ),
                                        ),
                                      );

                                      // Adisyonları birleştir
                                      final result = await ref
                                          .read(tablesProvider.notifier)
                                          .mergeTables(
                                            sourceTableId: draggedId,
                                            targetTableId: tableId,
                                          );

                                      // Yükleme animasyonunu kapat
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop();

                                      if (result) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Masalar başarıyla birleştirildi',
                                              style: GoogleFonts.poppins(),
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        await _fetchData(); // Verileri yenile
                                      } else {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Masalar birleştirilirken bir hata oluştu',
                                              style: GoogleFonts.poppins(),
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // Hata durumunda yükleme animasyonunu kapat
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop();

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Masalar birleştirilirken bir hata oluştu: $e',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                builder:
                                    (context, candidateData, rejectedData) {
                                  return Draggable<int>(
                                    data: tableId,
                                    feedback: Material(
                                      elevation: 4.0,
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        child: tableWidget,
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.5,
                                      child: tableWidget,
                                    ),
                                    child: Tooltip(
                                      message:
                                          'Masaları birleştirmek için sürükleyip bırakın',
                                      child: tableWidget,
                                    ),
                                  );
                                },
                              )
                            : InkWell(
                                onTap: () async {
                                  final tableTitle =
                                      filteredTables[index].tableTitle;
                                  final tableQrUrl =
                                      filteredTables[index].qrUrl;
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => ResponsiveLayout(
                                          desktopBody: BillView(
                                            tableId: tableId,
                                            tableTitle: tableTitle!,
                                            qrUrl: tableQrUrl,
                                            isSelfService: widget.isSelfService,
                                          ),
                                          mobileBody: BillMobileView(
                                            tableId: tableId,
                                            tableTitle: tableTitle,
                                            orderItems: productItem,
                                            qrUrl: tableQrUrl,
                                          ))));
                                },
                                child: tableWidget,
                              );
                      },
                    ),
                  ),
              ],
            ),
          ),
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
        0, (sum, item) => sum + ((item.price ?? 0) * (item.piece ?? 1)));
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

  Future<void> _showEditAreaDialog(BuildContext context, Area area, TablesNotifier tablesNotifier) async {
    final TextEditingController areaController = TextEditingController(text: area.title);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bölge Düzenle',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: areaController,
                  decoration: InputDecoration(
                    hintText: 'Bölge ismini girin',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[200]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[200]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.orange,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Delete button
                    IconButton(
                      onPressed: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                'Bölgeyi Sil',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              content: Text(
                                'Bu bölgeyi silmek istediğinize emin misiniz? Bu işlem geri alınamaz ve bölgedeki tüm masalar silinecektir.',
                                style: GoogleFonts.poppins(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text(
                                    'İptal',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: Text(
                                    'Sil',
                                    style: GoogleFonts.poppins(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (shouldDelete == true) {
                          // Show loading dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Center(
                              child: LoadingAnimationWidget.flickr(
                                leftDotColor: const Color(0xFFFF8A00),
                                rightDotColor: const Color(0xFF00B761),
                                size: 45,
                              ),
                            ),
                          );

                          try {
                            final result = await tablesNotifier.deleteArea(area.id!);
                            
                            // Close loading dialog
                            Navigator.of(context).pop();
                            
                            if (result) {
                              Navigator.of(context).pop(); // Close edit dialog
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Bölge başarıyla silindi',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              await _fetchData(); // Verileri yenile
                            } else {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Bölge silinirken bir hata oluştu',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            // Close loading dialog
                            Navigator.of(context).pop();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Bölge silinirken bir hata oluştu: $e',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red[400],
                        size: 24,
                      ),
                      tooltip: 'Bölgeyi Sil',
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'İptal',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final newAreaName = areaController.text.trim();
                            if (newAreaName.isNotEmpty && newAreaName != area.title) {
                              try {
                                // Yükleme animasyonunu göster
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => Center(
                                    child: LoadingAnimationWidget.flickr(
                                      leftDotColor: const Color(0xFFFF8A00),
                                      rightDotColor: const Color(0xFF00B761),
                                      size: 45,
                                    ),
                                  ),
                                );

                                final result = await tablesNotifier.updateArea(
                                  area: area,
                                  newAreaName: newAreaName,
                                );

                                // Yükleme animasyonunu kapat
                                Navigator.of(context).pop();

                                if (result) {
                                  Navigator.of(context).pop(); // Close edit dialog
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Bölge adı başarıyla güncellendi',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Bölge adı güncellenirken bir hata oluştu',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                // Yükleme animasyonunu kapat
                                Navigator.of(context).pop();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Bölge adı güncellenirken bir hata oluştu: $e',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(
                            'Kaydet',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
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
        );
      },
    );
  }
}

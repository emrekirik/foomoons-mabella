import 'package:foomoons/featured/bill/payment_showdialog.dart';
import 'package:foomoons/featured/providers/menu_notifier.dart';
import 'package:foomoons/product/constants/color_constants.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/product/widget/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:foomoons/product/services/payment_service.dart';
import 'package:foomoons/product/services/printer_service.dart';
import 'package:google_fonts/google_fonts.dart';

class BillView extends ConsumerStatefulWidget {
  final int tableId;
  final String tableTitle;
  final String? qrUrl;
  final bool isSelfService;
  const BillView({
    required this.tableId,
    required this.tableTitle,
    this.qrUrl,
    required this.isSelfService,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BillViewState();
}

class _BillViewState extends ConsumerState<BillView>
    with TickerProviderStateMixin {
  bool isClosing = false;
  late TextEditingController searchContoller;
  String searchQuery = '';
  late bool allItemsPaid;
  late double remainingAmount;
  Map<String, dynamic>? userDetails;
  // Seçilen öğeleri tutacak set
  final Set<int> selectedItems = {};
  bool isMultiSelectMode = false;

  final Map<String, AnimationController> _animationControllers = {};
  bool _isPrinting = false;
  // Set to track newly added items for animation
  final Set<int> _newlyAddedItems = {};

  // Öğe seçim durumunu değiştiren metod
  void toggleItemSelection(int itemId) {
    setState(() {
      if (selectedItems.contains(itemId)) {
        selectedItems.remove(itemId);
        if (selectedItems.isEmpty) {
          isMultiSelectMode = false;
        }
      } else {
        selectedItems.add(itemId);
        isMultiSelectMode = true;
      }
    });
  }

  // Tüm seçimleri temizleyen metod
  void clearSelection() {
    setState(() {
      selectedItems.clear();
      isMultiSelectMode = false;
    });
  }

  @override
  void initState() {
    super.initState();
    searchContoller = TextEditingController();
    Future.microtask(
      () async {
        if (mounted) {
          await ref
              .read(tablesProvider.notifier)
              .fetchTableBillApi(widget.tableId);
        }

        // Menu ürünlerini sadece boşsa veya cache süresi dolduysa çek
        if (mounted) {
          final menuState = ref.read(menuProvider);
          if (menuState.products == null || menuState.categories == null) {
            await ref.read(menuProvider.notifier).fetchAndLoad().then(
              (_) {
                if (mounted) {
                  // İlk kategori seçimini yapıyoruz
                  final categories = ref.read(menuProvider).categories;
                  if (categories != null && categories.isNotEmpty) {
                    ref
                        .read(menuProvider.notifier)
                        .selectCategory(categories.first.title);
                  }
                }
              },
            );
          } else if (menuState.selectedValue == null &&
              menuState.categories != null &&
              menuState.categories!.isNotEmpty) {
            // Sadece kategori seçili değilse, ilk kategoriyi seç
            ref
                .read(menuProvider.notifier)
                .selectCategory(menuState.categories!.first.title);
          }
        }
      },
    );
    
    // Listen for changes in the bill to track newly added items
    ref.listenManual(tablesProvider, (previous, next) {
      if (previous != null) {
        final prevItems = previous.getTableBill(widget.tableId);
        final currItems = next.getTableBill(widget.tableId);
        
        if (currItems.length > prevItems.length) {
          // Find newly added items
          for (final item in currItems) {
            if (!prevItems.any((prevItem) => prevItem.id == item.id) && 
                item.id != null && 
                item.isAmount != true) {
              setState(() {
                _newlyAddedItems.add(item.id!);
              });
              
              // Remove from newly added items after animation completes
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) {
                  setState(() {
                    _newlyAddedItems.remove(item.id);
                  });
                }
              });
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _animationControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
    searchContoller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider).isLoading('bill');
    final isLoadingAddItem = ref.watch(tablesProvider).isLoading;
    final tablesNotifier = ref.read(tablesProvider.notifier);
    final menuNotifier = ref.read(menuProvider.notifier);
    final productItem = ref.watch(menuProvider).products ?? [];
    final categories = ref.watch(menuProvider).categories ?? [];
    final selectedCategory = ref.watch(menuProvider).selectedValue;
    double deviceWidth = MediaQuery.of(context).size.width;
    final String userType = userDetails?['userType'] ?? '';
    // Filter items based on the search query, ignoring the selected category during search
    final filteredItems = productItem.where((item) {
      // If search query is not empty, ignore category and search across all products
      if (searchQuery.isNotEmpty) {
        return item.title!.toLowerCase().contains(searchQuery.toLowerCase());
      }

      // If search query is empty, filter based on the selected category
      final isCategoryMatch = selectedCategory == null ||
              selectedCategory == MenuNotifier.allCategories
          ? true
          : item.category == selectedCategory;
      return isCategoryMatch;
    }).toList();

    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        children: [
          Expanded(
            child: Scaffold(
              appBar: widget.isSelfService
                  ? null
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(70.0),
                      child: CustomAppbar(
                        userType: userType,
                        showDrawer: false,
                        showBackButton: true,
                      ),
                    ),
              backgroundColor: ColorConstants.appbackgroundColor,
              body: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12)),
                    color: ColorConstants.tablePageBackgroundColor,
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      // Sol taraf: Ürün listesi
                      Flexible(
                        flex: 2,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 6),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: TextField(
                                  controller: searchContoller,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Ürün ara...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 12.0, right: 6.0),
                                      child: Icon(
                                        Icons.search_rounded,
                                        color: Colors.grey.shade400,
                                        size: 20,
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                    suffixIcon: searchQuery.isNotEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.only(right: 6.0),
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.clear,
                                                color: Colors.grey.shade400,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                searchContoller.clear();
                                                setState(() {
                                                  searchQuery = '';
                                                });
                                              },
                                            ),
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.orange.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    isDense: true,
                                  ),
                                  onChanged: (query) {
                                    setState(() {
                                      searchQuery = query;
                                    });
                                  },
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: searchQuery.isNotEmpty
                                      ? const SizedBox()
                                      : Wrap(
                                          children: categories.map((category) {
                                            final isSelected =
                                                selectedCategory ==
                                                    category.title;
                                            double itemWidth =
                                                MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    10; // 4 sütun
                                            return Container(
                                              width: itemWidth,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.orange
                                                    : Colors.white,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? Colors.orange
                                                      : Colors.black12,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Material(
                                                color: isSelected
                                                    ? Colors.orange
                                                    : Colors.white,
                                                child: InkWell(
                                                  splashColor: Colors.orange
                                                      .withOpacity(0.6),
                                                  onTap: () {
                                                    menuNotifier.selectCategory(
                                                        category.title);
                                                  },
                                                  child: Center(
                                                    child: Text(
                                                      category.title ?? '',
                                                      style: TextStyle(
                                                          color: isSelected
                                                              ? Colors.white
                                                              : Colors.black,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Container(
                                color: ColorConstants.tablePageBackgroundColor,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: GridView.builder(
                                          itemCount: filteredItems.length,
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                (constraints.maxWidth / 240)
                                                    .floor(),
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                            childAspectRatio: 1.8,
                                          ),
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            final item = filteredItems[index];
                                            return isLoading
                                                ? const SizedBox()
                                                : Card(
                                                    color: Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      onTap: () {
                                                        tablesNotifier
                                                            .addItemToBillQueued(
                                                          item.copyWith(
                                                              tableId: widget
                                                                  .tableId),
                                                        );
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 12,
                                                                horizontal: 12),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    item.title ??
                                                                        '',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: 1,
                                                                  ),
                                                                ),
                                                                Consumer(
                                                                  builder:
                                                                      (context,
                                                                          ref,
                                                                          child) {
                                                                    final isPending = ref.watch(tablesProvider.select((state) =>
                                                                        state.pendingItems[
                                                                            '${item.id}_${widget.tableId}'] ??
                                                                        false));
                                                                    if (isPending) {
                                                                      return const SizedBox(
                                                                        width:
                                                                            16,
                                                                        height:
                                                                            16,
                                                                        child:
                                                                            CircularProgressIndicator(
                                                                          strokeWidth:
                                                                              2,
                                                                          valueColor:
                                                                              AlwaysStoppedAnimation<Color>(Colors.orange),
                                                                        ),
                                                                      );
                                                                    }
                                                                    return const SizedBox
                                                                        .shrink();
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                                height: 4),
                                                            Text(
                                                                '₺${item.price}',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade700,
                                                                )),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                          },
                                        ),
                                      ),
                                      widget.qrUrl != null
                                          ? SizedBox(
                                              child: QrImageView(
                                                data: widget.qrUrl!,
                                                version: QrVersions.auto,
                                                size: 100.0,
                                              ),
                                            )
                                          : const SizedBox(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      //Sağ taraf adisyon listesi
                      isLoadingAddItem == true
                          ? const Expanded(
                              child: Center(child: CircularProgressIndicator()))
                          : Expanded(
                              child: Consumer(
                                builder: (context, ref, child) {
                                  final tableBill = ref
                                      .watch(tablesProvider.select((state) =>
                                          state.getTableBill(widget.tableId)))
                                      .where((item) =>
                                          item.isAmount !=
                                          true) // `isAmount != true` olanlar filtrelenir
                                      .toList();
                                  final totalAmount = tableBill.fold(
                                      0.0,
                                      (sum, item) =>
                                          sum +
                                          ((item.price ?? 0) *
                                              (item.piece ?? 1)));
                                  calculateAmount(tableBill, totalAmount);
                                  return Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(12),
                                            bottomRight: Radius.circular(12)),
                                        boxShadow: [
                                          BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.4),
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                              offset: const Offset(-2, 0)),
                                        ],
                                        border: const Border(
                                            left: BorderSide(
                                                color: Colors.black12,
                                                width: 1))),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                widget.isSelfService
                                                    ? 'Hesap'
                                                    : widget.tableTitle,
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    if (isMultiSelectMode) {
                                                      clearSelection();
                                                    } else {
                                                      isMultiSelectMode = true;
                                                    }
                                                  });
                                                },
                                                icon: Icon(
                                                  isMultiSelectMode ? Icons.close : Icons.checklist_rounded,
                                                  color: isMultiSelectMode ? Colors.red : Colors.grey[700],
                                                ),
                                                tooltip: isMultiSelectMode ? 'Seçim Modunu Kapat' : 'Çoklu Seçim',
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: tableBill.length,
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              final item = tableBill[index];

                                              // Her öğe için benzersiz bir key oluştur
                                              final itemKey =
                                                  '${item.id}_${item.piece}';
                                                  
                                              // Check if this is a newly added item
                                              final isNewlyAdded = item.id != null && _newlyAddedItems.contains(item.id!);
                                              
                                              final Widget contentWidget = Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey.shade100),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                  child: Row(
                                                    children: [
                                                      // Checkbox (multiselect mode)
                                                      if (isMultiSelectMode)
                                                        Transform.scale(
                                                          scale: 0.9,
                                                          child: Checkbox(
                                                            value: selectedItems.contains(item.id),
                                                            onChanged: (bool? value) {
                                                              if (item.id != null) {
                                                                toggleItemSelection(item.id!);
                                                              }
                                                            },
                                                            activeColor: Colors.orange,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                          ),
                                                        ),
                                                      
                                                      // Main content
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            // Item title with status badge if paid
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    item.title ?? '',
                                                                    style: const TextStyle(
                                                                      fontSize: 14,
                                                                      fontWeight: FontWeight.w600,
                                                                    ),
                                                                    overflow: TextOverflow.ellipsis,
                                                                    maxLines: 1,
                                                                  ),
                                                                ),
                                                                if (item.status == 'ödendi')
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                    decoration: BoxDecoration(
                                                                      color: Colors.green.shade50,
                                                                      borderRadius: BorderRadius.circular(4),
                                                                      border: Border.all(color: Colors.green.shade100),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        Icon(
                                                                          Icons.check_circle,
                                                                          size: 10,
                                                                          color: Colors.green.shade700,
                                                                        ),
                                                                        const SizedBox(width: 3),
                                                                        Text(
                                                                          'Ödendi',
                                                                          style: TextStyle(
                                                                            fontSize: 10,
                                                                            fontWeight: FontWeight.w500,
                                                                            color: Colors.green.shade700,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                            
                                                            const SizedBox(height: 6),
                                                            
                                                            // Item details row
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                // Left side details (quantity and prep time)
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                      '${item.piece ?? 1} adet',
                                                                      style: TextStyle(
                                                                        fontSize: 12,
                                                                        color: Colors.grey.shade600,
                                                                      ),
                                                                    ),
                                                                    if (item.preparationTime != null) ...[
                                                                      const SizedBox(width: 8),
                                                                      Row(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          Icon(
                                                                            Icons.access_time,
                                                                            size: 12,
                                                                            color: Colors.grey.shade500,
                                                                          ),
                                                                          const SizedBox(width: 3),
                                                                          Text(
                                                                            _formatPreparationTime(item.preparationTime!),
                                                                            style: TextStyle(
                                                                              fontSize: 12,
                                                                              color: Colors.grey.shade600,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ],
                                                                ),
                                                                
                                                                // Price
                                                                Text(
                                                                  '₺${(item.price ?? 0) * (item.piece ?? 1)}',
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w500,
                                                                    color: Colors.grey.shade800,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      
                                                      // Delete button (when not in multiselect mode)
                                                      if (!isMultiSelectMode)
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.delete_outline,
                                                            size: 18,
                                                            color: Colors.red.shade300,
                                                          ),
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(),
                                                          onPressed: () async {
                                                            // Silme işlemi için onay dialog'u göster
                                                            final shouldDelete =
                                                                await showDialog<
                                                                    bool>(
                                                              context: context,
                                                              builder:
                                                                  (context) =>
                                                                      Dialog(
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20),
                                                                ),
                                                                child:
                                                                    Container(
                                                                  width: 400,
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                      32),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .white,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            20),
                                                                  ),
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text(
                                                                            'Adisyon Silme',
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontSize: 24,
                                                                              fontWeight: FontWeight.w600,
                                                                              color: Colors.black,
                                                                              letterSpacing: -0.5,
                                                                            ),
                                                                          ),
                                                                          IconButton(
                                                                            onPressed: () =>
                                                                                Navigator.pop(context, false),
                                                                            icon:
                                                                                Icon(
                                                                              Icons.close,
                                                                              color: Colors.grey[400],
                                                                              size: 24,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      const SizedBox(
                                                                          height:
                                                                              24),
                                                                      Text(
                                                                        'Bu adisyonu silmek istediğinize emin misiniz?',
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontSize:
                                                                              16,
                                                                          color:
                                                                              Colors.grey[700],
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                          height:
                                                                              32),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.end,
                                                                        children: [
                                                                          TextButton(
                                                                            onPressed: () =>
                                                                                Navigator.pop(context, false),
                                                                            child:
                                                                                Text(
                                                                              'İptal',
                                                                              style: GoogleFonts.poppins(
                                                                                fontSize: 16,
                                                                                color: Colors.grey[600],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                              width: 16),
                                                                          ElevatedButton(
                                                                            style:
                                                                                ElevatedButton.styleFrom(
                                                                              backgroundColor: Colors.red,
                                                                              padding: const EdgeInsets.symmetric(
                                                                                horizontal: 24,
                                                                                vertical: 12,
                                                                              ),
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(12),
                                                                              ),
                                                                            ),
                                                                            onPressed: () =>
                                                                                Navigator.pop(context, true),
                                                                            child:
                                                                                Text(
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
                                                              ),
                                                            );

                                                            // Kullanıcı onayladıysa silme işlemini gerçekleştir
                                                            if (shouldDelete ==
                                                                    true &&
                                                                context
                                                                    .mounted) {
                                                              final billItemId =
                                                                  item.id;
                                                              if (billItemId !=
                                                                  null) {
                                                                final success =
                                                                    await PaymentService
                                                                        .deleteBillItem(
                                                                            billItemId);
                                                                if (success &&
                                                                    context
                                                                        .mounted) {
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    const SnackBar(
                                                                        content:
                                                                            Text('Adisyon başarıyla silindi')),
                                                                  );
                                                                  // Silme işlemi başarılı olduktan sonra sayfayı yenile
                                                                  ref
                                                                      .read(tablesProvider
                                                                          .notifier)
                                                                      .fetchTableBillApi(
                                                                          widget
                                                                              .tableId);
                                                                } else if (context
                                                                    .mounted) {
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    const SnackBar(
                                                                        content:
                                                                            Text('Adisyon silinirken bir hata oluştu')),
                                                                  );
                                                                }
                                                              }
                                                            }
                                                          },
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                              
                                              // Apply slide animation only for newly added items
                                              if (isNewlyAdded) {
                                                return TweenAnimationBuilder<Offset>(
                                                  tween: Tween<Offset>(
                                                    begin: const Offset(-1, 0),
                                                    end: Offset.zero,
                                                  ),
                                                  duration: const Duration(milliseconds: 300),
                                                  curve: Curves.easeOutCubic,
                                                  builder: (context, offset, child) {
                                                    return FractionalTranslation(
                                                      translation: offset,
                                                      child: child,
                                                    );
                                                  },
                                                  child: contentWidget,
                                                );
                                              }
                                              
                                              // Return without animation for existing items
                                              return contentWidget;
                                            },
                                          ),
                                        ),
                                        const Divider(
                                          indent: 10,
                                          endIndent: 10,
                                        ),
                                        if (isMultiSelectMode)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            child: Row(
                                              children: [
                                                Text(
                                                  '${selectedItems.length} öğe seçildi',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const Spacer(),
                                                TextButton(
                                                  onPressed: clearSelection,
                                                  child: const Text('İptal', style: TextStyle(color: Colors.black),),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  onPressed: () async {
                                                    final shouldDelete = await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) => Dialog(
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
                                                                    'Toplu Silme',
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
                                                                'Seçili ${selectedItems.length} adisyonu silmek istediğinize emin misiniz?',
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
                                                      ),
                                                    );

                                                    if (shouldDelete == true && context.mounted) {
                                                      bool allSuccess = true;
                                                      for (int billItemId in selectedItems) {
                                                        final success = await PaymentService.deleteBillItem(billItemId);
                                                        if (!success) {
                                                          allSuccess = false;
                                                          break;
                                                        }
                                                      }

                                                      if (context.mounted) {
                                                        if (allSuccess) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Seçili adisyonlar başarıyla silindi'),
                                                              backgroundColor: Colors.green,
                                                            ),
                                                          );
                                                          clearSelection();
                                                          // Sayfayı yenile
                                                          ref.read(tablesProvider.notifier).fetchTableBillApi(widget.tableId);
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Adisyonlar silinirken bir hata oluştu'),
                                                              backgroundColor: Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    }
                                                  },
                                                  icon: const Icon(Icons.delete_outline, color: Colors.white,),
                                                  label: const Text('Seçilenleri Sil'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 10),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Toplam Tutar',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                '₺$totalAmount',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 6,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: deviceWidth < 1350
                                              ? verticalButtons(
                                                  tableBill,
                                                  context,
                                                  ref,
                                                  allItemsPaid,
                                                )
                                              : horiontalButtons(tableBill,
                                                  context, ref, allItemsPaid),
                                        ),
                                        const SizedBox(
                                          height: 24,
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Row horiontalButtons(List<Menu> tableBill, BuildContext context,
      WidgetRef ref, bool allItemsPaid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.transparent),
              backgroundColor:
                  tableBill.isNotEmpty ? Colors.green : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: tableBill.isNotEmpty
                ? () async {
                    final result = await paymentShowDialog(
                        context,
                        widget.tableId,
                        widget.tableTitle,
                        widget.isSelfService);
                    if (result == true) {
                      ref
                          .read(tablesProvider.notifier)
                          .fetchTableBillApi(widget.tableId);
                    }
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ÖDE',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₺$remainingAmount',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.transparent),
              backgroundColor:
                  tableBill.isNotEmpty ? Colors.orange : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: tableBill.isNotEmpty
                ? () async {
                    // Hızlı ödeme işlemi burada yapılacak
                    final isCredit =
                        await quickPaymentDialog(context, tableBill);
                    if (isCredit != null && widget.isSelfService) {
                      ref
                          .read(tablesProvider.notifier)
                          .fetchTableBillApi(widget.tableId);
                    } else if (isCredit != null && !widget.isSelfService) {
                      Navigator.pop(context);
                    }
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: isClosing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'HIZLI ÖDE',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.print,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (!widget.isSelfService) ...[
          const SizedBox(width: 4),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: (allItemsPaid && tableBill.isNotEmpty)
                    ? ColorConstants.billCloseButtonColor
                    : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: (allItemsPaid && tableBill.isNotEmpty) && !isClosing
                  ? () async {
                      setState(() {
                        isClosing = true;
                      });

                      final tablesNotifier = ref.read(tablesProvider.notifier);
                      final isClosed =
                          await tablesNotifier.hesabiKapat(widget.tableId);

                      if (isClosed) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Hesap başarıyla kapatıldı!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Hesap kapatılırken bir hata oluştu!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                      setState(() {
                        isClosing = false;
                      });
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isClosing)
                      const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      const Text(
                        'HESABI KAPAT',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Column verticalButtons(List<Menu> tableBill, BuildContext context,
      WidgetRef ref, bool allItemsPaid) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.transparent),
            backgroundColor: tableBill.isNotEmpty ? Colors.green : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: tableBill.isNotEmpty
              ? () async {
                  final result = await paymentShowDialog(context,
                      widget.tableId, widget.tableTitle, widget.isSelfService);
                  if (result == true) {
                    ref
                        .read(tablesProvider.notifier)
                        .fetchTableBillApi(widget.tableId);
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ÖDE',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₺$remainingAmount',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.transparent),
            backgroundColor: tableBill.isNotEmpty ? Colors.orange : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: tableBill.isNotEmpty
              ? () async {
                  // Hızlı ödeme işlemi burada yapılacak
                  final isCredit = await quickPaymentDialog(context, tableBill);
                  if (isCredit != null && widget.isSelfService) {
                    ref
                        .read(tablesProvider.notifier)
                        .fetchTableBillApi(widget.tableId);
                  } else if (isCredit != null && !widget.isSelfService) {
                    Navigator.pop(context);
                  }
                }
              : null,
          child: const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'HIZLI ÖDE',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.print,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (!widget.isSelfService) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: (allItemsPaid && tableBill.isNotEmpty)
                  ? ColorConstants.billCloseButtonColor
                  : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: (allItemsPaid && tableBill.isNotEmpty) && !isClosing
                ? () async {
                    setState(() {
                      isClosing = true;
                    });
                    final tablesNotifier = ref.read(tablesProvider.notifier);
                    final isClosed =
                        await tablesNotifier.hesabiKapat(widget.tableId);

                    if (isClosed) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hesap başarıyla kapatıldı!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Hesap kapatılırken bir hata oluştu!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                    setState(() {
                      isClosing = false;
                    });
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isClosing)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Text(
                      'HESABI KAPAT',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void calculateAmount(List<Menu> tableBill, double totalAmount) {
    final tableBillAmount = _getTableBillAmount(widget.tableId);
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

  Future<bool?> quickPaymentDialog(
      BuildContext context, List<Menu> tableBill) async {
    bool? isCredit;
    
    // Check if it's self service and contains only "Üye Girişi"
    if (widget.isSelfService && tableBill.length == 1 && tableBill.first.title == 'Üye Girişi') {
      // Process payment directly with credit card
      try {
        final tableBillCopy = List<Menu>.from(tableBill);
        final rightList = tableBillCopy
            .map((item) => item.copyWith(
                  status: 'ödendi',
                  isCredit: true, // Default to credit card payment
                ))
            .toList();

        final success = await PaymentService.processPayment(
          context: context,
          ref: ref,
          tableId: widget.tableId,
          rightList: rightList,
          amountItemsToDelete: {},
          onSavingChanged: (value) {},
        );

        if (success) {
          final billItemsForPrinter = rightList
              .map((item) => {
                    'title': item.title,
                    'price': item.price,
                    'piece': item.piece,
                    'isCredit': true,
                    'status': 'ödendi'
                  })
              .toList();
          
          await _handlePrinting(billItemsForPrinter);

          if (context.mounted) {
            final tablesNotifier = ref.read(tablesProvider.notifier);
            final isClosed = await tablesNotifier.hesabiKapat(widget.tableId);

            if (isClosed) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hesap başarıyla kapatıldı!'),
                    backgroundColor: Colors.green,
                  ),
                );

                ref.read(tablesProvider.notifier).fetchTableBillApi(widget.tableId);
                return true; // Return true for credit card payment
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hesap kapatılırken bir hata oluştu!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ödeme işlemi başarısız oldu!'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return null;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bir hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    }

    // Original dialog code for other cases
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            Future<void> processPayment(bool isCreditCard) async {
              try {
                dialogSetState(() {
                  isLoading = true;
                });

                final tableBillCopy = List<Menu>.from(tableBill);
                final rightList = tableBillCopy
                    .map((item) => item.copyWith(
                          status: 'ödendi',
                          isCredit: isCreditCard,
                        ))
                    .toList();

                final success = await PaymentService.processPayment(
                  context: context,
                  ref: ref,
                  tableId: widget.tableId,
                  rightList: rightList,
                  amountItemsToDelete: {},
                  onSavingChanged: (value) {},
                );

                if (success) {
                  final billItemsForPrinter = rightList
                      .map((item) => {
                            'title': item.title,
                            'price': item.price,
                            'piece': item.piece,
                            'isCredit': isCreditCard,
                            'status': 'ödendi'
                          })
                      .toList();
                  if (widget.isSelfService) {
                    await _handlePrinting(billItemsForPrinter);
                  }

                  if (context.mounted) {
                    final tablesNotifier = ref.read(tablesProvider.notifier);
                    final isClosed =
                        await tablesNotifier.hesabiKapat(widget.tableId);

                    if (isClosed) {
                      dialogSetState(() {
                        isLoading = false;
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hesap başarıyla kapatıldı!'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        isCredit = isCreditCard;
                        if (widget.isSelfService) {
                          ref
                              .read(tablesProvider.notifier)
                              .fetchTableBillApi(widget.tableId);
                        }
                        Navigator.of(context).pop(isCredit);
                      }
                    } else {
                      dialogSetState(() {
                        isLoading = false;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Hesap kapatılırken bir hata oluştu!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                } else {
                  dialogSetState(() {
                    isLoading = false;
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ödeme işlemi başarısız oldu!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                dialogSetState(() {
                  isLoading = false;
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bir hata oluştu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ödeme Yöntemi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isLoading)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.grey,
                      tooltip: 'Kapat',
                    ),
                ],
              ),
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onPressed: isLoading ? null : () => processPayment(true),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.orange,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.credit_card, color: Colors.orange),
                      label: Text(
                        'Kredi Kartı',
                        style: TextStyle(
                          color: isLoading ? Colors.grey : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onPressed: isLoading ? null : () => processPayment(false),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.green,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.payments, color: Colors.green),
                      label: Text(
                        'Nakit',
                        style: TextStyle(
                          color: isLoading ? Colors.grey : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handlePrinting(List<Map<String, dynamic>> billItems) async {
    if (_isPrinting) return;

    setState(() {
      _isPrinting = true;
    });

    try {
      await PrinterService.printReceiptToPhysicalPrinter(billItems);
    } catch (e) {
      print('❌ Beklenmeyen hata: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  String _formatPreparationTime(DateTime time) {
    final localTime = time.toLocal();
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }
}

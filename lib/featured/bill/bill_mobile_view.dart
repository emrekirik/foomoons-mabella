import 'package:foomoons/featured/bill/payment_showbottomsheet.dart';
import 'package:foomoons/featured/providers/menu_notifier.dart';
import 'package:foomoons/product/constants/color_constants.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:flutter/rendering.dart';
import 'package:foomoons/product/services/payment_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foomoons/product/services/bar_printer_service.dart';
import 'package:foomoons/product/services/kitchen_printer_service.dart';

class BillMobileView extends ConsumerStatefulWidget {
  final int tableId;
  final String tableTitle;
  final List<Menu> orderItems;
  final String? qrUrl;
  const BillMobileView({
    required this.tableId,
    required this.tableTitle,
    required this.orderItems,
    this.qrUrl,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BillMobileViewState();
}

class _BillMobileViewState extends ConsumerState<BillMobileView>
    with TickerProviderStateMixin {
  bool isClosing = false;
  bool isSending = false;
  bool isSearchBarVisible = false;
  late TextEditingController searchContoller;
  String searchQuery = '';
  late bool allItemsPaid;
  late double remainingAmount;
  Map<String, dynamic>? userDetails;

  final Map<String, AnimationController> _animationControllers = {};

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
            await ref.read(menuProvider.notifier).fetchAndLoad();
          }

          // Her durumda ilk kategoriyi seç (eğer kategoriler varsa)
          if (mounted) {
            final categories = ref.read(menuProvider).categories;
            if (categories != null && categories.isNotEmpty) {
              ref
                  .read(menuProvider.notifier)
                  .selectCategory(categories.first.title);
            }
          }
        }
      },
    );
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
    final tablesNotifier = ref.read(tablesProvider.notifier);
    final menuNotifier = ref.read(menuProvider.notifier);
    final productItem = ref.watch(menuProvider).products ?? [];
    final categories = ref.watch(menuProvider).categories ?? [];
    final selectedCategory = ref.watch(menuProvider).selectedValue;
    final userType = ref.watch(userTypeProvider).value ?? 'kafe';

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

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;

            final tableBill =
                ref.read(tablesProvider).getTableBill(widget.tableId);
            final userType = ref.read(userTypeProvider).value ?? 'kafe';

            if (userType == 'garson') {
              // Debug için siparişlerin durumunu kontrol et
              print('Tüm siparişler:');
              for (var item in tableBill) {
                print('Ürün: ${item.title}, Status: ${item.status}');
              }

              // Yeni siparişleri kontrol et (status değeri null veya 'yeni' olanlar)
              final newOrders = tableBill
                  .where((item) =>
                          item.status == null || // Status null ise
                          item.status == '' || // Status boş string ise
                          item.status == 'yeni' // Status 'yeni' ise
                      )
                  .toList();

              print('Yeni sipariş sayısı: ${newOrders.length}');

              if (newOrders.isNotEmpty) {
                final result = await showDialog<bool>(
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
                                'Dikkat',
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
                            '${newOrders.length} adet bekleyen yeni sipariş var. Çıkmak istediğinizden emin misiniz?',
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
                                  'Vazgeç',
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
                                  'Çık',
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
                if (result == true && context.mounted) {
                  // Sadece yeni siparişleri temizle
                  final existingOrders = tableBill
                      .where((item) =>
                          item.status != null &&
                          item.status != '' &&
                          item.status != 'yeni')
                      .toList();
                  ref
                      .read(tablesProvider.notifier)
                      .updateTableBill(widget.tableId, existingOrders);
                  Navigator.of(context).pop();
                }
              } else {
                // Yeni sipariş yoksa direkt çık
                Navigator.of(context).pop();
              }
            } else if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: LayoutBuilder(builder: (context, constraints) {
            return Column(
              children: [
                if (isLoading)
                  const LinearProgressIndicator(
                    color: Colors.green,
                  ),
                Expanded(
                  child: Scaffold(
                    appBar: PreferredSize(
                      preferredSize: Size.fromHeight(60.0),
                      child: AppBar(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        systemOverlayStyle: SystemUiOverlayStyle.dark,
                        flexibleSpace: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                        ),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.black),
                          onPressed: () async {
                            final tableBill = ref
                                .read(tablesProvider)
                                .getTableBill(widget.tableId);
                            final userType =
                                ref.read(userTypeProvider).value ?? 'kafe';

                            if (userType == 'garson') {
                              // Yeni siparişleri kontrol et
                              final newOrders = tableBill
                                  .where((item) => item.status == 'yeni')
                                  .toList();

                              if (newOrders.isNotEmpty) {
                                final result = await showDialog<bool>(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Dikkat',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
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
                                            '${newOrders.length} adet bekleyen yeni sipariş var. Çıkmak istediğinizden emin misiniz?',
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
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: Text(
                                                  'Vazgeç',
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
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: Text(
                                                  'Çık',
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
                                if (result == true && context.mounted) {
                                  // Sadece yeni siparişleri temizle
                                  final existingOrders = tableBill
                                      .where((item) => item.status != 'yeni')
                                      .toList();
                                  ref
                                      .read(tablesProvider.notifier)
                                      .updateTableBill(
                                          widget.tableId, existingOrders);
                                  Navigator.of(context).pop();
                                }
                              } else {
                                // Yeni sipariş yoksa direkt çık
                                Navigator.of(context).pop();
                              }
                            } else if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                        title: Image.asset(
                          'assets/images/logo.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                        centerTitle: true,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    body: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: ColorConstants.white,
                        ),
                        child: Stack(
                          children: [
                            // Üst taraf: Ürün listesi
                            Positioned.fill(
                              bottom: MediaQuery.of(context).size.height * 0.20,
                              child: Container(
                                color: ColorConstants.tablePageBackgroundColor,
                                child: Column(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: const Border(
                                            bottom: BorderSide(
                                          color: Colors.black12,
                                          width: 1,
                                        )),
                                      ),
                                      height: 68,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Search icon
                                          IconButton(
                                            icon: Icon(
                                              isSearchBarVisible
                                                  ? Icons.close
                                                  : Icons.search,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                isSearchBarVisible =
                                                    !isSearchBarVisible; // Arama çubuğu aç/kapat
                                              });
                                            },
                                          ),
                                          // Eğer arama çubuğu görünürse arama çubuğunu göster
                                          if (isSearchBarVisible)
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0),
                                                child: TextField(
                                                  controller: searchContoller,
                                                  decoration: InputDecoration(
                                                    hintText: 'Ara...',
                                                    prefixIcon:
                                                        Icon(Icons.search),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  onChanged: (query) {
                                                    setState(() {
                                                      searchQuery =
                                                          query; // Update search query
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          Expanded(
                                            child: searchQuery.isNotEmpty
                                                ? const SizedBox()
                                                : ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final category =
                                                          categories[index];
                                                      return Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border(
                                                            left: const BorderSide(
                                                                color: Colors
                                                                    .black12,
                                                                width: 1),
                                                            bottom: BorderSide(
                                                              color: selectedCategory ==
                                                                      category
                                                                          .title
                                                                  ? Colors
                                                                      .orange
                                                                  : Colors
                                                                      .transparent, // Seçili kategori altına çizgi ekle
                                                              width:
                                                                  5, // Çizginin kalınlığı
                                                            ),
                                                          ),
                                                        ),
                                                        child: Material(
                                                          color: Colors.white,
                                                          child: InkWell(
                                                            splashColor: Colors
                                                                .orange
                                                                .withOpacity(
                                                                    0.6),
                                                            onTap: () {
                                                              menuNotifier
                                                                  .selectCategory(
                                                                      category
                                                                          .title);
                                                            },
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          12),
                                                              child: Center(
                                                                child: Text(
                                                                  category.title ??
                                                                      '',
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    itemCount:
                                                        categories.length,
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        color: ColorConstants
                                            .tablePageBackgroundColor,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: GridView.builder(
                                            itemCount: filteredItems.length,
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount:
                                                  (constraints.maxWidth / 160)
                                                      .floor(),
                                              crossAxisSpacing: 10,
                                              mainAxisSpacing: 10,
                                              childAspectRatio: 1.6,
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
                                                            BorderRadius
                                                                .circular(15),
                                                      ),
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15),
                                                        splashColor: Colors
                                                            .orange
                                                            .withOpacity(0.3),
                                                        highlightColor: Colors
                                                            .orange
                                                            .withOpacity(0.1),
                                                        onTap: () {
                                                          final userType = ref
                                                                  .read(
                                                                      userTypeProvider)
                                                                  .value ??
                                                              'kafe';
                                                          if (userType ==
                                                              'garson') {
                                                            // Garson için sadece ön tarafta göster
                                                            final newItem =
                                                                item.copyWith(
                                                              tableId: widget
                                                                  .tableId,
                                                              piece: 1,
                                                            );

                                                            setState(() {
                                                              final tableBill = ref
                                                                  .read(
                                                                      tablesProvider)
                                                                  .getTableBill(
                                                                      widget
                                                                          .tableId)
                                                                  .toList();
                                                              tableBill
                                                                  .add(newItem);
                                                              ref
                                                                  .read(tablesProvider
                                                                      .notifier)
                                                                  .updateTableBill(
                                                                      widget
                                                                          .tableId,
                                                                      tableBill);
                                                            });
                                                          } else {
                                                            // Diğer kullanıcı tipleri için normal API çağrısı
                                                            tablesNotifier
                                                                .addItemToBillQueued(
                                                              item.copyWith(
                                                                  tableId: widget
                                                                      .tableId),
                                                            );
                                                          }
                                                        },
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      10),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceAround,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                  item.title ??
                                                                      '',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                  )),
                                                              Text(
                                                                  '₺${item.price}',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                  )),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            //Alt taraf adisyon listesi
                            NotificationListener<
                                DraggableScrollableNotification>(
                              onNotification: (notification) {
                                return true;
                              },
                              child: DraggableScrollableSheet(
                                initialChildSize: 0.25,
                                minChildSize: 0.25,
                                maxChildSize: 1,
                                snap: true,
                                snapSizes: const [0.25, 1],
                                builder: (BuildContext context,
                                    ScrollController scrollController) {
                                  return Consumer(
                                    builder: (context, ref, child) {
                                      final tableBill = ref
                                          .watch(tablesProvider.select(
                                              (state) => state.getTableBill(
                                                  widget.tableId)))
                                          .where(
                                              (item) => item.isAmount != true)
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
                                            borderRadius:
                                                const BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(32),
                                                    topRight:
                                                        Radius.circular(32)),
                                            border: const Border(
                                                top: BorderSide(
                                                    color: Colors.black12,
                                                    width: 1))),
                                        child: ListView(
                                          controller: scrollController,
                                          children: [
                                            // Sürüklenebilir gösterge
                                            Container(
                                              width: double.infinity,
                                              decoration: const BoxDecoration(
                                                color: Colors.orange,
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(28),
                                                  topRight: Radius.circular(28),
                                                ),
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 20),
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 50,
                                                    height: 4,
                                                    child: DecoratedBox(
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    2)),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              child: Text(
                                                widget.tableTitle,
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            ListView.separated(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              separatorBuilder:
                                                  (context, index) =>
                                                      const Divider(
                                                indent: 10,
                                                endIndent: 10,
                                              ),
                                              itemCount: tableBill.length,
                                              itemBuilder:
                                                  (BuildContext context,
                                                      int index) {
                                                final item = tableBill[index];

                                                final itemKey =
                                                    '${item.id}_${item.piece}';

                                                if (!_animationControllers
                                                    .containsKey(itemKey)) {
                                                  _animationControllers[
                                                          itemKey] =
                                                      AnimationController(
                                                    duration: const Duration(
                                                        milliseconds: 300),
                                                    vsync: this,
                                                  )..forward();
                                                }

                                                return SizeTransition(
                                                  sizeFactor: CurvedAnimation(
                                                    parent:
                                                        _animationControllers[
                                                            itemKey]!,
                                                    curve: Curves.easeOut,
                                                  ),
                                                  child: FadeTransition(
                                                    opacity: CurvedAnimation(
                                                      parent:
                                                          _animationControllers[
                                                              itemKey]!,
                                                      curve: Curves.easeOut,
                                                    ),
                                                    child: ListTile(
                                                      title: Text(
                                                        item.title ?? '',
                                                        style: TextStyle(
                                                          fontWeight: item
                                                                      .status ==
                                                                  'yeni'
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                        ),
                                                      ),
                                                      tileColor: item.status ==
                                                              'yeni'
                                                          ? Colors.orange
                                                              .withOpacity(0.1)
                                                          : null,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        side: item.status ==
                                                                'yeni'
                                                            ? const BorderSide(
                                                                color: Colors
                                                                    .orange,
                                                                width: 1)
                                                            : BorderSide.none,
                                                      ),
                                                      subtitle: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            '${item.piece ?? 1} adet',
                                                            style: TextStyle(
                                                              color:
                                                                  item.status ==
                                                                          'yeni'
                                                                      ? Colors
                                                                          .orange
                                                                      : null,
                                                              fontWeight:
                                                                  item.status ==
                                                                          'yeni'
                                                                      ? FontWeight
                                                                          .bold
                                                                      : null,
                                                            ),
                                                          ),
                                                          Text(
                                                            '₺${(item.price ?? 0) * (item.piece ?? 1)}',
                                                            style: TextStyle(
                                                              color:
                                                                  item.status ==
                                                                          'yeni'
                                                                      ? Colors
                                                                          .orange
                                                                      : null,
                                                              fontWeight:
                                                                  item.status ==
                                                                          'yeni'
                                                                      ? FontWeight
                                                                          .bold
                                                                      : null,
                                                            ),
                                                          ),
                                                          if (item.status ==
                                                              'yeni')
                                                            const Text(
                                                              'Yeni Sipariş',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .orange,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      trailing: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          item.status !=
                                                                  'ödendi'
                                                              ? const SizedBox()
                                                              : Text(
                                                                  '${item.status}',
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .green),
                                                                ),
                                                          if (userType ==
                                                                  'admin' &&
                                                              item.status !=
                                                                  'ödendi')
                                                            if (userType ==
                                                                'admin')
                                                              IconButton(
                                                                icon: const Icon(
                                                                    Icons
                                                                        .delete_forever,
                                                                    color: Colors
                                                                        .red),
                                                                onPressed:
                                                                    () async {
                                                                  final result =
                                                                      await showDialog<
                                                                          bool>(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (context) =>
                                                                            Dialog(
                                                                      shape:
                                                                          RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(20),
                                                                      ),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            400,
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            32),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              Colors.white,
                                                                          borderRadius:
                                                                              BorderRadius.circular(20),
                                                                        ),
                                                                        child:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Row(
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Text(
                                                                                  'Ürünü Sil',
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
                                                                              'Bu ürünü silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
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
                                                                                    'Vazgeç',
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

                                                                  if (result ==
                                                                          true &&
                                                                      item.id !=
                                                                          null) {
                                                                    final success =
                                                                        await PaymentService.deleteBillItem(
                                                                            item.id!);
                                                                    if (success &&
                                                                        mounted) {
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        const SnackBar(
                                                                          content:
                                                                              Text('Ürün başarıyla silindi'),
                                                                          backgroundColor:
                                                                              Colors.green,
                                                                        ),
                                                                      );
                                                                      // Tabloyu yenile
                                                                      ref
                                                                          .read(tablesProvider
                                                                              .notifier)
                                                                          .fetchTableBillApi(
                                                                              widget.tableId);
                                                                    } else if (mounted) {
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        const SnackBar(
                                                                          content:
                                                                              Text('Ürün silinirken bir hata oluştu'),
                                                                          backgroundColor:
                                                                              Colors.red,
                                                                        ),
                                                                      );
                                                                    }
                                                                  }
                                                                },
                                                              ),
                                                          if (userType ==
                                                                  'garson' &&
                                                              item.status ==
                                                                  'yeni')
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .orange
                                                                        .withOpacity(
                                                                            0.1),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                    border: Border.all(
                                                                        color: Colors
                                                                            .orange
                                                                            .withOpacity(0.3)),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      IconButton(
                                                                        icon: const Icon(
                                                                            Icons
                                                                                .remove,
                                                                            size:
                                                                                20),
                                                                        onPressed:
                                                                            () {
                                                                          final tableBill =
                                                                                ref.read(tablesProvider).getTableBill(widget.tableId).toList();
                                                                          final index =
                                                                                tableBill.indexOf(item);
                                                                          if (index != -1 &&
                                                                                (item.piece ?? 1) > 1) {
                                                                              tableBill[index] = item.copyWith(piece: (item.piece ?? 1) - 1);
                                                                              ref.read(tablesProvider.notifier).updateTableBill(widget.tableId, tableBill);
                                                                          }
                                                                        },
                                                                        color: Colors
                                                                            .orange,
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            4),
                                                                        constraints:
                                                                            const BoxConstraints(
                                                                          minWidth:
                                                                              32,
                                                                          minHeight:
                                                                              32,
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        constraints:
                                                                            const BoxConstraints(minWidth: 32),
                                                                        alignment:
                                                                            Alignment.center,
                                                                        child:
                                                                            Text(
                                                                          '${item.piece ?? 1}',
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.orange,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      IconButton(
                                                                        icon: const Icon(
                                                                            Icons
                                                                                .add,
                                                                            size:
                                                                                20),
                                                                        onPressed:
                                                                            () {
                                                                          final tableBill =
                                                                                ref.read(tablesProvider).getTableBill(widget.tableId).toList();
                                                                          final index =
                                                                                tableBill.indexOf(item);
                                                                          if (index !=
                                                                                -1) {
                                                                              tableBill[index] = item.copyWith(piece: (item.piece ?? 1) + 1);
                                                                              ref.read(tablesProvider.notifier).updateTableBill(widget.tableId, tableBill);
                                                                          }
                                                                        },
                                                                        color: Colors
                                                                            .orange,
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            4),
                                                                        constraints:
                                                                            const BoxConstraints(
                                                                          minWidth:
                                                                              32,
                                                                          minHeight:
                                                                              32,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                IconButton(
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .message_outlined),
                                                                  onPressed:
                                                                      () async {
                                                                    final message =
                                                                        await showModalBottomSheet<
                                                                            String>(
                                                                      context:
                                                                          context,
                                                                      isScrollControlled:
                                                                          true,
                                                                      shape:
                                                                          const RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.vertical(
                                                                          top: Radius.circular(
                                                                              20),
                                                                        ),
                                                                      ),
                                                                      builder:
                                                                          (BuildContext
                                                                              context) {
                                                                        final messageController =
                                                                            TextEditingController(text: item.customerMessage);
                                                                        return Padding(
                                                                          padding:
                                                                              EdgeInsets.only(
                                                                            bottom:
                                                                                MediaQuery.of(context).viewInsets.bottom,
                                                                          ),
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                const EdgeInsets.all(16),
                                                                            child:
                                                                                Column(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                              children: [
                                                                                Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Text(
                                                                                      'Ürün Açıklaması',
                                                                                      style: GoogleFonts.poppins(
                                                                                        fontSize: 20,
                                                                                        fontWeight: FontWeight.w600,
                                                                                      ),
                                                                                    ),
                                                                                    IconButton(
                                                                                      icon: const Icon(Icons.close),
                                                                                      onPressed: () => Navigator.pop(context),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                                const SizedBox(height: 16),
                                                                                TextField(
                                                                                  controller: messageController,
                                                                                  decoration: InputDecoration(
                                                                                    hintText: 'Ürün için açıklama girin...',
                                                                                    border: OutlineInputBorder(
                                                                                      borderRadius: BorderRadius.circular(12),
                                                                                    ),
                                                                                    filled: true,
                                                                                    fillColor: Colors.grey[100],
                                                                                  ),
                                                                                  maxLines: 3,
                                                                                ),
                                                                                const SizedBox(height: 16),
                                                                                ElevatedButton(
                                                                                  style: ElevatedButton.styleFrom(
                                                                                    backgroundColor: Colors.orange,
                                                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                                                    shape: RoundedRectangleBorder(
                                                                                      borderRadius: BorderRadius.circular(12),
                                                                                    ),
                                                                                  ),
                                                                                  onPressed: () {
                                                                                    Navigator.pop(context, messageController.text);
                                                                                  },
                                                                                  child: Text(
                                                                                    'Kaydet',
                                                                                    style: GoogleFonts.poppins(
                                                                                      fontSize: 16,
                                                                                      color: Colors.white,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 16),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        );
                                                                      },
                                                                    );

                                                                    if (message !=
                                                                        null) {
                                                                      setState(
                                                                          () {
                                                                        final tableBill = ref
                                                                            .read(tablesProvider)
                                                                            .getTableBill(widget.tableId)
                                                                            .toList();
                                                                        final index =
                                                                            tableBill.indexOf(item);
                                                                        if (index !=
                                                                            -1) {
                                                                          tableBill[index] =
                                                                              item.copyWith(customerMessage: message);
                                                                          ref.read(tablesProvider.notifier).updateTableBill(
                                                                              widget.tableId,
                                                                              tableBill);
                                                                        }
                                                                      });
                                                                    }
                                                                  },
                                                                ),
                                                                IconButton(
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .delete_outline,
                                                                      color: Colors
                                                                          .red),
                                                                  onPressed:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      final tableBill = ref
                                                                          .read(
                                                                              tablesProvider)
                                                                          .getTableBill(
                                                                              widget.tableId)
                                                                          .toList();
                                                                      tableBill
                                                                          .remove(
                                                                              item);
                                                                      ref.read(tablesProvider.notifier).updateTableBill(
                                                                          widget
                                                                              .tableId,
                                                                          tableBill);
                                                                    });
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            const Divider(
                                              indent: 10,
                                              endIndent: 10,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 12),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Toplam Tutar',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  Text(
                                                    '₺${tableBill.fold(0.0, (sum, item) => sum + ((item.price ?? 0) * (item.piece ?? 1)))}',
                                                    style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 8,
                                            ),
                                            Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12),
                                                child: verticalButtons(
                                                    tableBill,
                                                    context,
                                                    ref,
                                                    allItemsPaid)),
                                            const SizedBox(
                                              height: 24,
                                            )
                                          ],
                                        ),
                                      );
                                    },
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
          }),
        ),
      ),
    );
  }

  Column verticalButtons(List<Menu> tableBill, BuildContext context,
      WidgetRef ref, bool allItemsPaid) {
    final userType = ref.watch(userTypeProvider).value ?? 'kafe';

    if (userType == 'garson') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.transparent),
                backgroundColor:
                    tableBill.where((item) => item.status == 'yeni').isNotEmpty
                        ? Colors.green
                        : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              onPressed: (tableBill
                          .where((item) => item.status == 'yeni')
                          .isNotEmpty &&
                      !isSending)
                  ? () async {
                      setState(() {
                        isSending = true;
                      });

                      // Sadece yeni eklenen (status'u 'yeni' olan) ürünleri filtrele
                      final newOrders = tableBill
                          .where((item) => item.status == 'yeni')
                          .toList();

                      // Garson için sadece yeni ürünleri API'ye gönder
                      final orderService = ref.read(orderServiceProvider);
                      bool hasError = false;
                      int successCount = 0;

                      for (var item in newOrders) {
                        try {
                          // Önce siparişi API'ye gönder
                          final success = await orderService.addOrder(
                              item, widget.tableTitle);

                          if (success) {
                            // API'ye gönderim başarılı olduysa, yazıcıya gönder
                            try {
                              print(' Yazıcıya gönderiliyor...');
                              print('🖨️ Sipariş Tipi: ${item.orderType}');

                              final orderData = {
                                'title': item.title,
                                'piece': item.piece,
                                'tableTitle': widget.tableTitle,
                              };

                              if (item.orderType?.toLowerCase() == 'bar' ||
                                  item.orderType == null) {
                                print(
                                    '�� Bar siparişi yazıcıya gönderiliyor...');
                                await BarPrinterService.printBarOrder(
                                  orderData,
                                  useWifi: true,
                                );
                                print('✅ Bar siparişi yazıcıya gönderildi');
                              } else if (item.orderType?.toLowerCase() ==
                                  'mutfak') {
                                print(
                                    '🍳 Mutfak siparişi yazıcıya gönderiliyor...');
                                await KitchenPrinterService.printKitchenOrder(
                                  orderData,
                                  useWifi: true,
                                );
                                print('✅ Mutfak siparişi yazıcıya gönderildi');
                              } else {
                                print(
                                    '⚠️ Bilinmeyen sipariş tipi: ${item.orderType}');
                              }
                              successCount++;
                            } catch (printerError) {
                              print('❌ Yazıcı hatası detayı: $printerError');
                              print('📍 Hata konumu: ${StackTrace.current}');
                              // Yazıcı hatası olsa bile API'ye gönderildiği için başarılı sayıyoruz
                              successCount++;
                            }
                          } else {
                            hasError = true;
                            break;
                          }
                        } catch (e) {
                          hasError = true;
                          break;
                        }
                      }

                      if (mounted) {
                        setState(() {
                          isSending = false;
                        });
                      }

                      if (context.mounted) {
                        if (successCount == newOrders.length) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Yeni siparişler başarıyla gönderildi!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Başarılı gönderimden sonra sadece yeni siparişleri temizle
                          final existingOrders = tableBill
                              .where((item) => item.status != 'yeni')
                              .toList();
                          ref
                              .read(tablesProvider.notifier)
                              .updateTableBill(widget.tableId, existingOrders);
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '$successCount yeni sipariş gönderildi, ${newOrders.length - successCount} sipariş gönderilemedi!'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                child: isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'GÖNDER',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.transparent),
              backgroundColor:
                  tableBill.isNotEmpty ? Colors.green : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            onPressed: tableBill.isNotEmpty
                ? () async {
                    final result = await paymentBottomSheet(
                        context, widget.tableId, widget.tableTitle);
                    if (result == true) {
                      ref
                          .read(tablesProvider.notifier)
                          .fetchTableBillApi(widget.tableId);
                    }
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ÖDE',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '₺$remainingAmount',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: (allItemsPaid && tableBill.isNotEmpty)
                  ? ColorConstants.billCloseButtonColor
                  : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
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
                vertical: 12,
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
                  : const Text(
                      'HESABI KAPAT',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
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
}

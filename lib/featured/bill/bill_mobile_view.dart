import 'package:foomoons/featured/bill/payment_showbottomsheet.dart';
import 'package:foomoons/featured/providers/menu_notifier.dart';
import 'package:foomoons/product/constants/color_constants.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:flutter/rendering.dart';

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
              ref.read(menuProvider.notifier).selectCategory(categories.first.title);
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
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
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
                                                      decoration: BoxDecoration(
                                                        border: Border(
                                                          left:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .black12,
                                                                  width: 1),
                                                          bottom: BorderSide(
                                                            color: selectedCategory ==
                                                                    category
                                                                        .title
                                                                ? Colors.orange
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
                                                              .withOpacity(0.6),
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
                                                  itemCount: categories.length,
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
                                                          BorderRadius.circular(
                                                              15),
                                                    ),
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      splashColor: Colors.orange
                                                          .withOpacity(0.3),
                                                      highlightColor: Colors
                                                          .orange
                                                          .withOpacity(0.1),
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
                                                                horizontal: 10),
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
                                                                  fontSize: 16,
                                                                )),
                                                            Text(
                                                                '₺${item.price}',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 16,
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
                          NotificationListener<DraggableScrollableNotification>(
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
                                        .watch(tablesProvider.select((state) =>
                                            state.getTableBill(widget.tableId)))
                                        .where((item) => item.isAmount != true)
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
                                              topLeft: Radius.circular(32),
                                              topRight: Radius.circular(32)),
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
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(
                                              widget.tableTitle,
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
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
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              final item = tableBill[index];

                                              final itemKey =
                                                  '${item.id}_${item.piece}';

                                              if (!_animationControllers
                                                  .containsKey(itemKey)) {
                                                _animationControllers[itemKey] =
                                                    AnimationController(
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  vsync: this,
                                                )..forward();
                                              }

                                              return SizeTransition(
                                                sizeFactor: CurvedAnimation(
                                                  parent: _animationControllers[
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
                                                    title:
                                                        Text(item.title ?? ''),
                                                    subtitle: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                            '${item.piece ?? 1} adet'),
                                                        Text(
                                                            '₺${(item.price ?? 0) * (item.piece ?? 1)}'),
                                                      ],
                                                    ),
                                                    trailing: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        item.status != 'ödendi'
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
                                                        IconButton(
                                                          icon: const Icon(Icons
                                                              .remove_circle_outline),
                                                          onPressed: () {},
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
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 12),
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
                                              child: verticalButtons(tableBill,
                                                  context, ref, allItemsPaid)),
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
    );
  }

  Column verticalButtons(List<Menu> tableBill, BuildContext context,
      WidgetRef ref, bool allItemsPaid) {
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
              backgroundColor: tableBill.isNotEmpty
                  ? Colors.green
                  : Colors.grey, // Liste boşsa rengi gri yap
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            onPressed: tableBill.isNotEmpty
                ? () async {
                    final result = await paymentBottomSheet(
                        context, widget.tableId, widget.tableTitle);
                    if (result == true) {
                      // Dialog kapandıktan sonra verileri yenile
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
            ), // Liste boşsa düğme pasif olur
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: (allItemsPaid &&
                      tableBill
                          .isNotEmpty) // Adisyon boş değil ve tüm öğeler ödendi mi?
                  ? ColorConstants.billCloseButtonColor
                  : Colors
                      .grey, // Eğer adisyon boş veya tüm öğeler ödenmediyse buton gri (pasif) olur
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            onPressed: (allItemsPaid && tableBill.isNotEmpty) &&
                    !isClosing // Adisyon boş değil ve tüm öğeler ödendiyse buton aktif olur
                ? () async {
                    setState(() {
                      isClosing = true; // Hesap kapatma işlemi başladı
                    });
                    
                    final tablesNotifier = ref.read(tablesProvider.notifier);
                    final isClosed = await tablesNotifier.hesabiKapat(widget.tableId);

                    if (isClosed) {
                      // Hesap başarıyla kapatıldıysa kullanıcıya bildirim göster ve sayfayı kapat
                      if (context.mounted) {
                        // Verileri güncelle
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hesap başarıyla kapatıldı!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context); // Sayfayı kapat
                      }
                    } else {
                      // Eğer hesap kapatılamadıysa kullanıcıya uyarı mesajı göster
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hesap kapatılırken bir hata oluştu!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                    
                    setState(() {
                      isClosing = false; // Hesap kapatma işlemi bitti
                    });
                  }
                : null, // Buton aktif değilse `null` değer atayarak pasif hale getir
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

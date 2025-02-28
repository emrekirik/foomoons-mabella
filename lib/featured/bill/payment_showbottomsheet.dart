import 'package:foomoons/featured/bill/custom_numpad_mobile.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/product/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

Future<bool?> paymentBottomSheet(
    BuildContext context, int tableId, String tableTitle) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
        ),
        child: _PaymentPage(tableId: tableId, tableTitle: tableTitle),
      );
    },
  );
}

class _PaymentPage extends ConsumerStatefulWidget {
  final int tableId;
  final String tableTitle;
  const _PaymentPage({
    required this.tableId,
    required this.tableTitle,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<_PaymentPage> {
  late List<Menu> leftList;
  late List<Menu> rightList;
  Set<int> selectedIndexes = {};
  Set<int> saveIndexes = {};
  Set<int> amountItemsToDelete = {}; // Silinecek amount ödemelerin ID'lerini tutacak Set
  bool isLoading = true;
  bool hasChanges = false;
  double totalAmount = 0;
  double paidAmount = 0;
  double remainingAmount = 0;
  double inputAmount = 0;
  bool isSaving = false;
  bool? isCredit;
  String? errorMessage;
  String selectedPaymentType = 'product';
  late TextEditingController inputController;

  @override
  void initState() {
    super.initState();
    leftList = [];
    rightList = [];
    inputController = TextEditingController();
    _loadTableData(); // Load data asynchronously
  }

  Future<void> _loadTableData() async {
    await ref.read(tablesProvider.notifier).fetchTableBillApi(widget.tableId);
    final initialItems = ref.read(tablesProvider).getTableBill(widget.tableId);

    if (mounted) {
      setState(() {
        leftList =
            initialItems.where((item) => item.status != 'ödendi').toList();
        rightList =
            initialItems.where((item) => item.status == 'ödendi').toList();
        _calculateAmounts();
        isLoading = false;
        hasChanges = false; // Başlangıçta değişiklik yok
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? _buildShimmerLoading()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hesap',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    _paymentTypeButtons(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  widget.tableTitle,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: selectedPaymentType == 'amount'
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _amountBased(),
                      )
                    : _productBased(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const Divider(),
                    _buildAmountSummary(),
                    if (errorMessage != null)
                      ErrorMessage(errorMessage: errorMessage),
                    _buildSaveButton(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 100,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Card(
                      child: Container(
                        height: 80,
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 16,
                                    color: Colors.white,
                                  ),
                                  Container(
                                    width: 100,
                                    height: 14,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 20,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Row _paymentTypeButtons() {
    return Row(
      children: [
        if (selectedPaymentType == 'amount')
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedPaymentType == 'product'
                  ? Colors.orange
                  : Colors.grey.shade200,
            ),
            onPressed: () {
              setState(() {
                selectedPaymentType = 'product';
                inputAmount = 0;
              });
            },
            child: const Text(
              'Ürün Bazlı',
              style: TextStyle(color: Colors.black),
            ),
          ),
        if (selectedPaymentType == 'product')
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedPaymentType == 'amount'
                  ? Colors.orange
                  : Colors.grey.shade200,
            ),
            onPressed: () {
              setState(() {
                selectedPaymentType = 'amount';
                // Seçili ürünleri temizle
                selectedIndexes.clear();
                // Hata mesajını temizle
                errorMessage = null;
              });
            },
            child: const Text(
              'Tutar Bazlı',
              style: TextStyle(color: Colors.black),
            ),
          ),
      ],
    );
  }

  Column _amountBased() {
    return Column(
      children: [
        SizedBox(
          height: 60,
          width: 280,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Ödeme Tutarı',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              controller: TextEditingController(text: inputAmount.toString()),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: CustomNumpadMobile(
            value: remainingAmount,
            onInput: (value) {
              setState(() {
                inputAmount = double.tryParse(value) ?? 0;
              });
            },
          ),
        ),
      ],
    );
  }

  SingleChildScrollView _productBased() {
    final allItems = [...leftList, ...rightList];
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ÜRÜNLER',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              final item = allItems[index];
              final isSelected = selectedIndexes.contains(index);
              final isPaid = item.status == 'ödendi';
              return Card(
                color: isPaid
                    ? Colors.green.shade50
                    : isSelected
                        ? Colors.orange.shade100
                        : Colors.white,
                child: ListTile(
                  hoverColor: Colors.transparent,
                  title: Row(
                    children: [
                      Text(item.title ?? ''),
                      if (isPaid)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.piece ?? 1} adet'),
                      if (isPaid)
                        Text(
                          item.isCredit == true ? 'Kredi Kartı' : 'Nakit',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: Text('₺${(item.price ?? 0) * (item.piece ?? 1)}',
                      style: const TextStyle(fontSize: 16)),
                  onTap: isPaid
                      ? () {
                          _moveItemToUnpaid(item);
                        }
                      : () {
                          setState(() {
                            if (isSelected) {
                              selectedIndexes.remove(index);
                            } else {
                              selectedIndexes.add(index);
                            }
                          });
                        },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSummary() {
    return Column(
      children: [
        _buildAmountRow('Toplam Tutar:', '₺$totalAmount'),
        _buildAmountRow('Ödenen Tutar:', '₺$paidAmount'),
        _buildAmountRow('Kalan Tutar:', '₺$remainingAmount'),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.42,
                child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        backgroundColor: isCredit == true
                            ? Colors.orange
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.black),
                            borderRadius: BorderRadius.circular(4))),
                    onPressed: () {
                      _processSelectedItems(true);
                    },
                    icon: const Icon(
                      Icons.credit_card,
                      color: Colors.black,
                    ),
                    label: Text('Kredi Kartı',
                        style: TextStyle(color: Colors.black))),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.42,
                child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        backgroundColor: isCredit == false
                            ? Colors.green
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4))),
                    onPressed: () {
                      _processSelectedItems(false); // Nakit için false
                    },
                    icon: const Icon(
                      Icons.payments,
                      color: Colors.black,
                    ),
                    label:
                        Text('Nakit', style: TextStyle(color: Colors.black))),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildAmountRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
            backgroundColor:
                (!hasChanges || isSaving || selectedIndexes.isNotEmpty)
                    ? Colors.grey
                    : Colors.green,
            side: BorderSide(
                color: (!hasChanges || isSaving || selectedIndexes.isNotEmpty)
                    ? Colors.grey
                    : Colors.green)),
        onPressed: (!hasChanges || isSaving || selectedIndexes.isNotEmpty)
            ? null
            : () => _onPayPressed(context),
        child:
            Text('Kaydet', style: TextStyle(fontSize: 20, color: Colors.white)),
      ),
    );
  }

  void _processSelectedItems(bool isCreditSelected) async {
    if (totalAmount == paidAmount) {
      setState(() {
        errorMessage = 'Hesap zaten ödendi.';
      });
      return;
    }
    if (inputAmount > remainingAmount) {
      setState(() {
        errorMessage = 'Hesaptan daha fazla ücret ödeyemezsiniz';
      });
      return;
    }

    // Seçili ürünlerin toplam tutarını hesapla
    double selectedItemsTotal = 0;
    if (selectedIndexes.isNotEmpty) {
      selectedItemsTotal = selectedIndexes.fold<double>(
        0,
        (sum, index) {
          final item = leftList[index];
          return sum + ((item.price ?? 0) * (item.piece ?? 1));
        },
      );

      // Seçili ürünlerin tutarı kalan tutardan fazlaysa işlemi engelle
      if (selectedItemsTotal > remainingAmount) {
        setState(() {
          errorMessage = 'Hesaptan daha fazla ücret ödeyemezsiniz';
        });
        return;
      }
    }

    List<Menu> itemsToMove = [];
    if (inputAmount != 0) {
      // Yeni tutar bazlı ödeme oluştur
      final amount = Menu(
        id: null, // Yeni ödeme olduğu için id null olmalı
        title: isCreditSelected ? 'Kredi' : 'Nakit',
        isCredit: isCreditSelected,
        price: inputAmount,
        status: 'ödendi',
        isAmount: true,
        billId: rightList.isNotEmpty ? rightList.first.billId : null, // Mevcut billId'yi kullan
      );
      itemsToMove.add(amount);
    }

    // Eğer selectedIndexes boş değilse, listedeki öğeleri ekle
    if (selectedIndexes.isNotEmpty) {
      itemsToMove.addAll(selectedIndexes.map((index) {
        final item = leftList[index];
        return item.copyWith(
          status: 'ödendi',
          isCredit: isCreditSelected,
        );
      }).toList());
    }

    // Eğer hala liste boşsa, hata mesajını göster ve işlemi durdur
    if (itemsToMove.isEmpty) {
      setState(() {
        errorMessage = 'Lütfen önce bir veya daha fazla ürün seçin.';
      });
      return;
    }
    setState(() {
      // Sağ listeye sadece yeni ödemeleri ekle
      rightList.addAll(itemsToMove);
      saveIndexes = {...selectedIndexes};
      // Sol listeyi, taşınan ürünlerin `id` değerine göre filtrele
      leftList = leftList.where((item) {
        return !itemsToMove.any((movedItem) => movedItem.id == item.id);
      }).toList();

      selectedIndexes.clear(); // Seçim listesini temizle
      errorMessage = null; // Hata mesajını temizle
      hasChanges = true; // Değişiklik olduğunu işaretle
    });
    _calculateAmounts();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCreditSelected
              ? 'Seçilen ürünler kredi kartı ile ödendi olarak işaretlendi.'
              : 'Seçilen ürünler nakit ile ödendi olarak işaretlendi.',
        ),
      ),
    );

    setState(() {
      inputAmount = 0; // Reset input amount after payment
    });
  }

  /// `ÖDE` butonuna basıldığında sağ listedeki ürünlerin `status` alanını `ödendi` olarak günceller
  Future<void> _onPayPressed(BuildContext context) async {
    if (isSaving) return;

    final success = await PaymentService.processPayment(
      context: context,
      ref: ref,
      tableId: widget.tableId,
      rightList: rightList,
      amountItemsToDelete: amountItemsToDelete, // Silinecek ID'leri gönder
      onSavingChanged: (value) => setState(() => isSaving = value),
    );

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _moveItemToUnpaid(Menu item) {
    // Tutar bazlı ödemeler için
    if (item.isAmount == true) {
      setState(() {
        rightList.removeWhere((element) => element.id == item.id);
        if (item.id != null) {
          amountItemsToDelete.add(item.id!); // ID'yi silme listesine ekle
        }
        _calculateAmounts();
        hasChanges = true;
      });
      return;
    }

    // Normal ürünler için eski davranışı koru
    setState(() {
      rightList.removeWhere((element) => element.id == item.id);
      leftList.add(item.copyWith(status: 'bekliyor', isCredit: null));
      _calculateAmounts();
      hasChanges = true;
    });
  }

  void _calculateAmounts() {
    // `isAmount` true olan ürünlerin fiyatlarını filtrele ve çıkar
    double amountItemTotal = rightList
        .where((item) => item.isAmount == true)
        .fold<double>(
            0, (sum, item) => sum + ((item.price ?? 0) * (item.piece ?? 1)));

    // Toplam tutarı hesapla (`isAmount` ürünler hariç)
    totalAmount = leftList.where((item) => item.isAmount != true).fold<double>(
            0, (sum, item) => sum + ((item.price ?? 0) * (item.piece ?? 1))) +
        rightList.where((item) => item.isAmount != true).fold<double>(
            0, (sum, item) => sum + ((item.price ?? 0) * (item.piece ?? 1)));

    // Ödenen tutarı hesapla
    paidAmount = rightList.where((item) => item.isAmount != true).fold<double>(
        0, (sum, item) => sum + ((item.price ?? 0) * (item.piece ?? 1)));

    // Kalan tutarı hesapla
    remainingAmount = totalAmount - paidAmount - amountItemTotal;
    paidAmount = rightList.fold<double>(
        0, (sum, item) => sum + ((item.price ?? 0) * (item.piece ?? 1)));
  }
}

class ErrorMessage extends StatelessWidget {
  const ErrorMessage({
    super.key,
    required this.errorMessage,
  });

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        errorMessage!,
        style: TextStyle(
          color: errorMessage == 'Lütfen ödeme yöntemi seçin.'
              ? Colors.red
              : Colors.green,
          fontSize: 16,
        ),
      ),
    );
  }
}

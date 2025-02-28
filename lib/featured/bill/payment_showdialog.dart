import 'package:foomoons/featured/bill/custom_numpad.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/product/services/payment_service.dart';

Future<bool?> paymentShowDialog(BuildContext context, int tableId,
    String tableTitle, bool isSelfService) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return _PaymentPage(
        tableId: tableId,
        tableTitle: tableTitle,
        isSelfService: isSelfService,
      );
    },
  );
}

class _PaymentPage extends ConsumerStatefulWidget {
  final String tableTitle;
  final int tableId;
  final bool isSelfService;
  const _PaymentPage({
    required this.tableTitle,
    required this.tableId,
    required this.isSelfService,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<_PaymentPage> {
  late List<Menu> leftList; // Sol listede yer alan ürünler
  late List<Menu> rightList; // Sağ listede yer alan ürünler
  Set<int> selectedIndexes = {};
  Set<int> saveIndexes = {};
  Set<int> amountItemsToDelete =
      {}; // Silinecek amount ödemelerin ID'lerini tutacak Set
  bool isLoading = true;
  bool hasChanges = false;
  double totalAmount = 0; // Toplam tutar
  double paidAmount = 0; // Ödenen tutar
  double remainingAmount = 0; // Kalan tutar
  double inputAmount = 0;
  bool isSaving = false;
  bool? isCredit;
  String? errorMessage;
  String selectedPaymentType = 'product';
  late TextEditingController inputController;

  @override
  void initState() {
    super.initState();
    leftList = []; // Başlangıçta sol listeyi boş olarak tanımla
    rightList = []; // Başlangıçta sağ listeyi boş olarak tanımla
    inputController = TextEditingController();
    // Tabloya ait adisyon verilerini yükleyin ve sol listeye ekleyin.
    Future.microtask(() async {
      await ref.read(tablesProvider.notifier).fetchTableBillApi(widget.tableId);
      final initialItems =
          ref.read(tablesProvider).getTableBill(widget.tableId);
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
    });
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hesap',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Masa: ${widget.tableTitle}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            _buildPaymentTypeToggle(),
            _buildPaymentButtons(),
          ],
        ),
      ),
      content: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        width: deviceWidth * 0.7,
        height: deviceHeight * 0.55,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    selectedPaymentType == 'amount'
                        ? _buildAmountInput()
                        : _leftListViewOrders(),
                    _rightListView(),
                  ],
                ),
              ),
      ),
      actions: <Widget>[
        if (errorMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'İptal',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!widget.isSelfService) ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (!hasChanges || isSaving || selectedIndexes.isNotEmpty)
                          ? Colors.grey.shade300
                          : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed:
                    (!hasChanges || isSaving || selectedIndexes.isNotEmpty)
                        ? null
                        : () => _onRegularPayPressed(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.save,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Öde',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (!hasChanges || isSaving || selectedIndexes.isNotEmpty || remainingAmount > 0)
                        ? Colors.grey.shade300
                        : Colors.green.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: (!hasChanges || isSaving || selectedIndexes.isNotEmpty || remainingAmount > 0)
                  ? null
                  : () => _onPayPressed(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.save,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Öde ve Kapat',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            'Ürün Bazlı',
            selectedPaymentType == 'product',
            () => setState(() {
              selectedPaymentType = 'product';
              inputAmount = 0;
            }),
          ),
          const SizedBox(width: 4),
          _buildToggleButton(
            'Tutar Bazlı',
            selectedPaymentType == 'amount',
            () => setState(() {
              selectedPaymentType = 'amount';
              selectedIndexes.clear();
              errorMessage = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
      String label, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.white : Colors.transparent,
        elevation: isSelected ? 1 : 0,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black87 : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPaymentButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPaymentButton(
          icon: Icons.credit_card,
          label: 'Kredi Kartı',
          isSelected: isCredit == true,
          color: Colors.orange,
          onPressed: () => _processSelectedItems(true),
        ),
        const SizedBox(width: 8),
        _buildPaymentButton(
          icon: Icons.payments,
          label: 'Nakit',
          isSelected: isCredit == false,
          color: Colors.green,
          onPressed: () => _processSelectedItems(false),
        ),
      ],
    );
  }

  Widget _buildPaymentButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor:
            isSelected ? color.withOpacity(0.2) : Colors.transparent,
        side: BorderSide(color: isSelected ? color : Colors.grey.shade400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: isSelected ? color : Colors.grey.shade700),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? color : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 50,
            width: 240,
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Ödeme Tutarı',
                labelStyle: TextStyle(color: Colors.grey.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              readOnly: true,
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: inputAmount.toString()),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomNumpad(
              value: remainingAmount,
              onInput: (value) {
                setState(() {
                  inputAmount = double.tryParse(value) ?? 0;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Expanded _rightListView() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green.shade600, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'ÖDENENLER',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                itemCount: rightList.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = rightList[index];
                  return Card(
                    elevation: 0,
                    margin:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    color: Colors.green.shade50,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => _moveItemToLeftList(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: Colors.green.shade600,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '${item.piece ?? 1} adet',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: item.isCredit == true
                                              ? Colors.orange.shade100
                                              : Colors.green.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.isCredit == true
                                              ? 'Kredi Kartı'
                                              : 'Nakit',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: item.isCredit == true
                                                ? Colors.orange.shade800
                                                : Colors.green.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₺${((item.price ?? 0) * (item.piece ?? 1)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow('Toplam Tutar:', totalAmount),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Ödenen Tutar:', paidAmount),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kalan Tutar:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₺${remainingAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: remainingAmount > 0
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded _leftListViewOrders() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      color: Colors.grey.shade700, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'ÖDENECEKLER',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                itemCount: leftList.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = leftList[index];
                  final isSelected = selectedIndexes.contains(index);

                  return Card(
                    elevation: isSelected ? 1 : 0,
                    margin:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(
                        color:
                            isSelected ? Colors.orange : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    color: isSelected ? Colors.orange.shade50 : Colors.white,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedIndexes.remove(index);
                          } else {
                            selectedIndexes.add(index);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.title ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.piece ?? 1} adet',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₺${((item.price ?? 0) * (item.piece ?? 1)).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.orange.shade700
                                        : Colors.black87,
                                  ),
                                ),
                                if (isSelected)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: Colors.orange.shade700,
                                    ),
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
            ),
          ],
        ),
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

    double selectedItemsTotal = selectedIndexes.fold<double>(
      0.0,
      (total, index) => total + (leftList[index].price ?? 0.0),
    );

    if (inputAmount > remainingAmount || selectedItemsTotal > remainingAmount) {
      setState(() {
        errorMessage = 'Hesaptan daha fazla ücret ödeyemezsiniz';
      });
      return;
    }
    List<Menu> itemsToMove = [];
    if (inputAmount != 0) {
      final amount = Menu(
        id: null, // Yeni ödeme olduğu için id null olmalı
        title: isCreditSelected ? 'Kredi' : 'Nakit',
        isCredit: isCreditSelected,
        price: inputAmount,
        status: 'ödendi',
        isAmount: true,
        billId: rightList.isNotEmpty
            ? rightList.first.billId
            : null, // Mevcut billId'yi kullan
      );
      itemsToMove.add(amount);
    }

    // Eğer selectedIndexes boş değilse, listedeki öğeleri ekle
    if (selectedIndexes.isNotEmpty) {
      itemsToMove.addAll(selectedIndexes.map((index) {
        final item = leftList[index];
        return item.copyWith(
          status: 'ödendi', // Status güncelleniyor
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
      // Sağ listeye ekle
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
    setState(() {
      inputAmount = 0.0; // Reset input amount after payment
    });
  }

  Future<void> _onPayPressed(BuildContext context) async {
    if (isSaving) return;

    setState(() => isSaving = true); // Set isSaving at the start

    try {
      final success = await PaymentService.processPayment(
        context: context,
        ref: ref,
        tableId: widget.tableId,
        rightList: rightList,
        amountItemsToDelete: amountItemsToDelete,
        onSavingChanged:
            (_) {}, // Remove this since we're managing state ourselves
      );

      if (success && mounted) {
        // After successful payment, close the bill
        final tablesNotifier = ref.read(tablesProvider.notifier);
        final isClosed = await tablesNotifier.hesabiKapat(widget.tableId);

        if (mounted) {
          if (isClosed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hesap başarıyla kapatıldı!'),
                backgroundColor: Colors.green,
              ),
            );
            // İlk olarak dialog'u kapat
            Navigator.of(context).pop(true);
            if(!widget.isSelfService){
            Navigator.of(context).pop();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hesap kapatılırken bir hata oluştu!'),
                backgroundColor: Colors.red,
              ),
            );

            Navigator.of(context).pop(true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _onRegularPayPressed(BuildContext context) async {
    if (isSaving) return;

    setState(() => isSaving = true);

    try {
      final success = await PaymentService.processPayment(
        context: context,
        ref: ref,
        tableId: widget.tableId,
        rightList: rightList,
        amountItemsToDelete: amountItemsToDelete,
        onSavingChanged: (_) {},
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödeme başarıyla tamamlandı!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _moveItemToLeftList(int index) async {
    if (index >= 0 && index < rightList.length) {
      final item = rightList[index];

      // Tutar bazlı ödemeler için
      if (item.isAmount == true) {
        setState(() {
          rightList.removeAt(index);
          if (item.id != null) {
            amountItemsToDelete.add(item.id!); // ID'yi silme listesine ekle
          }
          _calculateAmounts();
          hasChanges = true;
        });
        return;
      }

      // Normal ürünler için eski davranışı koru
      final updatedItem = item.copyWith(status: 'bekliyor');
      setState(() {
        rightList.removeAt(index);
        leftList.add(updatedItem);
        _calculateAmounts();
        hasChanges = true;
      });
    }
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

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '₺${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

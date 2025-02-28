/* import 'package:foomoons/featured/providers/tables_notifier.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

final _tablesProvider =
    StateNotifierProvider<TablesNotifier, TablesState>((ref) {
  return TablesNotifier(ref);
});

void showAddOrderDialog(
  BuildContext context,
  String tableId,
  List<Menu> orderItems,
  String? qrUrl,
) {
  // Adisyonu fetch etmek için fonksiyonu çağırın
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return _AddOrderDialog(
        tableId: tableId,
        orderItems: orderItems,
        qrUrl: qrUrl,
      );
    },
  );
}

class _AddOrderDialog extends ConsumerStatefulWidget {
  final String tableId;
  final List<Menu> orderItems;
  final String? qrUrl;
  const _AddOrderDialog({
    required this.tableId,
    required this.orderItems,
    required this.qrUrl,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddOrderDialogState();
}

class _AddOrderDialogState extends ConsumerState<_AddOrderDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () {
       /*  ref.read(_tablesProvider.notifier).fetchTableBill(widget.tableId); */
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tablesNotifier = ref.read(_tablesProvider.notifier);
    return AlertDialog(
      title: const Text('Ürün Seç'),
      content: SizedBox(
        width: double.maxFinite,
        child: Row(
          children: [
            // Sol taraf: Ürün listesi
            Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.orderItems.length,
                      itemBuilder: (BuildContext context, int index) {
                        final item = widget.orderItems[index];
                        return ListTile(
                          title: Text(item.title ?? ''),
                          subtitle: Text(
                              '${item.price ?? 0} TL'), // Fiyat null ise 0 olarak göster
                          onTap: () {
                            // Ürün seçimi işlemi
                            // Ürünü masanın adisyonuna ekle
                            tablesNotifier.addItemToBill(widget.tableId, item);
                          },
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

            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final tableBill = ref.watch(_tablesProvider
                      .select((state) => state.getTableBill(widget.tableId)));
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adisyon',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: tableBill.length,
                          itemBuilder: (BuildContext context, int index) {
                            final item = tableBill[index];
                            return ListTile(
                              title: Text(item.title ?? ''),
                              subtitle: Text(
                                  '${item.price ?? 0} TL'), // Fiyat null ise 0 olarak göster
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  // Adisyondan ürünü çıkarma işlemi
                                  // tablesNotifier.removeItemFromBill(
                                  //     widget.tableId, item.id!);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Toplam: ${tableBill.fold(0, (sum, item) => sum + (item.price ?? 0))} TL', // Fiyat null ise 0 olarak topla
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Kapat'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
 */
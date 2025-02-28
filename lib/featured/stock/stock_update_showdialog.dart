import 'package:flutter/material.dart';
import 'package:foomoons/featured/providers/menu_notifier.dart';

void stockUpdateShowDialog(
    BuildContext context, MenuNotifier menuNotifier, String productId) {
  final existingProduct = menuNotifier.getProductById(productId);

  final TextEditingController controller =
      TextEditingController(text: existingProduct?.stock.toString());
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Güncelle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Sayı'),
                
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final stockValue = int.tryParse(controller.text);

              // Update only stock value while keeping other fields unchanged
              menuNotifier.updateProductStock(productId, stockValue, context);
              Navigator.of(context).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      );
    },
  );
}

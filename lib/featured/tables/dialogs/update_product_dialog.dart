// import 'package:flutter/material.dart';
// import 'package:altmisdokuzapp/product/model/category.dart';
// import 'package:altmisdokuzapp/product/model/menu.dart';
// import 'package:altmisdokuzapp/featured/providers/menu_notifier.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// final _menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
//   return MenuNotifier(ref);
// });

// class UpdateProductDialog extends ConsumerStatefulWidget {
//   final List<Category> categories;
//   final String productId;
//   final Menu existingProduct;

//   const UpdateProductDialog({
//     Key? key,
//     required this.categories,
//     required this.productId,
//     required this.existingProduct,
//   }) : super(key: key);

//   @override
//   _UpdateProductDialogState createState() => _UpdateProductDialogState();
// }

// class _UpdateProductDialogState extends ConsumerState<UpdateProductDialog> {
//   late TextEditingController titleController;
//   late TextEditingController priceController;
//   late TextEditingController prepTimeController;
//   late TextEditingController categoryController;
//   late TextEditingController stockController;

//   @override
//   void initState() {
//     super.initState();

//     // Mevcut ürünü dolduruyoruz
//     final initialPrepTimeInMinutes =
//         (widget.existingProduct.preparationTime ?? 0) / 60;
//     titleController = TextEditingController(text: widget.existingProduct.title);
//     priceController =
//         TextEditingController(text: widget.existingProduct.price?.toString());
//     prepTimeController = TextEditingController(
//         text: initialPrepTimeInMinutes.toStringAsFixed(0));
//     categoryController =
//         TextEditingController(text: widget.existingProduct.category);
//     stockController = TextEditingController(
//         text: widget.existingProduct.stock?.toString() ?? 'Stok Girişi Yok');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final menuState = ref.watch(_menuProvider);
//     final menuNotifier = ref.read(_menuProvider.notifier);

//     // Listen for photoURL changes and update UI
//     ref.listen<MenuState>(_menuProvider, (previous, next) {
//       if (previous?.photoURL != next.photoURL) {
//         setState(() {}); // photoURL değiştiğinde UI'ı güncelle
//       }
//     });

//     return 
//   }
// }

// void showUpdateProductDialog(
//   BuildContext context,
//   List<Category> categories,
//   String productId,
//   Menu item,
// ) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//       title: const Text('Ürün Güncelle'),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: <Widget>[
//             GestureDetector(
//               onTap: () async {
//                 await menuNotifier.pickAndUploadImage();
//               },
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   CircleAvatar(
//                     radius: 100,
//                     backgroundImage: (menuState.photoURL != null &&
//                             menuState.photoURL!.isNotEmpty)
//                         ? NetworkImage(menuState.photoURL!)
//                         : (widget.existingProduct.image != null
//                             ? NetworkImage(widget.existingProduct.image!)
//                             : const AssetImage(
//                                     'assets/images/food_placeholder.png')
//                                 as ImageProvider),
//                   ),
//                   if (menuState.isUploading)
//                     const CircularProgressIndicator(
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                 ],
//               ),
//             ),
//             TextField(
//               controller: titleController,
//               decoration: const InputDecoration(labelText: 'Ürün İsmi'),
//             ),
//             TextField(
//               controller: priceController,
//               decoration: const InputDecoration(labelText: 'Ürün Fiyatı'),
//               keyboardType: TextInputType.number,
//             ),
//             TextField(
//               controller: prepTimeController,
//               decoration: const InputDecoration(
//                   labelText: 'Ürün Min Hazırlanma Süresi'),
//               keyboardType: TextInputType.number,
//             ),
//             TextField(
//               controller: stockController,
//               decoration: const InputDecoration(labelText: 'Stok'),
//               keyboardType: TextInputType.number,
//             ),
//             DropdownButtonFormField<String>(
//               decoration: const InputDecoration(labelText: 'Ürün Kategorisi'),
//               items: widget.categories.map((category) {
//                 return DropdownMenuItem<String>(
//                   value: category.name,
//                   child: Text(category.name ?? ''),
//                 );
//               }).toList(),
//               value: widget.existingProduct.category,
//               onChanged: (value) {
//                 categoryController.text = value ?? '';
//               },
//             ),
//           ],
//         ),
//       ),
//       actions: <Widget>[
//         TextButton(
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//           child: const Text('İptal'),
//         ),
//         ElevatedButton(
//           onPressed: menuState.isUploading
//               ? null // Eğer hala resim yükleniyorsa butonu devre dışı bırak
//               : () async {
//                   final updatedProduct = Menu(
//                     title: titleController.text,
//                     price: int.tryParse(priceController.text),
//                     image: menuState.photoURL,
//                     preparationTime:
//                         int.tryParse(prepTimeController.text)! * 60,
//                     category: categoryController.text,
//                     stock: int.tryParse(stockController.text),
//                   );
//                   await menuNotifier.updateProduct(
//                       widget.productId, updatedProduct, context);
//                   Navigator.of(context).pop();
//                 },
//           child: const Text('Kaydet'),
//         ),
//       ],
//     );
//     },
//   );
// }

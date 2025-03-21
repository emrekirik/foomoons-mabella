import 'package:foomoons/featured/providers/menu_notifier.dart';
import 'package:foomoons/featured/tables/dialogs/add_category_bottomsheet.dart';
import 'package:foomoons/product/constants/color_constants.dart';
import 'package:foomoons/product/model/category.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

/// MenuView Widget
class MenuMobileView extends ConsumerStatefulWidget {
  final String? successMessage;
  const MenuMobileView({this.successMessage, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MenuMobileViewState();
}

class _MenuMobileViewState extends ConsumerState<MenuMobileView> {
  int selected = 0;
  late TextEditingController searchContoller;
  late TextEditingController titleController;
  late TextEditingController priceController;
  late TextEditingController prepTimeController;
  late TextEditingController categoryController;
  String searchQuery = '';
  bool isUploading = false;
  String? orderType;
  String? imageUrl;

  void _showTopSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          right: 20,
          left: 20,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    searchContoller = TextEditingController();
    titleController = TextEditingController();
    priceController = TextEditingController();
    prepTimeController = TextEditingController();
    categoryController = TextEditingController();

    // Sadece state boşsa veri yükle
    Future.microtask(() {
      final menuState = ref.read(menuProvider);
      if (menuState.products == null || menuState.categories == null) {
        ref.read(menuProvider.notifier).fetchAndLoad();
      }
/*       if (selected == 0) {
        ref
            .read(menuProvider.notifier)
            .selectCategory(MenuNotifier.allCategories);
      } */
    });
  }

  @override
  void dispose() {
    super.dispose();
    searchContoller.dispose();
    titleController.dispose();
    priceController.dispose();
    prepTimeController.dispose();
    categoryController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider).isLoading('menu');
    final menuNotifier = ref.watch(menuProvider.notifier);
    final menuState = ref.watch(menuProvider);
    final productItem = menuState.products ?? [];
    final categories = menuState.categories ?? [];
    /* final selectedCategory = menuState.selectedValue; */

    // Filter items based on the search query
    final filteredItems = productItem.where((item) {
      if (searchQuery.isNotEmpty) {
        return item.title!.toLowerCase().contains(searchQuery.toLowerCase());
      }
      /* final isCategoryMatch = selectedCategory == null ||
              selectedCategory == MenuNotifier.allCategories
          ? true
          : item.category == selectedCategory;
      return isCategoryMatch; */
      return true;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextField(
                        autofocus: false,
                        controller: searchContoller,
                        decoration: InputDecoration(
                          hintText: 'Ürün ara...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: 22,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.orange,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: GoogleFonts.poppins(fontSize: 14),
                        onChanged: (query) {
                          setState(() {
                            searchQuery = query;
                          });
                        },
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (String value) {
                        switch (value) {
                          case 'Kategori Ekle':
                            addCategoryBottomSheet(context, menuNotifier);
                            break;
                          case 'Ürün Ekle':
                            _addProductDialog(
                              context,
                              isUploading,
                              categories,
                              menuNotifier,
                            );
                            setState(() {});
                            break;
                          default:
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem<String>(
                            value: 'Kategori Ekle',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Kategori Ekle',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'Ürün Ekle',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ürün Ekle',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: ColorConstants.tablePageBackgroundColor,
                  ),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (constraints.maxWidth / 130).floor(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return isLoading
                          ? _buildShimmerItem()
                          : MenuItem(item: item);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<dynamic> _addProductDialog(BuildContext context, bool isUploading,
      List<Category> categories, MenuNotifier menuNotifier) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ürün Ekle',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              setState(() {
                                isUploading = true;
                              });
                              try {
                                final url = await ref.read(menuProvider.notifier).pickImage();
                                setState(() {
                                  imageUrl = url;
                                  isUploading = false;
                                });
                              } catch (e) {
                                setState(() {
                                  isUploading = false;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Resim yükleme hatası: $e')),
                                  );
                                }
                              }
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(75),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(75),
                                    child: imageUrl != null
                                        ? Image.network(
                                            imageUrl!,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(
                                            Icons.add_a_photo_outlined,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                  ),
                                ),
                                if (isUploading)
                                  const CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Ürün İsmi',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'Ürün ismini girin',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.orange[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Ürün Fiyatı',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Ürün fiyatını girin',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.orange[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Kategori',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            icon: Icon(Icons.arrow_drop_down,
                                color: Colors.grey[600]),
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            menuMaxHeight: 200,
                            hint: Text(
                              'Kategori seçin',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            items: categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.title,
                                child: Text(
                                  category.title ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              categoryController.text = value ?? '';
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Sipariş Tipi',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            icon: Icon(Icons.arrow_drop_down,
                                color: Colors.grey[600]),
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            menuMaxHeight: 200,
                            hint: Text(
                              'Sipariş tipi seçin',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            items: ['Mutfak', 'Bar',].map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  type,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                orderType = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'İptal',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isUploading
                                    ? null
                                    : () async {
                                        if (titleController.text.isEmpty ||
                                            priceController.text.isEmpty ||
                                            categoryController.text.isEmpty) {
                                          _showTopSnackBar(
                                            context,
                                            'Lütfen tüm alanları doldurun',
                                          );
                                          return;
                                        }

                                        final newProduct = Menu(
                                          title: titleController.text,
                                          price: double.tryParse(
                                                  priceController.text) ??
                                              0.0,
                                          image: imageUrl,
                                          category: categoryController.text,
                                          orderType: orderType,
                                        );

                                        await menuNotifier
                                            .addProduct(newProduct);
                                        Navigator.of(context).pop();
                                      },
                                child: Text(
                                  'Kaydet',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Container(
                height: 14,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  const MenuItem({
    super.key,
    required this.item,
  });

  final Menu item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
              child: item.image != null && item.image!.startsWith('http')
                  ? FadeInImage.assetNetwork(
                      placeholder: 'assets/images/food_placeholder.png',
                      image: item.image!,
                      width: double.infinity,
                      height: 130,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/food_placeholder.png',
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'assets/images/food_placeholder.png',
                      width: double.infinity,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            child: Text(
              item.title ?? '',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Text(
              item.price != null ? '${item.price} ₺' : 'Fiyat Yok',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

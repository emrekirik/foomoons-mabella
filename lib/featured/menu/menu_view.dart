import 'package:foomoons/featured/providers/menu_notifier.dart';
import 'package:foomoons/featured/menu/add_category_dialog.dart';
import 'package:foomoons/product/constants/color_constants.dart';
import 'package:foomoons/product/model/category.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

/// MenuView Widget
class MenuView extends ConsumerStatefulWidget {
  final String? successMessage;
  const MenuView({this.successMessage, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MenuViewState();
}

class _MenuViewState extends ConsumerState<MenuView> {
  int selected = -1;
  late TextEditingController searchContoller;
  String searchQuery = '';
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    searchContoller = TextEditingController();
    _fetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchData();
  }

  void _fetchData() {
    Future.microtask(() {
      if (mounted) {
        final menuState = ref.read(menuProvider);
        if (menuState.products == null || menuState.categories == null) {
          ref.read(menuProvider.notifier).fetchAndLoad();
        }
        if (menuState.categories != null && menuState.categories!.isNotEmpty) {
          setState(() {
            selected = 0;
          });
          ref.read(menuProvider.notifier).selectCategory(menuState.categories![0].title);
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    searchContoller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);
    final isLoading = ref.watch(loadingProvider).isLoading('menu');
    final menuNotifier = ref.watch(menuProvider.notifier);
    final productItem = menuState.products ?? [];
    final categories = menuState.categories ?? [];
    final selectedCategory = menuState.selectedValue;
    double deviceWidth = MediaQuery.of(context).size.width;

    // Filter items based on the search query
    final filteredItems = productItem.where((item) {
      if (searchQuery.isNotEmpty) {
        return item.title!.toLowerCase().contains(searchQuery.toLowerCase());
      }
      final isCategoryMatch = selectedCategory == null ? true : item.category == selectedCategory;
      return isCategoryMatch;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: ColorConstants.white,
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                searchQuery.isNotEmpty || deviceWidth < 600
                    ? const SizedBox()
                    : Container(
                        width: 200,
                        height: double.infinity,
                        decoration:const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          color: Colors.white,
                          border: Border(
                            right: BorderSide(
                              color: Colors.black12,
                              width: 1,
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                scrollDirection: Axis.vertical,
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: selected == index
                                            ? const BorderSide(
                                                color: Colors.orange,
                                                width: 5)
                                            : const BorderSide(
                                                color: Colors.black12,
                                                width: 1,
                                              ),
                                      ),
                                    ),
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        overlayColor: Colors.grey[200],
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          selected = index;
                                        });
                                        menuNotifier
                                            .selectCategory(category.title);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: Text(
                                          category.title ?? '',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: selected == index
                                                ? Colors.orange
                                                : ColorConstants.black,
                                            fontWeight: selected == index
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 45,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(12),
                          ),
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.black12,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: deviceWidth < 750 ? 200 : 400,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0),
                                child: TextField(
                                  controller: searchContoller,
                                  decoration: InputDecoration(
                                    hintText: 'Ara...',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.grey[500],
                                      size: 22,
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.orange,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onChanged: (query) {
                                    setState(() {
                                      searchQuery = query;
                                    });
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: PopupMenuButton<String>(
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
                                      addCategoryDialog(context, menuNotifier);
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
                                            style: GoogleFonts.poppins(
                                                fontSize: 14),
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
                                            style: GoogleFonts.poppins(
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: ColorConstants.tablePageBackgroundColor,
                          ),
                          child: GridView.builder(
                            padding: const EdgeInsets.all(10),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  (constraints.maxWidth / 140).floor(),
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.85,
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
                ),
              ],
            ),
          ),
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

  Future<dynamic> _addProductDialog(BuildContext context, bool isUploading,
      List<Category> categories, MenuNotifier menuNotifier) {
    TextEditingController titleController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    TextEditingController categoryController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 600,
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
                          'Ürün Ekle',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
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
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ürün İsmi',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Ürün ismini girin',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey[200]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey[200]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.black,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ürün Fiyatı',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ürün fiyatını girin',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey[200]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey[200]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.black,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kategori',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[200]!,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        menuMaxHeight: 200,
                        hint: Text(
                          'Kategori seçin',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
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
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'İptal',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: isUploading
                              ? null
                              : () async {
                                  if (titleController.text.isEmpty ||
                                      priceController.text.isEmpty ||
                                      categoryController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Lütfen tüm alanları doldurun'),
                                      ),
                                    );
                                    return;
                                  }

                                  final newProduct = Menu(
                                    title: titleController.text,
                                    price: double.tryParse(priceController.text),
                                    image: ref.watch(menuProvider).photoURL,
                                    category: categoryController.text,
                                  );

                                  await menuNotifier.addProduct(newProduct);
                                  Navigator.of(context).pop();
                                },
                          child: Text(
                            'Kaydet',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
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
        );
      },
    );
  }
}

class MenuItem extends ConsumerWidget {
  const MenuItem({
    super.key,
    required this.item,
  });

  final Menu item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
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
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/images/food_placeholder.png',
                      image: item.image ?? 'assets/images/food_placeholder.png',
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
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                final titleController = TextEditingController(text: item.title);
                                final priceController = TextEditingController(text: item.price?.toString());
                                final categoryController = TextEditingController(text: item.category);
                                final stockController = TextEditingController(text: item.stock?.toString() ?? '0');

                                return Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Container(
                                    width: 500,
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
                                              'Ürün Düzenle',
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
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        _buildTextField(
                                          controller: titleController,
                                          label: 'Ürün Adı',
                                          hint: 'Ürün adını girin',
                                        ),
                                        const SizedBox(height: 16),
                                        _buildTextField(
                                          controller: priceController,
                                          label: 'Fiyat',
                                          hint: 'Ürün fiyatını girin',
                                          keyboardType: TextInputType.number,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Kategori',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.grey[200]!,
                                            ),
                                          ),
                                          child: DropdownButtonFormField<String>(
                                            value: item.category,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                            ),
                                            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
                                            isExpanded: true,
                                            dropdownColor: Colors.white,
                                            menuMaxHeight: 200,
                                            hint: Text(
                                              'Kategori seçin',
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey[400],
                                                fontSize: 14,
                                              ),
                                            ),
                                            items: ref.watch(menuProvider).categories?.map((category) {
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
                                        const SizedBox(height: 16),
                                        _buildTextField(
                                          controller: stockController,
                                          label: 'Stok',
                                          hint: 'Ürün stok miktarını girin',
                                          keyboardType: TextInputType.number,
                                        ),
                                        const SizedBox(height: 32),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () async {
                                                // Show confirmation dialog
                                                final shouldDelete = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: Text(
                                                      'Ürünü Sil',
                                                      style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    content: Text(
                                                      'Bu ürünü silmek istediğinizden emin misiniz?',
                                                      style: GoogleFonts.poppins(),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, false),
                                                        child: Text(
                                                          'İptal',
                                                          style: GoogleFonts.poppins(),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, true),
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: Colors.red,
                                                        ),
                                                        child: Text(
                                                          'Sil',
                                                          style: GoogleFonts.poppins(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (shouldDelete == true && item.id != null) {
                                                  try {
                                                    await ref.read(menuProvider.notifier).deleteProduct(item.id!, context);
                                                    if (context.mounted) {
                                                      Navigator.of(context).pop(); // Close the edit dialog
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Ürün silinirken hata oluştu: $e')),
                                                      );
                                                    }
                                                  }
                                                }
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: Text(
                                                'Sil',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
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
                                              onPressed: () async {
                                                try {
                                                  final updatedProduct = Menu(
                                                    id: item.id,
                                                    title: titleController.text,
                                                    price: double.tryParse(priceController.text),
                                                    category: categoryController.text,
                                                    stock: int.tryParse(stockController.text),
                                                    image: item.image,
                                                    status: item.status,
                                                  );

                                                  await ref.read(menuProvider.notifier).updateProduct(updatedProduct, context);
                                                  if (context.mounted) {
                                                    Navigator.of(context).pop();
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Güncelleme hatası: $e')),
                                                    );
                                                  }
                                                }
                                              },
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
                                              child: Text(
                                                'Kaydet',
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
                            );
                          },
                          child: Center(
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                item.title ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                item.price != null ? '${item.price} ₺' : 'Fiyat Yok',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[400],
            ),
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
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
                color: Colors.black,
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
      ],
    );
  }
}

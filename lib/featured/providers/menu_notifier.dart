import 'package:foomoons/product/model/category.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:foomoons/product/model/table.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/product/utility/firebase/user_firestore_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class MenuNotifier extends StateNotifier<MenuState> {
  static const String allCategories = 'Tüm Kategoriler';
  final UserFirestoreHelper _firestoreHelper = UserFirestoreHelper();
  final Ref ref;
  final ImagePicker _picker = ImagePicker();
  DateTime? _lastFetchTime;
  static const _cacheValidityDuration = Duration(minutes: 30);
  
  MenuNotifier(this.ref) : super(const MenuState());

  Future<void> fetchAndLoad() async {
    // Cache kontrolü
    if (_lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration &&
        state.products != null &&
        state.categories != null) {
      print('🔄 Menu cache geçerli, veriler yüklü. Fetch atlanıyor.');
      return;
    }

    print('📥 Menu verileri fetch ediliyor...');
    ref.read(loadingProvider.notifier).setLoading('menu', true);
    try {
      await Future.wait([
        fetchProducts(),
        fetchCategories(),
      ]);
      _lastFetchTime = DateTime.now();
      print('✅ Menu verileri başarıyla yüklendi ve cache güncellendi.');
    } catch (e) {
      print('❌ Menu veri yükleme hatası: $e');
      _lastFetchTime = null;
    } finally {
      ref.read(loadingProvider.notifier).setLoading('menu', false);
    }
  }

  Future<void> fetchProducts() async {
    final productService = ref.read(productServiceProvider);
    final products = await productService.fetchProducts();
    state = state.copyWith(products: products);
  }

  Future<void> fetchCategories() async {
    final categoryService = ref.read(categoryServiceProvider);
    final categories = await categoryService.fetchCategories();
    state = state.copyWith(categories: categories);
  }

  Future<void> addCategory(Category category) async {
    final categoryService = ref.read(categoryServiceProvider);
    final newCategory = await categoryService.addCategory(category);
    state = state.copyWith(categories: [...?state.categories, newCategory]);
  }

  Future<void> updateCategory(Category category, String oldTitle, BuildContext context) async {
    try {
      final categoryService = ref.read(categoryServiceProvider);
      final productService = ref.read(productServiceProvider);
      
      // Update the category
      final updatedCategory = await categoryService.updateCategory(category);
      
      // Update the categories list
      final updatedCategories = state.categories?.map((c) {
        return c.id == category.id ? updatedCategory : c;
      }).toList();
      
      // Update all products that belong to this category
      final updatedProducts = state.products?.map((product) async {
        if (product.category == oldTitle) {
          final updatedProduct = product.copyWith(category: updatedCategory.title);
          return await productService.updateProduct(updatedProduct);
        }
        return product;
      }).toList();

      // If the updated category was selected, update the selected value
      final newSelectedValue = state.selectedValue == oldTitle 
          ? updatedCategory.title 
          : state.selectedValue;

      if (updatedProducts != null) {
        final products = await Future.wait(updatedProducts);
        state = state.copyWith(
          categories: updatedCategories,
          products: products,
          selectedValue: newSelectedValue,
        );
      } else {
        state = state.copyWith(
          categories: updatedCategories,
          selectedValue: newSelectedValue,
        );
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori başarıyla güncellendi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kategori güncellenirken hata oluştu: $e')),
        );
      }
      _handleError(e, 'Kategori güncelleme hatası');
    }
  }

  Future<void> deleteCategory(Category category, BuildContext context) async {
    try {
      final categoryService = ref.read(categoryServiceProvider);
      final productService = ref.read(productServiceProvider);

      // Delete all products in this category first
      if (state.products != null) {
        final productsToDelete = state.products!.where((p) => p.category == category.title).toList();
        for (var product in productsToDelete) {
          if (product.id != null) {
            await productService.deleteProduct(product.id!);
          }
        }
      }

      // Then delete the category
      if (category.id != null) {
        await categoryService.deleteCategory(category.id!);
      }

      // Update state
      final updatedCategories = state.categories?.where((c) => c.id != category.id).toList();
      final updatedProducts = state.products?.where((p) => p.category != category.title).toList();

      // Reset selected value if the deleted category was selected
      final newSelectedValue = state.selectedValue == category.title ? null : state.selectedValue;

      state = state.copyWith(
        categories: updatedCategories,
        products: updatedProducts,
        selectedValue: newSelectedValue,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori ve ilgili ürünler başarıyla silindi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kategori silinirken hata oluştu: $e')),
        );
      }
      _handleError(e, 'Kategori silme hatası');
    }
  }

  Future<void> addProduct(Menu newProduct) async {
    try {
      final productService = ref.read(productServiceProvider);
      final addedProduct = await productService.addProduct(newProduct);
      // Backend'den gelen güncel veriyi kullanarak state'i güncelle
      if (addedProduct.title != null && addedProduct.price != null) {
        state = state.copyWith(
          products: [...?state.products, addedProduct],
        );
      } else {
        throw Exception('Backend\'den gelen ürün verisi eksik');
      }
    } catch (e) {
      _handleError(e, 'Ürün ekleme hatası');
    }
  }

  Future<void> updateProduct(Menu product, BuildContext context) async {
    try {
      final productService = ref.read(productServiceProvider);
      final updatedProduct = await productService.updateProduct(product);
      
      // Update the products list with the updated product
      final updatedProducts = state.products?.map((p) {
        return p.id == updatedProduct.id ? updatedProduct : p;
      }).toList();
      
      state = state.copyWith(products: updatedProducts);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün başarıyla güncellendi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün güncellenirken hata oluştu: $e')),
        );
      }
      _handleError(e, 'Ürün güncelleme hatası');
    }
  }

  Future<void> deleteProduct(int productId, BuildContext context) async {
    try {
      final productService = ref.read(productServiceProvider);
      final deleted = await productService.deleteProduct(productId);

      if (deleted) {
        // Başarılı silme durumunda state'i güncelle
        state = state.copyWith(
          products: state.products?.where((product) => product.id != productId).toList(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ürün başarıyla silindi')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ürün silinirken bir hata oluştu')),
          );
        }
      }
    } catch (e) {
      print('❌ Ürün silme hatası: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün silinirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserDetails() async {
    final currentUser = _firestoreHelper.currentUser;
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    // Kullanıcının Firestore belgesini al
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!userDoc.exists) {
      throw Exception('Kullanıcı bulunamadı');
    }

    return userDoc.data();
  }

  // stock güncelleme işlemi
  Future<void> updateProductStock(
      String productId, int? updatedStock, BuildContext context) async {
    try {
      final productDocument =
          _firestoreHelper.getUserDocument('products', productId);

      // Fetch existing product data
      final productSnapshot = await productDocument.get();
      final existingData = productSnapshot.data();

      if (existingData != null) {
        // Update only the stock field
        final updatedData = {
          'stock': updatedStock,
        };

        // Update only the stock field in Firestore
        await productDocument.update(updatedData);
        await fetchProducts(); // Refresh products after update

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ürün stoğu başarıyla güncellendi')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _handleError(e, 'Ürünü güncelleme hatası');
      }
    }
  }

  Menu? getProductById(String productId) {
    return state.products?.firstWhere(
      (product) => product.id == productId,
      orElse: () =>
          const Menu(), // Return a default `Menu` object instead of `null`
    );
  }

  // Web ortamı için resim seçip yükleme işlemi
  Future<void> pickAndUploadImage() async {
    try {
      // Oturum açmış olan kullanıcıyı alıyoruz
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      // Galeriden bir resim seçiyoruz
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // Yükleme işlemine başlıyoruz
        state = state.copyWith(isUploading: true);

        // Seçilen dosya File değil, XFile olduğu için web'de direkt XFile'dan yükleme yapıyoruz
        final String fileName =
            'product_pictures/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Firebase Storage'a dosyayı yüklüyoruz
        UploadTask uploadTask = FirebaseStorage.instance
            .ref()
            .child(fileName)
            .putData(await pickedFile
                .readAsBytes()); // Web'de readAsBytes() kullanıyoruz

        TaskSnapshot snapshot = await uploadTask;
        String downloadURL = await snapshot.ref.getDownloadURL();

        // Firestore'da profil resmi URL'sini güncelle
        await updateProfilePhotoURL(downloadURL, currentUser.uid);
      }
    } catch (e, stackTrace) {
      print('Fotoğraf seçilirken hata oluştu: $e');
      print('Hata Yığını: $stackTrace');
    } finally {
      // Yükleme tamamlandı, durumu güncelle
      state = state.copyWith(isUploading: false);
    }
  }

  Future<void> updateProfilePhotoURL(String photoURL, String userId) async {
    try {
      final documentRef =
          FirebaseFirestore.instance.collection('productImage').doc(userId);

      final docSnapshot = await documentRef.get();

      if (docSnapshot.exists) {
        // Eğer belge mevcutsa, photoURL'yi güncelle
        await documentRef.update({
          'photoURL': photoURL,
        });
      } else {
        // Eğer belge yoksa, photoURL ile yeni bir belge oluştur
        await documentRef.set({
          'photoURL': photoURL,
        });
      }

      // Lokal durumu güncelle
      state = state.copyWith(photoURL: photoURL);
    } catch (e) {
      print('Profil fotoğrafı güncellenirken hata oluştu: $e');
    }
  }

  /// Seçili kategoriyi günceller
  void selectCategory(String? categoryName) {
    state = state.copyWith(selectedValue: categoryName);
  }

  /// Hata yönetimi
  void _handleError(Object e, String message) {
    print(
        '$message: $e'); // Hataları loglayın veya bir hata yönetimi mekanizması kullanın
  }

  void resetState() {
    state = const MenuState(); // Reset to the initial state
  }

  void resetPhotoUrl() {
    state = state.copyWith(photoURL: null);
  }

  void invalidateCache() {
    _lastFetchTime = null;
  }
}

class MenuState extends Equatable {
  const MenuState(
      {this.products,
      this.categories,
      this.selectedValue,
      this.tables,
      this.tableBills = const {},
      this.stockWarning,
      this.isUploading = false,
      this.photoURL});

  final List<Menu>? products;
  final List<Category>? categories;
  final String? selectedValue;
  final List<CoffeTable>? tables;
  final Map<int, List<Menu>> tableBills;
  final String? stockWarning;
  final bool isUploading;
  final String? photoURL;

  @override
  List<Object?> get props => [
        products,
        categories,
        selectedValue,
        tables,
        tableBills,
        stockWarning,
        isUploading,
        photoURL
      ];

  MenuState copyWith({
    List<Menu>? products,
    List<Category>? categories,
    String? selectedValue,
    List<CoffeTable>? tables,
    Map<int, List<Menu>>? tableBills,
    String? stockWarning,
    bool? isUploading,
    String? photoURL,
  }) {
    return MenuState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedValue: selectedValue ?? this.selectedValue,
      tables: tables ?? this.tables,
      tableBills: tableBills ?? this.tableBills,
      stockWarning: stockWarning ?? this.stockWarning,
      isUploading: isUploading ?? this.isUploading,
      photoURL: photoURL ?? this.photoURL,
    );
  }
}

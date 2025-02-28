import 'dart:convert';

import 'package:foomoons/product/init/config/app_environment.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:foomoons/product/services/auth_service.dart';
import 'package:http/http.dart' as http;

class ProductService {
  final String baseUrl = AppEnvironmentItems.baseUrl.value;
  final AuthService _authService;

  ProductService({required AuthService authService}) : _authService = authService;

  Future<List<Menu>> fetchProducts() async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      final response = await http.post(
        Uri.parse('$baseUrl/Products/getbybusinessid?id=$businessId'),
        headers: {'accept': '*/*'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> productList = data['data'];
        return productList.map((json) => Menu.fromJson(json)).toList();
      } else {
        throw Exception(
            'Ürünleri getirirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ürünleri getirirken hata oluştu: $e');
    }
  }

  Future<Menu> addProduct(Menu newProduct) async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      final url = Uri.parse('$baseUrl/products/add');
      final body = jsonEncode({
        'category': newProduct.category,
        'image': newProduct.image ?? 'assets/images/food_placeholder.png',
        'price': newProduct.price ?? 0.0,
        'preparationTime':
            "2024-12-21T00:59:39.252Z", // backend'de null olamaz verilmiş
        'status': newProduct.status,
        'stock': 0, // backend'de null olamaz verilmiş
        'title': newProduct.title,
        'businessId': businessId
      });

      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'}, body: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        return Menu.fromJson(data);
      } else {
        throw Exception('Ürün eklerken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ürün eklerken hata oluştu: $e');
    }
  }

  Future<Menu> updateProduct(Menu product) async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      final url = Uri.parse('$baseUrl/products/update');
      final body = jsonEncode({
        'id' : product.id,
        'category': product.category,
        'image': product.image ?? 'assets/images/food_placeholder.png',
        'price': product.price ?? 0.0,
        'preparationTime': "2024-12-21T00:59:39.252Z", // backend'de null olamaz verilmiş
        'status': product.status,
        'stock': product.stock ?? 0,
        'title': product.title,
        'businessId': businessId
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return Menu.fromJson(data);
      } else {
        throw Exception('Ürün güncellenirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ürün güncellenirken hata oluştu: $e');
    }
  }

  Future<bool> deleteProduct(int productId) async {
    try {
      print('🗑️ Ürün siliniyor (ID: $productId)...');
      final response = await http.post(
        Uri.parse('$baseUrl/products/deletebyid?id=$productId'),
        headers: {'accept': '*/*'},
      );

      if (response.statusCode != 200) {
        print('❌ Ürün silinemedi (Status: ${response.statusCode})');
        return false;
      }

      print('✅ Ürün başarıyla silindi');
      return true;
    } catch (e) {
      print('❌ HATA: Ürün silinirken bir sorun oluştu:');
      print('❌ $e');
      return false;
    }
  }
}

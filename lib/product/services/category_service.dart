import 'dart:convert';
import 'package:foomoons/product/init/config/app_environment.dart';
import 'package:foomoons/product/model/category.dart';
import 'package:foomoons/product/services/auth_service.dart';
import 'package:http/http.dart' as http;

class CategoryService {
  final String baseUrl = AppEnvironmentItems.baseUrl.value;
  final AuthService _authService;

  CategoryService({required AuthService authService}) : _authService = authService;

  Future<List<Category>> fetchCategories() async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      final response = await http.post(
        Uri.parse('$baseUrl/Categories/getbybusinessid?id=$businessId'),
        headers: {'accept': '*/*'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> categoryList = data['data'];
        return categoryList.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception(
            'Kategorileri getirirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kategorileri getirirken hata oluştu: $e');
    }
  }

  Future<Category> addCategory(Category category) async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      final url = Uri.parse('$baseUrl/categories/add');
      final body = jsonEncode({
        'title': category.title,
        'businessId': businessId,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return Category.fromJson(data);
      } else {
        throw Exception(
            'Kategori eklerken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kategori eklerken hata oluştu: $e');
    }
  }

  Future<Category> updateCategory(Category category) async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      final url = Uri.parse('$baseUrl/Categories/update');
      final body = jsonEncode({
        'id': category.id,
        'title': category.title,
        'businessId': businessId,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return Category.fromJson(data);
      } else {
        throw Exception(
            'Kategori güncellenirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kategori güncellenirken hata oluştu: $e');
    }
  }

  Future<bool> deleteCategory(int categoryId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Categories/deletebyid?id=$categoryId'),
        headers: {'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Kategori silinirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kategori silinirken hata oluştu: $e');
    }
  }
}

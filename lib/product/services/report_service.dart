import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:foomoons/product/init/config/app_environment.dart';
import 'package:foomoons/product/services/auth_service.dart';

class ReportService {
  final String baseUrl = AppEnvironmentItems.baseUrl.value;
  final AuthService _authService;

  ReportService({required AuthService authService}) : _authService = authService;

  Future<List<dynamic>> fetchPastBillItems() async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      final response = await http.get(
        Uri.parse('$baseUrl/PastBillItems/getbybusinessid?id=$businessId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'];
        return data;
      } else {
        throw Exception('Failed to load past bill items');
      }
    } catch (e) {
      throw Exception('API\'den geçmiş fatura öğelerini çekerken hata oluştu: $e');
    }
  }

 /*  Future<Map<String, dynamic>> fetchEmployees() async {
    try {
      print('🔄 Çalışanlar için API isteği başlatılıyor...');
      final response = await http.get(
        Uri.parse('$baseUrl/users/getall'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('✅ Çalışanlar API yanıtı başarılı (200 OK)');
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'];
        print('📦 API\'den gelen çalışan sayısı: ${data.length}');
        return responseData;
      } else {
        print('❌ Çalışanlar API yanıtı başarısız (${response.statusCode})');
        print('   Yanıt: ${response.body}');
        throw Exception('Failed to load employees');
      }
    } catch (e) {
      print('❌ Çalışanlar için hata oluştu: $e');
      throw Exception('Çalışanları getirme hatası: $e');
    }
  } */
} 
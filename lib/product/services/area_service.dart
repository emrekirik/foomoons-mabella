import 'dart:convert';
import 'package:foomoons/product/init/config/app_environment.dart';
import 'package:foomoons/product/model/area.dart';
import 'package:foomoons/product/services/auth_service.dart';
import 'package:http/http.dart' as http;

class AreaService {
  final baseUrl = AppEnvironmentItems.baseUrl.value;
  final AuthService _authService;

  AreaService({required AuthService authService}) : _authService = authService;

  Future<List<Area>> fetchAreas() async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      final response = await http.post(
        Uri.parse('$baseUrl/Areas/getbybusinessid?id=$businessId'),
        headers: {'accept': '*/*'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> areaList = data['data'];
        return areaList.map((json) => Area.fromJson(json)).toList();
      } else {
        throw Exception(
            'Bölgeleri getirirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bölgeleri getirirken hata oluştu: $e');
    }
  }

  Future<Area> addArea(Area area) async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      final url = Uri.parse('$baseUrl/areas/add');
      final body = jsonEncode({
        'title': area.title,
        'businessId': businessId,
      });
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'}, body: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        print('area: $data');
        return Area.fromJson(data);
      } else {
        throw Exception('Bölge eklerken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bölge eklerken hata oluştu: $e');
    }
  }

  Future<bool> deleteArea(int areaId) async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      final url = Uri.parse('$baseUrl/Areas/deletebyid?id=$areaId');
      final response = await http.post(
        url,
        headers: {'accept': '*/*'},
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Bölge silinirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bölge silinirken hata oluştu: $e');
    }
  }
}

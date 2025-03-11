import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foomoons/product/init/config/app_environment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AuthService {
  final String baseUrl = AppEnvironmentItems.baseUrl.value;
  final Ref ref;

  AuthService(this.ref);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Accept': '*/*',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];
        final expiration = responseData['expiration'];

        // Token'ı ve diğer bilgileri SharedPreferences'a kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('expiration', expiration);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', email);

        // Kullanıcı bilgilerini al ve userType'ı kaydet
        final userResult = await getUserByEmail(email);
        if (userResult['success']) {
          final userData = userResult['data'];
          await prefs.setString('userType', userData['userType'] ?? '');
        }
        // Profile verilerini zorla yenile
        ref.read(profileProvider.notifier).invalidateCache();
        await ref.read(profileProvider.notifier).fetchAndLoad(forceRefresh: true);

        return {
          'success': true,
          'message': 'Success',
        };
      } else {
        return {
          'success': false,
          'message': 'Giriş başarısız. Lütfen bilgilerinizi kontrol edin.',
        };
      }
    } catch (e) {
      print('Bir hata oluştu: ${e.toString()}');
      return {
        'success': false,
        'message': 'Bir hata oluştu: ${e.toString()}',
      };
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Önce businessId'yi al (topic'ten çıkış için gerekebilir)
    final businessId = await getBusinessId();
    // Tüm verileri temizle
    await prefs.clear();
    // Profile state'ini temizle
    ref.read(profileProvider.notifier).resetProfile();
    // Cache'i geçersiz kıl
    ref.read(profileProvider.notifier).invalidateCache();
    
    debugPrint('Çıkış yapıldı, businessId: $businessId temizlendi');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final expiration = prefs.getString('expiration');
    
    if (token == null || expiration == null) {
      return false;
    }

    final expirationDate = DateTime.parse(expiration);
    if (expirationDate.isBefore(DateTime.now())) {
      await prefs.clear();
      return false;
    }

    return true;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  Future<Map<String, dynamic>> getUserByEmail(String email) async {
    try {
      final token = await getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı',
        };
      }
      print('token: $token');
      final response = await http.get(
        Uri.parse('$baseUrl/Users/getuserbyemail?email=$email'),
        headers: {
          'Accept': '*/*',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userData = responseData['data'];
        
        // BusinessId'yi SharedPreferences'a kaydedelim
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('businessId', userData['businessId']);
        
        return {
          'success': true,
          'data': userData,
        };
      } else {
        print('Kullanıcı bilgileri alınamadı: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Kullanıcı bilgileri alınamadı',
        };
      }
    } catch (e) {
      print('Kullanıcı bilgileri alınırken hata: $e');
      return {
        'success': false,
        'message': 'Bir hata oluştu: $e',
      };
    }
  }

  Future<int?> getBusinessId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('businessId');
  }

  Future<int> getValidatedBusinessId() async {
    final businessId = await getBusinessId();
    if (businessId == null) {
      throw Exception('BusinessId bulunamadı');
    }
    return businessId;
  }

  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userType');
  }
} 
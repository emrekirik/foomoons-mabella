import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:foomoons/product/init/config/app_environment.dart';
import 'package:foomoons/product/services/auth_service.dart';
import 'package:intl/intl.dart';

class PastBillsService {
  final String baseUrl = AppEnvironmentItems.baseUrl.value;
  final AuthService _authService;

  PastBillsService({required AuthService authService}) : _authService = authService;

  /// Geçmiş adisyonları getiren metod
  Future<List<Map<String, dynamic>>> fetchPastBills({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      
      // API endpoint URL'sini oluştur
      final url = '$baseUrl/ClosedBills/getclosedBilldetailsbybusinessid?id=$businessId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['data'] != null) {
          final List<dynamic> closedBills = data['data'];
          
          // Tarih aralığına göre filtreleme
          final filteredBills = closedBills.where((bill) {
            if (startDate == null && endDate == null) {
              return true; // Tarih filtresi yoksa tüm sonuçları göster
            }
            
            final closedAt = DateTime.parse(bill['closedBill']['closedAt'] ?? DateTime.now().toString());
            
            if (startDate != null && endDate != null) {
              return closedAt.isAfter(startDate) && closedAt.isBefore(endDate.add(const Duration(days: 1)));
            } else if (startDate != null) {
              return closedAt.isAfter(startDate);
            } else if (endDate != null) {
              return closedAt.isBefore(endDate.add(const Duration(days: 1)));
            }
            
            return true;
          }).toList();
          
          // Sonuçları işleme
          return filteredBills.map((bill) {
            // API yanıtından doğrudan değerleri al
            final closedBill = bill['closedBill'];
            final List<dynamic> pastBillItems = bill['pastBillItems'] as List<dynamic>? ?? [];

            DateTime? openedAt;
            DateTime? closedAt;
            
            try {
              openedAt = closedBill['openedAt'] != null 
                ? DateTime.parse(closedBill['openedAt']) 
                : null;
              closedAt = closedBill['closedAt'] != null 
                ? DateTime.parse(closedBill['closedAt']) 
                : null;
            } catch (e) {
              print('Tarih dönüşüm hatası: $e');
            }
            
            // Ödeme yöntemini belirle
            final cashTotal = (closedBill['cashTotal'] ?? 0).toDouble();
            final creditCardTotal = (closedBill['creditCardTotal'] ?? 0).toDouble();
            
            String paymentMethod = 'Bilinmiyor';
            if (cashTotal > 0 && creditCardTotal > 0) {
              paymentMethod = 'Karışık';
            } else if (creditCardTotal > 0) {
              paymentMethod = 'Kredi Kartı';
            } else if (cashTotal > 0) {
              paymentMethod = 'Nakit';
            }
            
            return {
              'id': closedBill['id'],
              'tableId': closedBill['tableId'],
              'businessId': closedBill['businessId'],
              'totalAmount': (closedBill['totalAmount'] ?? 0).toDouble(),
              'openedAt': openedAt,
              'closedAt': closedAt,
              'cashTotal': cashTotal,
              'creditCardTotal': creditCardTotal,
              'pastBillItems': pastBillItems.map((item) => {
                'id': item['id'],
                'category': item['category'],
                'isAmount': item['isAmount'] ?? false,
                'isCredit': item['isCredit'] ?? false,
                'piece': item['piece'] ?? 1,
                'preparationTime': item['preparationTime'],
                'price': (item['price'] ?? 0).toDouble(),
                'title': item['title'],
                'businessId': item['businessId'],
                'closedBillId': item['closedBillId'],
                'status': item['status'],
                'orderedBy': item['orderedBy'],
              }).toList(),
              'rawData': closedBill,
            };
          }).toList();
        }
        return [];
      } else {
        throw Exception('Geçmiş adisyonlar alınırken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Geçmiş adisyonlar alınırken hata: $e');
      throw Exception('Geçmiş adisyonlar alınırken hata oluştu: $e');
    }
  }
  
  /// Belirli bir geçmiş adisyonun detaylarını getiren metod
  Future<Map<String, dynamic>> fetchPastBillDetails(int billId) async {
    try {
      final url = '$baseUrl/ClosedBills/getclosedBilldetail?id=$billId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['data'] != null) {
          return data;  // Tüm veriyi olduğu gibi döndür
        }
        throw Exception('Adisyon detayları bulunamadı');
      } else {
        throw Exception('Adisyon detayları alınırken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Adisyon detayları alınırken hata: $e');
      throw Exception('Adisyon detayları alınırken hata oluştu: $e');
    }
  }
} 
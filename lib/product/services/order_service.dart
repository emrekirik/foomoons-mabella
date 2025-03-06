import 'dart:convert';
import 'package:foomoons/product/init/config/app_environment.dart';
import 'package:foomoons/product/model/order.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:http/http.dart' as http;
import 'package:foomoons/product/services/auth_service.dart';

class OrderService {
  final String baseUrl = AppEnvironmentItems.baseUrl.value;
  final AuthService _authService;

  OrderService({required AuthService authService}) : _authService = authService;

  Future<List<Order>> fetchOrders() async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      
      final response = await http.get(
        Uri.parse('$baseUrl/Orders/getbybusinessid?id=$businessId'),
        headers: {'accept': '*/*'},
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> orderList = data['data'];
        return orderList.map((json) => Order.fromJson(json)).toList();
      } else {
        print('Siparişleri alırken hata oluştu: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('API hatası: $e');
      return [];
    }
  }

  Future<bool> addOrder(Menu item, String tableTitle) async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      
      final requestBody = {
        'piece': item.piece ?? 1,
        'orderDate': DateTime.now().toIso8601String(),
        'preprationTime': DateTime.now().toIso8601String(),
        'price': item.price ?? 0.0,
        'productId': item.id ?? 0,
        'tableTitle': tableTitle,
        'title': item.title ?? '',
        'status': 'hazırlanıyor',
        'businessId': businessId,
        'customerMessage': '',
        'orderType': 'mutfak',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/orders/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }
      return false;
    } catch (e) {
      print('Sipariş ekleme hatası: $e');
      return false;
    }
  }

  Future<(bool, Order?)> updateOrder(Order order, String newStatus) async {
    try {
      print('OrderService: Updating order - ID: ${order.id}, Status: $newStatus');
      
      // Convert Timestamp to ISO string format
      String? orderDateStr = order.orderDate != null 
          ? DateTime.fromMillisecondsSinceEpoch(order.orderDate!.millisecondsSinceEpoch).toIso8601String()
          : null;
          
      print('OrderService: Order: $order');
      print('OrderService: OrderDateStr: $orderDateStr');
          
      final requestBody = {
        'id': order.id,
        'orderDate': orderDateStr,
        'piece': order.piece,
        'preprationTime': "2024-12-21T00:59:39.252Z", // Using same date for preparation time
        'price': order.price,
        'productId': order.productId,
        'tableTitle': order.tableTitle,
        'title': order.title,
        'status': newStatus,
        'businessId': order.businessId,
        'customerMessage': order.customerMessage ?? '', // Default empty string since it's not in our model
        'orderType': order.orderType,
      };
      
      print('OrderService: Request body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/orders/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      print('OrderService: Response status code: ${response.statusCode}');
      print('OrderService: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final updatedOrder = Order.fromJson(responseData['data']);
          return (true, updatedOrder);
        }
      }
      return (false, null);
    } catch (e) {
      print('OrderService: Update error: $e');
      return (false, null);
    }
  }
}

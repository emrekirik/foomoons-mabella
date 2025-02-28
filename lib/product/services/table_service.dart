import 'dart:convert';

import 'package:foomoons/product/init/config/app_environment.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:foomoons/product/model/table.dart';
import 'package:foomoons/product/services/auth_service.dart';
import 'package:http/http.dart' as http;

class TableService {
  final String baseUrl = AppEnvironmentItems.baseUrl.value;
  final AuthService _authService;

  TableService({required AuthService authService}) : _authService = authService;

  Future<List<CoffeTable>> fetchTables() async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      final response = await http.get(
        Uri.parse('$baseUrl/Tables/getbybusinessid?id=$businessId'),
        headers: {'accept': '*/*'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> tableList = data['data'];
        final tables =
            tableList.map((json) => CoffeTable.fromJson(json)).toList();
        tables.sort((a, b) =>
            int.tryParse(a.tableTitle!.split(' ').last)?.compareTo(
              int.tryParse(b.tableTitle!.split(' ').last) ?? 0,
            ) ??
            0);
        return tables;
      } else {
        throw Exception(
            'Masaları getirirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Masaları getirirken hata oluştu: $e');
    }
  }

  Future<CoffeTable> addTable(CoffeTable table) async {
    try {
      final businessId = await _authService.getValidatedBusinessId();
      final url = Uri.parse('$baseUrl/tables/add');
      final body = jsonEncode({
        'area': table.area,
        'qrUrl': table.qrUrl,
        'tableTitle': table.tableTitle,
        'businessId': businessId,
      });
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );
      final responseData = jsonDecode(response.body);
      final addedTable = CoffeTable.fromJson(responseData['data']);
      print(addedTable.qrUrl);
      return addedTable;
    } catch (e) {
      throw Exception('Masa eklerken hata oluştu: $e');
    }
  }

  Future<List<Menu>> fetchTableBill(int tableId) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/bills/getbilldetailbytableid?id=$tableId')); //bu api sıkıntılı bazı değerleri null alıyor (isAmount, isCredit, category, preptime)
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final billItems = data['data']?['billItems'] as List<dynamic>? ?? [];

        final List<Menu> currentBillItems = billItems.map((item) {
          final menuItem = Menu(
            id: item['id'] as int?,
            title: item['title'] as String?,
            price: item['price'] as double?,
            status: item['status'] as String?,
            category: item['category'] as String?,
            piece: _parseToInt(item['piece']) ?? 1,
            isCredit: item['isCredit'] as bool?,
            isAmount: item['isAmount'] as bool?,
            billId: item['billId'] as int?,
          );
          return menuItem;
        }).toList();
        return currentBillItems;
      } else {
        throw Exception(
            'Masa adisyonu çekerken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Masa adisyonu çekerken hata oluştu: $e');
    }
  }

  Future<Menu> addItemToBill(Menu item, [List<Menu>? existingBillItems]) async {
    try {
      print('🔍 Masa için mevcut adisyon kontrol ediliyor...');
      
      // Try to get billId from existing items first
      int? billId;
      if (existingBillItems != null && existingBillItems.isNotEmpty) {
        billId = existingBillItems.first.billId;
        print('📋 Mevcut adisyon bulundu - Bill ID: $billId');
      }
      
      // If no existing billId found, create new one
      billId ??= await _getOrCreateBillId(item.tableId!);
      print('📝 Adisyon ID: $billId');

      print('➕ Ürün adisyona ekleniyor: ${item.title}');
      // Add item to bill
      final requestBody = {
        "category": item.category,
        "isAmount": item.isAmount ?? false,
        "isCredit": item.isCredit ?? false,
        "piece": item.piece ?? 1,
        "preparationTime": DateTime.now().toIso8601String(),
        "price": item.price,
        "status": item.status,
        "title": item.title,
        "billId": billId,
      };
      print('📤 API isteği gönderiliyor...');
      final itemResponse = await http.post(
        Uri.parse('$baseUrl/billitems/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (itemResponse.statusCode != 200) {
        print('❌ Hata: Ürün adisyona eklenemedi (Status: ${itemResponse.statusCode})');
        throw Exception('Ürün adisyona eklenemedi');
      }

      print('✅ Ürün başarıyla adisyona eklendi');
      final addedItemData = jsonDecode(itemResponse.body)['data'];
      final menuItem = Menu(
        id: addedItemData['id'],
        title: addedItemData['title'],
        price: addedItemData['price']?.toDouble(),
        status: addedItemData['status'],
        category: addedItemData['category'],
        piece: _parseToInt(addedItemData['piece']) ?? 1,
        isCredit: addedItemData['isCredit'] ?? item.isCredit ?? false,
        isAmount: addedItemData['isAmount'] ?? item.isAmount ?? false,
        tableId: item.tableId,
        billId: billId,
      );
      print('🎉 İşlem tamamlandı: ${menuItem.title} (${menuItem.piece} adet)');
      return menuItem;
    } catch (e) {
      print('💥 Hata oluştu: $e');
      throw Exception('Ürün adisyona eklenirken hata oluştu: $e');
    }
  }

  Future<int> _getOrCreateBillId(int tableId) async {
    print('🔍 Masa #$tableId için mevcut adisyon aranıyor...');
    final response =
        await http.get(Uri.parse('$baseUrl/bills/getbilldetailbytableid?id=$tableId'));
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200 &&
        responseData['data']?['billDetail'] != null) {
      final billId = responseData['data']['billDetail']['id'];
      print('✅ Mevcut adisyon bulundu - Adisyon ID: $billId');
      return billId;
    }

    print('📝 Mevcut adisyon bulunamadı, yeni adisyon oluşturuluyor...');
    final businessId = await _authService.getValidatedBusinessId();

    final billResponse = await http.post(
      Uri.parse('$baseUrl/bills/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'businessId': businessId,
        'tableId': tableId,
      }),
    );

    if (billResponse.statusCode != 200) {
      print('❌ Hata: Yeni adisyon oluşturulamadı (Status: ${billResponse.statusCode})');
      throw Exception('Yeni adisyon oluşturulamadı');
    }

    final newBillId = jsonDecode(billResponse.body)['data']['id'];
    print('🎉 Yeni adisyon oluşturuldu - Adisyon ID: $newBillId');
    return newBillId;
  }

  Future<int> getOrCreateBillId(int tableId) async {
    return _getOrCreateBillId(tableId);
  }

  /// Helper method to safely parse values to int
  static int? _parseToInt(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value);
    } else {
      return null;
    }
  }

  Future<void> addToPastBillItems(Menu item) async {
    try {
      final businessId = await _authService.getValidatedBusinessId();

      final url = Uri.parse('$baseUrl/PastBillItems/add');
      final body = jsonEncode({
        'category': item.category,
        'isAmount': item.isAmount ?? false,
        'isCredit': item.isCredit,
        'piece': item.piece ?? 1,
        'preparationTime': DateTime.now().toIso8601String(),
        'price': item.price,
        'title': item.title,
        'businessId': businessId
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Geçmiş adisyon kalemlerine eklenirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Geçmiş adisyon kalemlerine eklenirken hata oluştu: $e');
    }
  }

  Future<bool> closeBill(int tableId) async {
    try {
      print('🔄 Masa #$tableId için adisyon kapatma işlemi başlatıldı');
      
      // 1. Get current bill items
      final currentBill = await fetchTableBill(tableId);
      print('📋 Mevcut adisyon kalemleri getirildi: ${currentBill.length} adet ürün');

      if (currentBill.isEmpty) {
        print('⚠️ Adisyonda ürün bulunmadığı için işlem iptal edildi');
        return false;
      }

      final billId = currentBill.first.billId;
      print('🔑 Bill ID: $billId');

      // 2. Add each item to past bill items in parallel
      print('📥 Ürünler geçmiş adisyon kalemlerine aktarılıyor...');
      await Future.wait(
        currentBill.map((item) async {
          await addToPastBillItems(item);
          print('✅ "${item.title}" geçmiş kayıtlara eklendi');
        }),
      );

      // 3. Delete each bill item in parallel
      print('🗑️ Mevcut adisyon kalemleri siliniyor...');
      final deleteItemFutures = currentBill.where((item) => item.id != null).map((item) async {
        final deleteItemResponse = await http.post(
          Uri.parse('$baseUrl/BillItems/deletebyid?id=${item.id}'),
          headers: {'Content-Type': 'application/json'},
        );

        if (deleteItemResponse.statusCode != 200) {
          throw Exception('Bill item silinemedi: ${item.id}');
        }
        print('✅ "${item.title}" adisyondan silindi');
      });
      
      await Future.wait(deleteItemFutures);

      // 4. Delete the bill itself
      if (billId != null) {
        print('🗑️ Ana adisyon siliniyor (ID: $billId)...');
        final deleteBillResponse = await http.post(
          Uri.parse('$baseUrl/bills/deletebyid?id=$billId'),
        );

        if (deleteBillResponse.statusCode != 200) {
          throw Exception('Bill silinemedi');
        }
        print('✅ Ana adisyon başarıyla silindi');
      } else {
        throw Exception('Bill ID bulunamadı');
      }

      print('✨ Masa #$tableId için adisyon kapatma işlemi başarıyla tamamlandı');
      return true;
    } catch (e) {
      print('❌ HATA: Adisyon kapatılırken bir sorun oluştu:');
      print('❌ $e');
      return false;
    }
  }

  Future<void> updateBillItemStatus(Menu item) async {
    try {
      // Tutar bazlı ödemeler için id null ise add endpoint'ini kullan
      // Normal ürünler veya id'si olan tutar bazlı ödemeler için update endpoint'ini kullan
      final endpoint = (item.isAmount == true && item.id == null)
          ? 'billitems/add'
          : 'BillItems/update';
      final url = Uri.parse('$baseUrl/$endpoint');

      final Map<String, dynamic> requestBody;
      if (item.isAmount == true && item.id == null) {
        requestBody = {
          'category': item.category ?? 'Genel',
          'isAmount': item.isAmount,
          'isCredit': item.isCredit,
          'piece': item.piece ?? 1,
          'preparationTime': DateTime.now().toIso8601String(),
          'price': item.price,
          'status': item.status,
          'title': item.title,
          'billId': item.billId
        };
      } else {
        requestBody = {
          'id': item.id,
          'category': item.category ?? 'Genel',
          'isAmount': item.isAmount,
          'isCredit': item.isCredit,
          'piece': item.piece ?? 1,
          'preparationTime': DateTime.now().toIso8601String(),
          'price': item.price,
          'status': item.status,
          'title': item.title,
          'billId': item.billId
        };
      }

      final body = jsonEncode(requestBody);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Ürün durumu güncellenirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ürün durumu güncellenirken hata oluştu: $e');
    }
  }

  Future<int?> getTableIdByTitle(String tableTitle) async {
    try {
      final tables = await fetchTables();
      final table = tables.firstWhere(
        (table) => table.tableTitle == tableTitle,
        orElse: () => throw Exception('Masa bulunamadı: $tableTitle'),
      );
      return table.id;
    } catch (e) {
      print('Masa ID bulunamadı: $e');
      return null;
    }
  }

  Future<bool> deleteBill(int id) async {
    try {
      print('🗑️ Adisyon siliniyor (ID: $id)...');
      final response = await http.post(
        Uri.parse('$baseUrl/bills/deletebyid?id=$id'),
        headers: {'accept': '*/*'},
      );

      if (response.statusCode != 200) {
        print('❌ Adisyon silinemedi (Status: ${response.statusCode})');
        return false;
      }

      print('✅ Adisyon başarıyla silindi');
      return true;
    } catch (e) {
      print('❌ HATA: Adisyon silinirken bir sorun oluştu:');
      print('❌ $e');
      return false;
    }
  }

  Future<bool> deleteTable(int tableId) async {
    try {
      print('🗑️ Masa siliniyor (ID: $tableId)...');
      final response = await http.post(
        Uri.parse('$baseUrl/Tables/deletebyid?id=$tableId'),
        headers: {'accept': '*/*'},
      );

      if (response.statusCode != 200) {
        print('❌ Masa silinemedi (Status: ${response.statusCode})');
        return false;
      }

      print('✅ Masa başarıyla silindi');
      return true;
    } catch (e) {
      print('❌ HATA: Masa silinirken bir sorun oluştu:');
      print('❌ $e');
      return false;
    }
  }

  Future<bool> mergeTables(int sourceTableId, int targetTableId) async {
    try {
      print('🔄 Masalar birleştiriliyor...');
      print('📤 Kaynak masa: #$sourceTableId');
      print('📥 Hedef masa: #$targetTableId');

      // 1. Kaynak masanın adisyonunu al
      final sourceBillItems = await fetchTableBill(sourceTableId);
      if (sourceBillItems.isEmpty) {
        print('⚠️ Kaynak masada adisyon bulunamadı');
        return false;
      }

      // 2. Hedef masanın adisyon ID'sini al veya yeni adisyon oluştur
      final targetBillId = await _getOrCreateBillId(targetTableId);
      print('🎯 Hedef masa adisyon ID: $targetBillId');

      // 3. Kaynak masadaki her ürünü hedef masaya aktar
      print('📦 Ürünler aktarılıyor...');
      for (final item in sourceBillItems) {
        final newItem = Menu(
          title: item.title,
          price: item.price,
          status: item.status,
          category: item.category,
          piece: item.piece,
          isCredit: item.isCredit,
          isAmount: item.isAmount,
          tableId: targetTableId,
          billId: targetBillId,
        );
        await addItemToBill(newItem);
        print('✅ "${item.title}" aktarıldı');
      }

      // 4. Kaynak masanın adisyonunu sil
      final sourceBillId = sourceBillItems.first.billId;
      if (sourceBillId != null) {
        print('🗑️ Kaynak masa adisyonu siliniyor...');
        await deleteBill(sourceBillId);
      }

      print('✨ Masalar başarıyla birleştirildi');
      return true;
    } catch (e) {
      print('❌ HATA: Masalar birleştirilirken bir sorun oluştu:');
      print('❌ $e');
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/featured/providers/tables_notifier.dart';
import 'package:foomoons/product/model/menu.dart';
import 'package:foomoons/product/init/config/app_environment.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:http/http.dart' as http;

final _tablesProvider = StateNotifierProvider<TablesNotifier, TablesState>((ref) {
  return TablesNotifier(ref);
});

class PaymentService {
  static final String baseUrl = AppEnvironmentItems.baseUrl.value;

  static Future<bool> deleteBillItem(int id) async {
    try {
      print('🗑️ Tutar bazlı ödeme silme isteği gönderiliyor - ID: $id');
      final response = await http.post(
        Uri.parse('$baseUrl/BillItems/deletebyid?id=$id'),
      );
      print('📡 API yanıtı - Status Code: ${response.statusCode}, Body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Silme işlemi hatası - ID: $id, Hata: $e');
      return false;
    }
  }

  static Future<bool> processPayment({
    required BuildContext context,
    required WidgetRef ref,
    required int tableId,
    required List<Menu> rightList,
    required Function(bool) onSavingChanged,
    required Set<int> amountItemsToDelete,
  }) async {
    try {
      onSavingChanged(true);
      ref.read(loadingProvider.notifier).setLoading('payment', true);
      final tableService = ref.read(tableServiceProvider);
      final billId = await tableService.getOrCreateBillId(tableId);

      // Önce silinecek amount ödemeleri sil
      if (amountItemsToDelete.isNotEmpty) {
        print('🔍 Silinecek amount ödemeleri: $amountItemsToDelete');
        final deletionResults = await Future.wait(
          amountItemsToDelete.map((id) => deleteBillItem(id))
        );

        // Her bir silme işleminin sonucunu kontrol et
        for (int i = 0; i < amountItemsToDelete.length; i++) {
          final id = amountItemsToDelete.elementAt(i);
          final success = deletionResults[i];
          if (!success) {
            print('❌ ID: $id için silme işlemi başarısız oldu');
          }
        }

        if (deletionResults.contains(false)) {
          throw Exception('Bazı ödemelerin silinmesi başarısız oldu. Lütfen tekrar deneyin.');
        }
      }

      // Diğer ödemeleri güncelle
      await Future.wait(
        rightList.map((item) async {
          final updatedItem = item.copyWith(
            status: 'ödendi',
            isCredit: item.isCredit,
            billId: billId,
          );
          return tableService.updateBillItemStatus(updatedItem);
        }),
      );

      await ref.read(_tablesProvider.notifier).fetchTableBillApi(tableId);
      
      if (!context.mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ödeme başarıyla tamamlandı ve ürünler güncellendi.'),
          backgroundColor: Colors.green,
        ),
      );

      return true;
    } catch (e) {
      if (!context.mounted) return false;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ödeme işlemi sırasında hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    } finally {
      if (context.mounted) {
        onSavingChanged(false);
        ref.read(loadingProvider.notifier).setLoading('payment', false);
      }
    }
  }
} 
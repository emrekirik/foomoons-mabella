import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:foomoons/product/services/settings_service.dart';
import 'dart:io';
import 'dart:convert';

typedef LogCallback = void Function(String message, {bool isError});

class KitchenPrinterService {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  static Future<void> printKitchenOrder(
    Map<String, dynamic> order, {
    LogCallback? onLog,
    bool useWifi = false,
  }) async {
    print('\n🖨️ Mutfak Siparişi Yazdırma başlatılıyor...');
    
    final settingsService = SettingsService();
    
    if (useWifi) {
      final printerIp = await settingsService.getPrinter2IpAddress();
      if (printerIp == null || printerIp.isEmpty) {
        print('❌ Mutfak yazıcısı IP adresi bulunamadı. Lütfen önce IP adresini ayarlayın.');
        return;
      }
      await printKitchenOrderWifi(order, printerIp);
      return;
    }
    
    final printerName = await settingsService.getPrinter2Name();
    if (printerName.isEmpty) {
      print('❌ Mutfak yazıcısı ismi bulunamadı. Lütfen önce yazıcı ismini ayarlayın.');
      return;
    }

    int retryCount = 0;
    bool success = false;

    while (!success && retryCount < _maxRetries) {
      if (retryCount > 0) {
        print('🔄 Yeniden deneme ${retryCount + 1}/$_maxRetries...');
        await Future.delayed(_retryDelay);
      }

      success = await _tryPrintKitchenOrder(printerName, order);
      if (!success) retryCount++;
    }

    if (!success) {
      print('❌ Maksimum deneme sayısına ulaşıldı. Mutfak siparişi yazdırma başarısız.');
    }
  }

  static Future<void> printKitchenOrderWifi(Map<String, dynamic> order, String printerIp) async {
    print('📡 WiFi üzerinden mutfak siparişi yazdırılıyor...');
    print('🖨️ Yazıcı IP: $printerIp');

    try {
      final socket = await Socket.connect(printerIp, 9100, timeout: Duration(seconds: 5));
      print('✅ Yazıcı bağlantısı başarılı');

      final orderData = _generateKitchenOrderData(order);
      List<int> bytes = [];
      
      // ESC/POS komutları
      bytes.addAll([0x1B, 0x40]); // Initialize printer
      bytes.addAll([0x1B, 0x74, 0x12]); // Select character code table
      
      // Veriyi byte'lara dönüştür
      bytes.addAll(utf8.encode(orderData));
      
      // Kağıt kesme komutu
      bytes.addAll([0x1D, 0x56, 0x41, 0x00]);
      
      // Veriyi gönder
      socket.add(bytes);
      await socket.flush();
      
      // Bağlantıyı kapat
      await socket.close();
      print('✅ Mutfak siparişi başarıyla yazdırıldı');
    } catch (e) {
      print('❌ WiFi yazdırma hatası: $e');
      rethrow;
    }
  }

  static Future<bool> _tryPrintKitchenOrder(
    String printerName,
    Map<String, dynamic> order,
  ) async {
    print('📌 Kullanılacak mutfak yazıcısı: $printerName');
    final printerNamePtr = printerName.toNativeUtf16();
    final hPrinter = calloc<HANDLE>();

    try {
      print('🔌 Mutfak yazıcısı bağlantısı açılıyor...');
      if (OpenPrinter(printerNamePtr, hPrinter, nullptr) == 0) {
        final error = GetLastError();
        print('❌ Mutfak yazıcısı açılamadı. Hata kodu: $error');
        return false;
      }

      print('✅ Mutfak yazıcısı bağlantısı başarılı');

      print('📝 Mutfak siparişi yazdırma bilgileri hazırlanıyor...');
      final docInfo = calloc<DOC_INFO_1>()
        ..ref.pDocName = TEXT('Mutfak Siparisi')
        ..ref.pOutputFile = nullptr
        ..ref.pDatatype = TEXT('RAW');

      try {
        print('🚀 Mutfak siparişi yazdırma işlemi başlatılıyor...');
        if (StartDocPrinter(hPrinter.value, 1, docInfo) == 0) {
          final error = GetLastError();
          print('❌ StartDocPrinter başarısız. Hata kodu: $error');
          return false;
        }

        print('✅ Mutfak siparişi yazdırma işlemi başlatıldı');

        print('📋 Mutfak siparişi verisi hazırlanıyor...');
        final orderData = _generateKitchenOrderData(order);
        
        List<int> allBytes = [];
        
        for (int i = 0; i < orderData.length; i++) {
          allBytes.add(orderData.codeUnitAt(i));
        }
        
        allBytes.addAll([0x1D, 0x56, 0x41]); // Kesme komutu
        
        final printData = calloc<Uint8>(allBytes.length);
        for (int i = 0; i < allBytes.length; i++) {
          printData[i] = allBytes[i];
        }
        
        final bytesWritten = calloc<Uint32>();

        try {
          print('📤 Mutfak siparişi verisi yazıcıya gönderiliyor...');
          print('📏 Gönderilecek veri boyutu: ${allBytes.length} byte');

          if (StartPagePrinter(hPrinter.value) == 0) {
            final error = GetLastError();
            print('❌ StartPagePrinter başarısız. Hata kodu: $error');
            return false;
          }

          final result = WritePrinter(hPrinter.value, printData.cast(), allBytes.length, bytesWritten);
          
          if (result != 0) {
            print('✅ WritePrinter başarılı - Yazılan byte: ${bytesWritten.value}');
          } else {
            final error = GetLastError();
            print('❌ WritePrinter başarısız. Hata kodu: $error');
            return false;
          }

          if (EndPagePrinter(hPrinter.value) == 0) {
            final error = GetLastError();
            print('❌ EndPagePrinter başarısız. Hata kodu: $error');
            return false;
          }

          print('✅ Mutfak siparişi yazdırma başarılı');
          return true;
        } finally {
          calloc.free(printData);
          calloc.free(bytesWritten);
        }
      } finally {
        EndDocPrinter(hPrinter.value);
        calloc.free(docInfo);
      }
    } catch (e) {
      print('❌ Beklenmeyen hata: $e');
      return false;
    } finally {
      ClosePrinter(hPrinter.value);
      calloc.free(printerNamePtr);
      calloc.free(hPrinter);
    }
  }

  static String _generateKitchenOrderData(Map<String, dynamic> order) {
    final buffer = StringBuffer();
    const paperWidth = 42;
    const doubleLine = '========================================\n';
    const singleLine = '----------------------------------------\n';

    // Yazıcı başlatma
    buffer.write('\x1B\x40'); // Initialize printer
    buffer.write('\x1B\x74\x12'); // Select PC857 Turkish character set
    buffer.write('\x1B\x52\x12'); // Select international character set (Turkish)
    
    buffer.write('\n');
    
    // Başlık
    buffer.write('\x1B\x61\x01'); // Center alignment
    buffer.write('\x1B\x21\x30'); // Double width + Double height
    buffer.write('MUTFAK SIPARISI\n\n');
    
    buffer.write('\x1B\x21\x01'); // Normal boyut
    buffer.write('\x1B\x61\x00'); // Left alignment
    
    // Sipariş detayları
    final dateStr = DateTime.now().toString().substring(0, 19);
    buffer.write('Tarih: $dateStr\n');
    buffer.write(singleLine);
    
    // Masa bilgisi
    buffer.write('\x1B\x21\x08'); // Emphasized
    buffer.write('Masa: ${order['tableTitle'] ?? 'Bilinmiyor'}\n');
    buffer.write(singleLine);
    
    // Ürün detayları
    buffer.write('Urun: ${order['title'] ?? 'Bilinmiyor'}\n');
    buffer.write('Adet: ${order['piece'] ?? 1}\n');
    
    if (order['customerMessage'] != null && order['customerMessage'].toString().isNotEmpty) {
      buffer.write('\nNot: ${order['customerMessage']}\n');
    }
    
    buffer.write(doubleLine);
    buffer.write('\n\n\n\n\n'); // Kağıt kesme için boşluk
    
    return buffer.toString();
  }

  static String _convertToAscii(String text) {
    final turkishMap = {
      'ç': 'c', 'Ç': 'C',
      'ğ': 'g', 'Ğ': 'G',
      'ı': 'i', 'İ': 'I',
      'ö': 'o', 'Ö': 'O',
      'ş': 's', 'Ş': 'S',
      'ü': 'u', 'Ü': 'U',
    };

    String result = text;
    turkishMap.forEach((turkishChar, asciiChar) {
      result = result.replaceAll(turkishChar, asciiChar);
    });
    return result;
  }
} 
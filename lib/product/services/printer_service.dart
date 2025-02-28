import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:foomoons/product/services/settings_service.dart';

typedef LogCallback = void Function(String message, {bool isError});

class PrinterService {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  static List<String> getAvailablePrinters({LogCallback? onLog}) {
    print('\n🖨️ Yazıcı Tarama Başladı...');
    final printers = <String>[];
    final flags = PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS;
    final pcbNeeded = calloc<Uint32>();
    final pcReturned = calloc<Uint32>();

    try {
      print('📊 İlk buffer boyutu hesaplanıyor...');
      if (EnumPrinters(flags, nullptr, 2, nullptr, 0, pcbNeeded, pcReturned) == 0) {
        final error = GetLastError();
        if (error != ERROR_INSUFFICIENT_BUFFER) {
          print('❌ Buffer boyutu alınamadı. Hata kodu: $error');
          return printers;
        }
      }

      print('📏 Gerekli buffer boyutu: ${pcbNeeded.value} byte');

      if (pcbNeeded.value > 0) {
        final pPrinterInfo = calloc<Uint8>(pcbNeeded.value);
        print('🔍 Yazıcılar taranıyor...');
        
        final result = EnumPrinters(
          flags, 
          nullptr, 
          2, 
          pPrinterInfo, 
          pcbNeeded.value,
          pcbNeeded, 
          pcReturned
        );

        if (result != 0) {
          final count = pcReturned.value;
          print('✅ Bulunan yazıcı sayısı: $count');
          
          for (var i = 0; i < count; i++) {
            final printerInfo = pPrinterInfo.cast<PRINTER_INFO_2>().elementAt(i);
            final printerName = printerInfo.ref.pPrinterName.cast<Utf16>().toDartString();
            print('📌 Yazıcı ${i + 1}: $printerName');
            printers.add(printerName);
          }
        } else {
          final error = GetLastError();
          print('❌ Yazıcı listesi alınamadı. Hata kodu: $error');
        }
        
        print('🧹 Bellek temizleniyor...');
        calloc.free(pPrinterInfo);
      } else {
        print('⚠️ Hiç yazıcı bulunamadı');
      }
    } catch (e) {
      print('❌ Hata oluştu: $e');
    } finally {
      calloc.free(pcbNeeded);
      calloc.free(pcReturned);
      print('🏁 Yazıcı tarama tamamlandı\n');
    }

    return printers;
  }

  static String _generateESCPosData(List<Map<String, dynamic>> billItems) {
    print('📋 Fiş içeriği oluşturuluyor...');
    final buffer = StringBuffer();
    const paperWidth = 42;
    const doubleLine = '========================================\n';
    const singleLine = '----------------------------------------\n';

    // Debug: Komut uzunluklarını kontrol et
    print('🔍 ESC/POS Komutları Kontrol Ediliyor...');

    // Printer initialization
    buffer.write('\x1B\x40'); // Initialize printer
    buffer.write('\x1B\x74\x12'); // Select PC857 Turkish character set
    buffer.write('\x1B\x52\x12'); // Select international character set (Turkish)
    
    buffer.write('\n'); // Başlık öncesi ekstra boşluk
    
    // Header - Daha büyük ve kalın başlık
    buffer.write('\x1B\x61\x01'); // Center alignment
    buffer.write('\x1B\x21\x38'); // Quadruple size + Double height + Bold
    buffer.write('FAKULTE\n'); 
    buffer.write('KARABUK\n\n'); // İki kelimeye böldük, daha şık görünüm
    
    buffer.write('\x1B\x21\x01'); // Font B (daha şık font) + Normal size
    buffer.write('\x1B\x61\x00'); // Left alignment
    
    final dateStr = DateTime.now().toString().substring(0, 19);
    buffer.write('  $dateStr\n'); // Tarih bilgisi aynı hizada
    
    // Ürün başlığı - Vurgulanmış
    buffer.write('\x1B\x21\x08'); // Font A + Bold
    buffer.write('  urun${' ' * 17}odeme${' ' * 7}fiyat\n');
    buffer.write('\x1B\x21\x01'); // Font B için geri dön
    buffer.write(singleLine);
    print('📝 Başlık çizgisi eklendi');

    print('📊 Ürünler gruplanıyor...');
    double total = 0;
    final Map<String, Map<String, dynamic>> groupedItems = {};

    for (final item in billItems) {
      final itemTitle = _convertToAscii(item['title'] ?? "Bilinmeyen Urun");
      print('🔍 Ürün Detayları:');
      print('   - Başlık: ${item['title']}');
      print('   - Status: ${item['status']}');
      print('   - isCredit: ${item['isCredit']}');
      print('   - Tüm veri: $item');
      
      final isCredit = item['isCredit'] == true;
      final key = '$itemTitle-${isCredit ? 'kredi' : 'nakit'}';
      
      if (!groupedItems.containsKey(key)) {
        groupedItems[key] = {
          'count': 1,
          'price': item['price'] ?? 0,
          'total': item['price'] ?? 0,
          'isCredit': isCredit
        };
      } else {
        groupedItems[key]?['count'] =
            (groupedItems[key]?['count'] ?? 0) + 1;
        groupedItems[key]?['total'] =
            (groupedItems[key]?['total'] ?? 0) + (item['price'] ?? 0);
      }
    }

    print('📝 Ürünler fişe yazılıyor...');
    for (final entry in groupedItems.entries) {
      final itemText = entry.key.split('-')[0];
      final count = entry.value['count'];
      final totalPrice = entry.value['total'];
      final isCredit = entry.value['isCredit'] as bool;
      total += totalPrice;

      final itemWithCount = '$itemText (${count}x)';
      
      // Ürün adını 15 karakterde kes ve gerekirse alt satıra geç
      final maxLength = 15;
      final lines = <String>[];
      
      if (itemWithCount.length > maxLength) {
        // İlk satır
        lines.add(itemWithCount.substring(0, maxLength));
        // İkinci satır (varsa)
        if (itemWithCount.length > maxLength) {
          lines.add(itemWithCount.substring(maxLength).trim());
        }
      } else {
        lines.add(itemWithCount);
      }

      // İlk satırı yaz
      final firstLine = lines[0].padRight(20);
      final paymentType = isCredit ? 'kredi' : 'nakit';
      final paymentStr = paymentType.padRight(8);
      final priceStr = '${totalPrice.toStringAsFixed(2)} TL'.padLeft(10);
      buffer.write('  $firstLine$paymentStr$priceStr\n');
      
      // Eğer ikinci satır varsa, sadece ürün adını yaz
      if (lines.length > 1) {
        final secondLine = lines[1].padRight(20);
        buffer.write('  $secondLine\n');
      }
      
      print('✍️ Ürün satırı eklendi');
    }

    buffer.write(doubleLine);
    print('📝 Alt çizgi eklendi');

    print('💰 Toplam tutar hesaplanıyor: $total TL');
    
    // Toplam kısmı - Daha belirgin
    buffer.write('\x1B\x21\x08'); // Font A + Bold
    final totalText = 'TOPLAM:';
    final totalAmount = '${total.toStringAsFixed(2)} TL'.padLeft(10);
    final totalSpaces = paperWidth - totalText.length - totalAmount.length - 2;
    final totalLine = '  $totalText${' ' * totalSpaces}$totalAmount\n';
    buffer.write(totalLine);
    
    buffer.write('\x1B\x21\x01'); // Font B için geri dön
    buffer.write('\n'); // Toplam ile İyi Çalışmalar arasına boşluk

    // Alt bilgi - Daha estetik
    buffer.write('\x1B\x61\x01'); // Center alignment
    buffer.write('\x1B\x21\x30'); // Double width + Double height
    buffer.write('Iyi Calismalar :)\n');
    buffer.write('\x1B\x21\x01'); // Font B
    buffer.write('Wifi: fakulteynk\n\n\n\n\n');

    final content = buffer.toString();
    print('📏 Oluşturulan fiş içeriği uzunluğu: ${content.length} byte');
    print('🔍 Fiş içeriği hex formatında:');
    print(content.split('').map((c) => '\\x${c.codeUnitAt(0).toRadixString(16).padLeft(2, '0')}').join(''));

    return content;
  }

  static String _convertToAscii(String text) {
    final turkishMap = {
      'ç': 'c',
      'Ç': 'C',
      'ğ': 'g',
      'Ğ': 'G',
      'ı': 'i',
      'İ': 'I',
      'ö': 'o',
      'Ö': 'O',
      'ş': 's',
      'Ş': 'S',
      'ü': 'u',
      'Ü': 'U',
    };

    String result = text;
    turkishMap.forEach((turkishChar, asciiChar) {
      result = result.replaceAll(turkishChar, asciiChar);
    });

    return result;
  }

  static Future<void> printReceiptToPhysicalPrinter(
    List<Map<String, dynamic>> billItems, {
    LogCallback? onLog,
  }) async {
    print('\n🖨️ Fiziksel Yazıcıya Fiş Yazdırma başlatılıyor...');
    
    final settingsService = SettingsService();
    final printerName = await settingsService.getPrinterName();
    
    if (printerName.isEmpty) {
      print('❌ Yazıcı ismi bulunamadı. Lütür önce yazıcı ismini ayarlayın.');
      return;
    }

    int retryCount = 0;
    bool success = false;

    while (!success && retryCount < _maxRetries) {
      if (retryCount > 0) {
        print('🔄 Yeniden deneme ${retryCount + 1}/$_maxRetries...');
        await Future.delayed(_retryDelay);
      }

      success = await _tryPrintReceipt(printerName, billItems);
      if (!success) retryCount++;
    }

    if (!success) {
      print('❌ Maksimum deneme sayısına ulaşıldı. Yazdırma başarısız.');
    }
  }

  static Future<bool> _tryPrintReceipt(
    String printerName,
    List<Map<String, dynamic>> billItems,
  ) async {
    print('📌 Kullanılacak yazıcı: $printerName');
    final printerNamePtr = printerName.toNativeUtf16();
    final hPrinter = calloc<HANDLE>();

    try {
      print('🔌 Fiziksel yazıcı bağlantısı açılıyor...');
      if (OpenPrinter(printerNamePtr, hPrinter, nullptr) == 0) {
        final error = GetLastError();
        print('❌ Fiziksel yazıcı açılamadı. Hata kodu: $error');
        return false;
      }

      print('✅ Fiziksel yazıcı bağlantısı başarılı');

      print('📝 Yazdırma bilgileri hazırlanıyor...');
      final docInfo = calloc<DOC_INFO_1>()
        ..ref.pDocName = TEXT('Fis Yazdirma')
        ..ref.pOutputFile = nullptr
        ..ref.pDatatype = TEXT('RAW');

      try {
        print('🚀 Yazdırma işlemi başlatılıyor...');
        if (StartDocPrinter(hPrinter.value, 1, docInfo) == 0) {
          final error = GetLastError();
          print('❌ StartDocPrinter başarısız. Hata kodu: $error');
          return false;
        }

        print('✅ Yazdırma işlemi başlatıldı');

        print('📋 Fiş verisi hazırlanıyor...');
        final receiptData = _generateESCPosData(billItems);
        
        // Tüm komutları birleştir
        List<int> allBytes = [];
        
        // Fiş içeriğini byte'lara dönüştür
        for (int i = 0; i < receiptData.length; i++) {
          allBytes.add(receiptData.codeUnitAt(i));
        }
        
        // Kesme komutunu ekle
        allBytes.addAll([0x1D, 0x56, 0x41]); // GS V A
        
        // Tüm byte'ları native belleğe kopyala
        final printData = calloc<Uint8>(allBytes.length);
        for (int i = 0; i < allBytes.length; i++) {
          printData[i] = allBytes[i];
        }
        
        final bytesWritten = calloc<Uint32>();

        try {
          print('📤 Fiş verisi yazıcıya gönderiliyor...');
          print('📏 Gönderilecek veri boyutu: ${allBytes.length} byte');

          if (StartPagePrinter(hPrinter.value) == 0) {
            final error = GetLastError();
            print('❌ StartPagePrinter başarısız. Hata kodu: $error');
            return false;
          }

          // Tüm veriyi tek seferde gönder
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

          print('✅ Fiş yazdırma başarılı');
          print('📊 Toplam yazılan veri boyutu: ${bytesWritten.value} byte');
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
} 
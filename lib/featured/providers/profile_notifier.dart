import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foomoons/product/init/config/app_environment.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this.ref) : super(const ProfileState());

  final ImagePicker _picker = ImagePicker();
  final Ref ref; // Ref instance to manage the global provider
  DateTime? _lastFetchTime;
  static const _cacheValidityDuration = Duration(minutes: 30);

  Future<void> fetchCurrentBusinessInfo() async {
    final baseUrl = AppEnvironmentItems.baseUrl.value;
    final authService = ref.read(authServiceProvider);

    try {
      // BusinessId'yi AuthService'den al
      final businessId = await authService.getBusinessId();
      if (businessId == null) {
        throw Exception('BusinessId bulunamadı');
      }

      final response = await http
          .get(Uri.parse('$baseUrl/businesses/getbyid?id=$businessId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        state = state.copyWith(
          businessName: data['name'] ?? '',
          photoURL: data['photo'] ?? 'assets/images/coffee_icon.png',
          phoneNumber: data['phoneNumber'] ?? '',
          businessAddress: data['adress'] ?? '',
          businessInfo: data['info'] ?? '',
          isSelfService: data['isSelfService'] ?? false,
        );
      } else {
        throw Exception('İşletme bilgisi API hatası : ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e, 'İşletme bilgileri getirme hatası');
    }
  }

  Future<void> fetchUserInfo() async {
    try {
      final authService = ref.read(authServiceProvider);
      final userEmail = await authService.getUserEmail();

      if (userEmail != null) {
        final userResult = await authService.getUserByEmail(userEmail);
        if (userResult['success']) {
          print('>>> Kullanıcı bilgileri: ${userResult['data']}');
          final userData = userResult['data'];
          final firstName = userData['firstName'];
          final lastName = userData['lastName'];
          final phoneNumber = userData['phoneNumber'];
          final email = userData['email'];
          state = state.copyWith(
            name: '$firstName $lastName',
            email: email,
            userPhoneNumber: phoneNumber,
          );
        }
      }
    } catch (e) {
      _handleError(e, 'Kullanıcı bilgileri getirme hatası');
    }
  }

  Future<void> fetchAndLoad({bool forceRefresh = false}) async {
    if (!forceRefresh && _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration &&
        state.businessName != null) {
      print('🔄 Profile cache geçerli, veriler yüklü. Fetch atlanıyor.');
      return;
    }

    print('📥 Profile verileri fetch ediliyor...');
    ref.read(loadingProvider.notifier).setLoading('profile', true);
    try {
      await fetchUserInfo();
      await fetchCurrentBusinessInfo();
      await _loadPrinterIpAddress();
      await _loadPrinterName();
      await _loadPrinter2IpAddress();
      await _loadPrinter2Name();
      _lastFetchTime = DateTime.now();
      print('✅ Profile verileri başarıyla yüklendi ve cache güncellendi.');
    } catch (e) {
      print('❌ Profile veri yükleme hatası: $e');
      _lastFetchTime = null;
    } finally {
      ref.read(loadingProvider.notifier).setLoading('profile', false);
    }
  }

  Future<void> _loadPrinterIpAddress() async {
    try {
      final settingsService = ref.read(settingsServiceProvider);
      final ipAddress = await settingsService.getPrinterIpAddress();
      state = state.copyWith(printerIpAddress: ipAddress);
    } catch (e) {
      print('❌ Bar yazıcı IP adresi yüklenirken hata: $e');
    }
  }

  Future<void> _loadPrinterName() async {
    try {
      final settingsService = ref.read(settingsServiceProvider);
      final printerName = await settingsService.getPrinterName();
      state = state.copyWith(printerName: printerName);
    } catch (e) {
      print('❌ Bar yazıcı adı yüklenirken hata: $e');
    }
  }

  Future<void> _loadPrinter2IpAddress() async {
    try {
      final settingsService = ref.read(settingsServiceProvider);
      final ipAddress = await settingsService.getPrinter2IpAddress();
      state = state.copyWith(printer2IpAddress: ipAddress);
    } catch (e) {
      print('❌ Mutfak yazıcı IP adresi yüklenirken hata: $e');
    }
  }

  Future<void> _loadPrinter2Name() async {
    try {
      final settingsService = ref.read(settingsServiceProvider);
      final printerName = await settingsService.getPrinter2Name();
      state = state.copyWith(printer2Name: printerName);
    } catch (e) {
      print('❌ Mutfak yazıcı adı yüklenirken hata: $e');
    }
  }

  void updatePrinterIpAddress(String value) {
    state = state.copyWith(printerIpAddress: value);
  }

  void updatePrinterName(String value) {
    state = state.copyWith(printerName: value);
  }

  void updatePrinter2IpAddress(String value) {
    state = state.copyWith(printer2IpAddress: value);
  }

  void updatePrinter2Name(String value) {
    state = state.copyWith(printer2Name: value);
  }

  Future<void> savePrinterIpAddress() async {
    try {
      if (state.printerIpAddress != null) {
        final settingsService = ref.read(settingsServiceProvider);
        await settingsService.setPrinterIpAddress(state.printerIpAddress!);
        print('✅ Bar yazıcı IP adresi kaydedildi: ${state.printerIpAddress}');
      }
    } catch (e) {
      print('❌ Bar yazıcı IP adresi kaydedilirken hata: $e');
    }
  }

  Future<void> savePrinterName() async {
    try {
      if (state.printerName != null) {
        final settingsService = ref.read(settingsServiceProvider);
        await settingsService.setPrinterName(state.printerName!);
        print('✅ Bar yazıcı adı kaydedildi: ${state.printerName}');
      }
    } catch (e) {
      print('❌ Bar yazıcı adı kaydedilirken hata: $e');
    }
  }

  Future<void> savePrinter2IpAddress() async {
    try {
      if (state.printer2IpAddress != null) {
        final settingsService = ref.read(settingsServiceProvider);
        await settingsService.setPrinter2IpAddress(state.printer2IpAddress!);
        print('✅ Mutfak yazıcı IP adresi kaydedildi: ${state.printer2IpAddress}');
      }
    } catch (e) {
      print('❌ Mutfak yazıcı IP adresi kaydedilirken hata: $e');
    }
  }

  Future<void> savePrinter2Name() async {
    try {
      if (state.printer2Name != null) {
        final settingsService = ref.read(settingsServiceProvider);
        await settingsService.setPrinter2Name(state.printer2Name!);
        print('✅ Mutfak yazıcı adı kaydedildi: ${state.printer2Name}');
      }
    } catch (e) {
      print('❌ Mutfak yazıcı adı kaydedilirken hata: $e');
    }
  }

  Future<void> updateProfileInfo({
    required String fieldName,
    required String updatedValue,
  }) async {
    final baseUrl = AppEnvironmentItems.baseUrl.value;
    final authService = ref.read(authServiceProvider);
    try {
      final businessId = await authService.getBusinessId();
      if (businessId == null) {
        throw Exception('BusinessId bulunamadı');
      }

      // Handle combined business information update
      Map<String, dynamic> updateData = {
        'id': businessId,
        'photo': state.photoURL ?? 'assets/images/coffee_icon.png'
      };

      if (fieldName == 'businessAll') {
        final parts = updatedValue.split('|');
        if (parts.length == 3) {
          updateData.addAll({
            'name': parts[0],
            'adress': parts[1],
            'info': parts[2],
            'phoneNumber': state.phoneNumber,
            'photo': fieldName == 'photo' ? updatedValue : state.photoURL,
          });
        }
      } else {
        // Handle individual field updates
        updateData.addAll({
          'name': fieldName == 'businessName' ? updatedValue : state.businessName,
          'info': fieldName == 'businessInfo' ? updatedValue : state.businessInfo,
          'adress': fieldName == 'businessAddress' ? updatedValue : state.businessAddress,
          'phoneNumber': fieldName == 'phoneNumber' ? updatedValue : state.phoneNumber,
          'photo': fieldName == 'photo' ? updatedValue : state.photoURL,
        });
      }

      final response = await http.post(
        Uri.parse('$baseUrl/businesses/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      print('>>> Gönderilen alan: $fieldName, değer: $updatedValue');
      print('>>> API Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('>>> İşlem başarısı: ${responseData['success']}');
        print('>>> Gelen veri: ${responseData['data']}');

        if (responseData['success'] == true && responseData['data'] != null) {
          final businessData = responseData['data'];
          state = state.copyWith(
            businessName: businessData['name'],
            businessInfo: businessData['info'],
            businessAddress: businessData['adress'],
            phoneNumber: businessData['phoneNumber'],
            photoURL: businessData['photo'],
          );

          // Cache'i güncelleme
          _lastFetchTime = DateTime.now();
          print('>>> Profile verileri güncellendi ve cache yenilendi.');
          print('>>> Yeni state değerleri:');
          print('   - İşletme Adı: ${state.businessName}');
          print('   - Adres: ${state.businessAddress}');
          print('   - Bilgi: ${state.businessInfo}');
          print('   - Telefon: ${state.phoneNumber}');
        } else {
          print('!!! API yanıtında data bulunamadı');
          throw Exception('API yanıtında data bulunamadı');
        }
      } else {
        print('!!! API hatası: ${response.statusCode}');
        throw Exception('Güncelleme başarısız: ${response.statusCode}');
      }
    } catch (e) {
      print('!!! Hata oluştu: $e');
      _handleError(e, 'Profil güncellenirken hata oluştu');
      _lastFetchTime = null;
    }
  }

  // Profil resmi URL'sini Firestore'da günceller
  Future<void> updateProfilePhotoURL(String photoURL, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'photoURL': photoURL,
      });
      // Local state'i güncelle
      state = state.copyWith(photoURL: photoURL);
    } catch (e) {
      print('Profil fotoğrafı güncellenirken hata oluştu: $e');
    }
  }

  Future<bool> pickAndUploadBusinessImage() async {
    try {
      final authService = ref.read(authServiceProvider);
      final businessId = await authService.getBusinessId();

      if (businessId == null) {
        throw Exception('Kullanıcı oturum açmamış veya işletme ID bulunamadı');
      }

      // Configure image picker for iOS compatibility
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
        requestFullMetadata: true, // Enable full metadata for iOS
      ).timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw Exception('Fotoğraf seçimi zaman aşımına uğradı');
        },
      );

      if (pickedFile != null) {
        state = state.copyWith(isUploading: true);

        try {
          // For iOS, we need to ensure the image is fully downloaded
          Uint8List? imageBytes;
          int retryCount = 0;
          const maxRetries = 3;

          while (retryCount < maxRetries && (imageBytes == null || imageBytes.isEmpty)) {
            try {
              imageBytes = await pickedFile.readAsBytes();
              if (imageBytes.isEmpty) {
                throw Exception('Resim verisi boş');
              }
            } catch (e) {
              retryCount++;
              if (retryCount >= maxRetries) throw e;
              await Future.delayed(Duration(seconds: retryCount));
              continue;
            }
          }

          if (imageBytes == null || imageBytes.isEmpty) {
            throw Exception('Resim yüklenemedi');
          }

          final String fileName = 'business_photos/$businessId.jpg';
          
          // Upload to Firebase Storage
          final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
          
          final UploadTask uploadTask = storageRef.putData(
            imageBytes,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {'businessId': businessId.toString()},
            ),
          );

          // Monitor upload progress
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            print('Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
          });

          final TaskSnapshot snapshot = await uploadTask;
          final String downloadURL = await snapshot.ref.getDownloadURL();

          // Update business photo URL in the backend
          await updateProfileInfo(
            fieldName: 'photo',
            updatedValue: downloadURL,
          );
          return true;

        } catch (e) {
          print('Resim işlenirken hata oluştu: $e');
          return false;
        }
      }
      return false;
    } catch (e, stackTrace) {
      print('İşletme fotoğrafı yüklenirken hata oluştu: $e');
      print('Hata Yığını: $stackTrace');
      return false;
    } finally {
      state = state.copyWith(isUploading: false);
    }
  }

  /// Hata yönetimi
  void _handleError(Object e, String message) {
    print(
        '$message: $e'); // Hataları loglayın veya bir hata yönetimi mekanizması kullanın
  }

  // Reset profile state
  void resetProfile() {
    state = const ProfileState();
  }

  void invalidateCache() {
    _lastFetchTime = null;
    print('🔄 Profile cache geçersiz kılındı.');
  }
}

// State class to hold profile data
class ProfileState {
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? userPhoneNumber;
  final String? businessName;
  final String? businessAddress;
  final String? businessInfo;
  final String? errorMessage;
  final String? photoURL;
  final bool isUploading;
  final String? printerIpAddress;
  final String? printerName;
  final String? printer2IpAddress;
  final String? printer2Name;
  final bool? isSelfService;
  const ProfileState({
    this.name,
    this.email,
    this.phoneNumber,
    this.userPhoneNumber,
    this.businessName,
    this.businessAddress,
    this.businessInfo,
    this.errorMessage,
    this.photoURL,
    this.isUploading = false,
    this.printerIpAddress,
    this.printerName,
    this.printer2IpAddress,
    this.printer2Name,
    this.isSelfService,
  });

  ProfileState copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? userPhoneNumber,
    String? businessName,
    String? businessAddress,
    String? businessInfo,
    String? errorMessage,
    String? photoURL,
    bool? isUploading,
    String? printerIpAddress,
    String? printerName,
    String? printer2IpAddress,
    String? printer2Name,
    bool? isSelfService,
  }) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessInfo: businessInfo ?? this.businessInfo,
      errorMessage: errorMessage ?? this.errorMessage,
      photoURL: photoURL ?? this.photoURL,
      isUploading: isUploading ?? this.isUploading,
      printerIpAddress: printerIpAddress ?? this.printerIpAddress,
      printerName: printerName ?? this.printerName,
      printer2IpAddress: printer2IpAddress ?? this.printer2IpAddress,
      printer2Name: printer2Name ?? this.printer2Name,
      isSelfService: isSelfService ?? this.isSelfService,
    );
  }
}

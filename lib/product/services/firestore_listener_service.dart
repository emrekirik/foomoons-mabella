import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/main.dart';
import 'package:audioplayers/audioplayers.dart';

class FirestoreListenerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _subscription;
  final Ref _ref;
  bool _isInitialLoad = true;  // İlk yükleme flag'i
  bool _isInitialized = false; // Servisin initialize edilip edilmediğini kontrol eden flag
  AudioPlayer? _audioPlayer;

  FirestoreListenerService(this._ref) {
    debugPrint('🔵 FirestoreListenerService: Servis oluşturuldu');
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer?.setReleaseMode(ReleaseMode.release);
      debugPrint('🟢 FirestoreListenerService: AudioPlayer başarıyla oluşturuldu');
    } catch (e) {
      debugPrint('🔴 FirestoreListenerService: AudioPlayer oluşturma hatası: $e');
    }
  }

  Future<void> initialize() async {
    // Eğer zaten initialize edilmişse, tekrar etme
    if (_isInitialized) {
      debugPrint('🔵 FirestoreListenerService: Servis zaten initialize edilmiş, tekrar initialize edilmiyor');
      return;
    }

    debugPrint('🔵 FirestoreListenerService: initialize başlatıldı');
    
    // Skip for iOS platform
    if (Platform.isIOS) {
      debugPrint('🔴 FirestoreListenerService: iOS platformunda çalıştırılmadı');
      return;
    }

    try {
      // Eğer varsa eski subscription'ı temizle
      await _subscription?.cancel();
      _subscription = null;

      final authService = _ref.read(authServiceProvider);
      final businessId = await authService.getValidatedBusinessId();

      debugPrint('🔵 FirestoreListenerService: BusinessId alındı: $businessId');

      // Create query for notifications collection filtered by businessId
      final query = _firestore
          .collection('notifications')
          .where('cafeId', isEqualTo: businessId.toString());
          // .orderBy('timestamp', descending: true); // Geçici olarak kaldırıldı

      debugPrint('🔵 FirestoreListenerService: Firestore sorgusu oluşturuldu');
      debugPrint('🔵 FirestoreListenerService: Collection: notifications');
      debugPrint('🔵 FirestoreListenerService: Filter: cafeId = ${businessId.toString()} (String olarak)');
      debugPrint('⚠️ Not: Bu sorgu için Firebase Console\'da composite index oluşturulmalı:');
      debugPrint('⚠️ Collection: notifications');
      debugPrint('⚠️ Fields to index: cafeId (Ascending) + timestamp (Descending)');

      // Subscribe to query
      _subscription = query.snapshots().listen(
        (snapshot) async {
          debugPrint('🔵 FirestoreListenerService: Snapshot alındı');
          debugPrint('🔵 FirestoreListenerService: Toplam döküman sayısı: ${snapshot.docs.length}');
          debugPrint('🔵 FirestoreListenerService: Değişiklik sayısı: ${snapshot.docChanges.length}');
          
          if (_isInitialLoad) {
            debugPrint('🔵 FirestoreListenerService: İlk yükleme, mevcut bildirimler atlanıyor');
            _isInitialLoad = false;
            return;
          }

          if (snapshot.docChanges.isNotEmpty) {
            for (var change in snapshot.docChanges) {
              final data = change.doc.data() as Map<String, dynamic>;
              debugPrint('🔵 FirestoreListenerService: Değişiklik tipi: ${change.type}');
              debugPrint('🔵 FirestoreListenerService: Döküman ID: ${change.doc.id}');
              
              if (change.type == DocumentChangeType.added) {
                debugPrint('🟢 FirestoreListenerService: Yeni sipariş alındı!');
                debugPrint('🟢 FirestoreListenerService: Sipariş verisi: $data');
                debugPrint('🟢 FirestoreListenerService: Timestamp: ${data['timestamp']}');

                // Show notification
                _showNotification('Yeni sipariş alındı!');

                // Refresh orders data
                debugPrint('🔵 FirestoreListenerService: Siparişler yenileniyor...');
                await _ref.read(adminProvider.notifier).fetchAndLoad(forceRefresh: true);
                debugPrint('🟢 FirestoreListenerService: Siparişler başarıyla yenilendi');

                // Delete the notification document
                try {
                  await _firestore.collection('notifications').doc(change.doc.id).delete();
                  debugPrint('🟢 FirestoreListenerService: Bildirim başarıyla silindi (ID: ${change.doc.id})');
                } catch (e) {
                  debugPrint('🔴 FirestoreListenerService: Bildirim silinirken hata oluştu: $e');
                }
              }
            }
          } else {
            debugPrint('🔵 FirestoreListenerService: Değişiklik yok');
          }
        },
        onError: (error) {
          debugPrint('🔴 FirestoreListenerService: Dinleme hatası: $error');
        },
      );

      _isInitialized = true; // Initialize başarılı olduğunda flag'i güncelle
      debugPrint('🟢 FirestoreListenerService: Dinleme başarıyla başlatıldı (businessId: $businessId)');
    } catch (e) {
      debugPrint('🔴 FirestoreListenerService: Başlatma hatası: $e');
    }
  }

  void _showNotification(String message) async {
    final context = _ref.read(navigatorKeyProvider).currentContext;
    if (context != null) {
      // Bildirim sesini çal
      try {
        if (_audioPlayer == null) {
          await _initAudioPlayer();
        }
        
        await _audioPlayer?.stop(); // Önceki sesi durdur
        await _audioPlayer?.setVolume(1.0); // Ses seviyesini ayarla
        await _audioPlayer?.play(AssetSource('sounds/notification.mp3'));
        debugPrint('🟢 FirestoreListenerService: Bildirim sesi çalındı');
      } catch (e) {
        debugPrint('🔴 FirestoreListenerService: Bildirim sesi çalınamadı: $e');
        // Hata durumunda AudioPlayer'ı yeniden başlatmayı dene
        _audioPlayer?.dispose();
        _audioPlayer = null;
        await _initAudioPlayer();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            right: 20,
            left: 20,
          ),
        ),
      );
    }
  }

  void dispose() {
    debugPrint('🔵 FirestoreListenerService: Servis kapatılıyor...');
    _subscription?.cancel();
    _audioPlayer?.dispose(); // AudioPlayer'ı temizle
    _audioPlayer = null;
    _isInitialLoad = true;
    _isInitialized = false;
    debugPrint('🟢 FirestoreListenerService: Servis başarıyla kapatıldı');
  }
} 
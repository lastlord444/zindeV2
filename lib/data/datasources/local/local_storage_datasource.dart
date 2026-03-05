// lib/data/datasources/local/local_storage_datasource.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';

/// Yerel depolama veri kaynağı (SharedPreferences)
/// Profil, plan önbelleği iin kullanılır
class LocalStorageDataSource {
  static const String _profilKey = 'kullanici_profili';
  static const String _gunlukPlanPrefixKey = 'gunluk_plan_';
  static const String _favoriPrefix = 'favori_yemekler';

  // ─── Profil ────────────────────────────────────────────────────────────────
  /// Profil JSON'ın1 kaydet
  Future<void> profilKaydet(Map<String, dynamic> profilJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profilKey, json.encode(profilJson));
      AppLogger.debug('Profil yerel depoya kaydedildi');
    } catch (e) {
      throw Exception('Profil kaydedilemedi: $e'); // Fixed DepolamaIstisnasi call syntax if custom Exception required, throwing standard Exception here
    }
  }

  /// Profil JSON'ın1 getir
  Future<String?> profilGetir() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_profilKey);
    } catch (e) {
      AppLogger.uyari('Profil yerel depodan alınamad1: $e');
      return null;
    }
  }

  /// Profili sil
  Future<void> profilSil() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profilKey);
  }

  // ─── Günlük Plan Önbellek ─────────────────────────────────────────────────
  /// Plan JSON'ın1 önbelleğe kaydet (tarih key)
  Future<void> planKaydet(String tarihKey, String planJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_gunlukPlanPrefixKey$tarihKey', planJson);
    } catch (e) {
      AppLogger.uyari('Plan önbelleğe kaydedilemedi: $e');
    }
  }

  /// Önbellekten plan getir
  Future<String?> planGetir(String tarihKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_gunlukPlanPrefixKey$tarihKey');
    } catch (e) {
      return null;
    }
  }

  /// Belirli bir planın önbelleğini sil
  Future<void> planSil(String tarihKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_gunlukPlanPrefixKey$tarihKey');
    AppLogger.debug('$tarihKey önbelleği silindi');
  }

  /// Tüm önbelleği temizle
  Future<void> tumPlanlariTemizle() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) => k.startsWith(_gunlukPlanPrefixKey))
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    AppLogger.debug('Tüm plan önbelleği temizlendi');
  }

  // ─── Favori Yemekler ──────────────────────────────────────────────────────
  /// Favori yemek ID listesini getir
  Future<List<String>> favoriIdleriGetir() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_favoriPrefix) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Favorilere ekle
  Future<void> favoriyeEkle(String yemekId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriler = prefs.getStringList(_favoriPrefix) ?? [];
    if (!favoriler.contains(yemekId)) {
      favoriler.add(yemekId);
      await prefs.setStringList(_favoriPrefix, favoriler);
    }
  }

  /// Favorilerden ıkar
  Future<void> favoridenCikar(String yemekId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriler = prefs.getStringList(_favoriPrefix) ?? [];
    favoriler.remove(yemekId);
    await prefs.setStringList(_favoriPrefix, favoriler);
  }
}

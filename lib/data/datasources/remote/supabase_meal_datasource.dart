// lib/data/datasources/remote/supabase_meal_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../core/utils/formatters.dart';

/// Supabase yemek plan1 veri kaynağı
class SupabaseMealDataSource {
  final SupabaseClient _client;

  SupabaseMealDataSource(this._client);

  /// Tüm yemekleri getir
  Future<List<Map<String, dynamic>>> tumYemekleriGetir() async {
    try {
      List<Map<String, dynamic>> tumYemekler = [];
      int offset = 0;
      const int limit = 1000;

      while (true) {
        final batch = await _client
            .from('meals')
            .select()
            .range(offset, offset + limit - 1);
            
        if (batch.isEmpty) break;
        
        // Convert dynamic maps to Map<String, dynamic> 
        final typedBatch = batch.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
        tumYemekler.addAll(typedBatch);

        if (batch.length < limit) break;
        offset += limit;
      }
      
      AppLogger.bilgi('Veritabanından toplam ${tumYemekler.length} yemek başarıyla çekildi.');
      return tumYemekler;
    } on PostgrestException catch (e) {
      AppLogger.hata('Tüm yemekleri getirme hatas1', e);
      throw SunucuIstisnasi(mesaj: e.message);
    }
  }

  // ─── Günlük Plan ─────────────────────────────────────────────────────────
  /// Günlük plan1 getir
  Future<Map<String, dynamic>?> gunlukPlanGetir(
      String userId, DateTime tarih) async {
    try {
      final tarihStr = Formatters.supabaseGunFormatla(tarih);
      final sonuc = await _client
          .from(SupabaseConfig.tabloDailyPlans)
          .select()
          .eq('user_id', userId)
          .eq('tarih', tarihStr)
          .maybeSingle();
      return sonuc;
    } on PostgrestException catch (e) {
      AppLogger.hata('Günlük plan getirme hatas1', e);
      throw SunucuIstisnasi(mesaj: e.message);
    }
  }

  /// Günlük plan1 kaydet (upsert)
  Future<Map<String, dynamic>> gunlukPlanKaydet(
      Map<String, dynamic> planData) async {
    try {
      final sonuc = await _client
          .from(SupabaseConfig.tabloDailyPlans)
          .upsert(planData, onConflict: 'user_id,tarih')
          .select()
          .single();
      AppLogger.bilgi('Günlük plan Supabase\'e kaydedildi');
      return sonuc;
    } on PostgrestException catch (e) {
      AppLogger.hata('Günlük plan kaydetme hatas1', e);
      throw SunucuIstisnasi(mesaj: e.message);
    }
  }

  /// Haftalık planlar1 getir
  Future<List<Map<String, dynamic>>> haftalikPlanlarGetir(
      String userId, DateTime baslangic) async {
    try {
      final baslangicStr = Formatters.supabaseGunFormatla(baslangic);
      final bitisStr = Formatters.supabaseGunFormatla(
          baslangic.add(const Duration(days: 6)));

      final sonuclar = await _client
          .from(SupabaseConfig.tabloDailyPlans)
          .select()
          .eq('user_id', userId)
          .gte('tarih', baslangicStr)
          .lte('tarih', bitisStr)
          .order('tarih');

      return sonuclar;
    } on PostgrestException catch (e) {
      throw SunucuIstisnasi(mesaj: e.message);
    }
  }

  /// Öğün durumunu güncelle
  Future<void> ogunDurumKaydet({
    required String userId,
    required DateTime tarih,
    required String yemekId,
    required String durum,
  }) async {
    try {
      final tarihStr = Formatters.supabaseGunFormatla(tarih);
      await _client.from(SupabaseConfig.tabloMealConfirmations).upsert({
        'user_id': userId,
        'yemek_id': yemekId,
        'tarih': tarihStr,
        'durum': durum,
      }, onConflict: 'user_id,yemek_id,tarih');
    } on PostgrestException catch (e) {
      throw SunucuIstisnasi(mesaj: e.message);
    }
  }

  /// Günün öğün durumların1 getir
  Future<List<Map<String, dynamic>>> ogunDurumlariGetir(
      String userId, DateTime tarih) async {
    try {
      final tarihStr = Formatters.supabaseGunFormatla(tarih);
      return await _client
          .from(SupabaseConfig.tabloMealConfirmations)
          .select()
          .eq('user_id', userId)
          .eq('tarih', tarihStr);
    } on PostgrestException catch (e) {
      throw SunucuIstisnasi(mesaj: e.message);
    }
  }

  /// Plan1 sil
  Future<void> gunlukPlanSil(String userId, DateTime tarih) async {
    try {
      final tarihStr = Formatters.supabaseGunFormatla(tarih);
      await _client
          .from(SupabaseConfig.tabloDailyPlans)
          .delete()
          .eq('user_id', userId)
          .eq('tarih', tarihStr);
    } on PostgrestException catch (e) {
      throw SunucuIstisnasi(mesaj: e.message);
    }
  }
}

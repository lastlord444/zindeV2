// lib/data/datasources/remote/supabase_user_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../domain/entities/user/kullanici_profili.dart';
import '../../../../core/utils/logger.dart';

/// Supabase kullanıc1 profil veri kaynağı
class SupabaseUserDataSource {
  final SupabaseClient _client;

  SupabaseUserDataSource(this._client);

  /// Kullanıc1 profilini getir
  Future<Map<String, dynamic>?> profilGetir(String userId) async {
    try {
      final sonuc = await _client
          .from(SupabaseConfig.tabloKullaniciProfili)
          .select()
          .eq('id', userId)
          .maybeSingle();
      return sonuc;
    } on PostgrestException catch (e) {
      AppLogger.hata('Supabase profil getirme hatas1', e);
      throw SunucuIstisnasi(mesaj: e.message, statusKodu: int.tryParse(e.code ?? '0'));
    } catch (e) {
      throw SunucuIstisnasi(mesaj: e.toString());
    }
  }

  /// Kullanıc1 profilini kaydet (upsert)
  Future<Map<String, dynamic>> profilKaydet(Map<String, dynamic> profilData) async {
    try {
      final sonuc = await _client
          .from(SupabaseConfig.tabloKullaniciProfili)
          .upsert(profilData, onConflict: 'id')
          .select()
          .single();
      AppLogger.bilgi('Profil Supabase\'e kaydedildi');
      return sonuc;
    } on PostgrestException catch (e) {
      AppLogger.hata('Supabase profil kaydetme hatas1', e);
      throw SunucuIstisnasi(mesaj: e.message);
    } catch (e) {
      throw SunucuIstisnasi(mesaj: e.toString());
    }
  }

  /// Kullanıc1 profilini sil
  Future<void> profilSil(String userId) async {
    try {
      await _client
          .from(SupabaseConfig.tabloKullaniciProfili)
          .delete()
          .eq('id', userId);
    } on PostgrestException catch (e) {
      throw SunucuIstisnasi(mesaj: e.message);
    }
  }

  /// Mevcut oturum amış kullanıcının ID'sini getir
  String? get mevcutKullaniciId => _client.auth.currentUser?.id;
}

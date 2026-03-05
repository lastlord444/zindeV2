// lib/data/repositories/user_repository_impl.dart

import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/logger.dart';
import '../../domain/entities/user/kullanici_profili.dart';
import '../../domain/entities/user/hedef.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/remote/supabase_user_datasource.dart';
import '../datasources/local/local_storage_datasource.dart';

/// Kullanıc1 profil repository implementasyonu
class UserRepositoryImpl implements UserRepository {
  final SupabaseUserDataSource _remote;
  final LocalStorageDataSource _local;

  const UserRepositoryImpl({
    required SupabaseUserDataSource remote,
    required LocalStorageDataSource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<Either<Failure, KullaniciProfili?>> profilGetir(String userId) async {
    try {
      // 1. Supabase'den getir
      final data = await _remote.profilGetir(userId);
      if (data == null) return const Right(null);
      final profil = _jsondenProfilOlustur(data);
      return Right(profil);
    } on SunucuIstisnasi catch (e) {
      AppLogger.uyari('Supabase hatas1, yerel depoya bakılıyor: ${e.mesaj}');
      // Supabase başarısız → yerel önbellekten getir
      final yerelJson = await _local.profilGetir();
      if (yerelJson != null) {
        try {
          final profil = KullaniciProfili.fromJson(json.decode(yerelJson));
          return Right(profil);
        } catch (_) {}
      }
      return Left(SunucuHatasi(e.mesaj));
    } catch (e) {
      return Left(BilinmeyenHata(e.toString()));
    }
  }

  @override
  Future<Either<Failure, KullaniciProfili>> profilKaydet(
      KullaniciProfili profil) async {
    try {
      final userId = _remote.mevcutKullaniciId ?? profil.id;
      final data = {
        'id': userId,
        'ad': profil.ad,
        'soyad': profil.soyad,
        'yas': profil.yas,
        'boy': profil.boy,
        'mevcut_kilo': profil.mevcutKilo,
        'hedef_kilo': profil.hedefKilo,
        'cinsiyet': profil.cinsiyet.name,
        'aktivite_seviyesi': profil.aktiviteSeviyesi.name,
        'hedef': profil.hedef.name,
        'diyet_tipi': profil.diyetTipi.name,
        'manuel_alerjiler': profil.manuelAlerjiler,
        'kayit_tarihi': profil.kayitTarihi.toIso8601String(),
      };

      await _remote.profilKaydet(data);

      // Yerel önbelleğe de kaydet
      await _local.profilKaydet(profil.toJson());
      AppLogger.bilgi('Profil başarıyla kaydedildi: ${profil.ad}');

      return Right(profil);
    } on SunucuIstisnasi catch (e) {
      // Sadece yerel kaydet (offline mod)
      await _local.profilKaydet(profil.toJson());
      AppLogger.uyari('Supabase hatas1, yalnızca yerel depoland1: ${e.mesaj}');
      return Right(profil);
    } catch (e) {
      return Left(BilinmeyenHata(e.toString()));
    }
  }

  @override
  Future<Either<Failure, KullaniciProfili>> profilGuncelle(
      KullaniciProfili profil) => profilKaydet(profil);

  @override
  Future<Either<Failure, void>> profilSil(String userId) async {
    try {
      await _remote.profilSil(userId);
      await _local.profilSil();
      return const Right(null);
    } on SunucuIstisnasi catch (e) {
      return Left(SunucuHatasi(e.mesaj));
    }
  }

  @override
  Future<KullaniciProfili?> onbellektenProfilGetir() async {
    final yerelJson = await _local.profilGetir();
    if (yerelJson == null) return null;
    try {
      return KullaniciProfili.fromJson(json.decode(yerelJson));
    } catch (_) {
      return null;
    }
  }

  // ─── Yardımc1 ─────────────────────────────────────────────────────────────
  KullaniciProfili _jsondenProfilOlustur(Map<String, dynamic> data) {
    return KullaniciProfili(
      id: data['user_id']?.toString() ?? data['id']?.toString() ?? '',
      ad: data['ad'] as String,
      soyad: data['soyad'] as String,
      yas: data['yas'] as int,
      boy: (data['boy'] as num).toDouble(),
      mevcutKilo: (data['mevcut_kilo'] as num).toDouble(),
      hedefKilo: data['hedef_kilo'] != null
          ? (data['hedef_kilo'] as num).toDouble()
          : null,
      cinsiyet: Cinsiyet.values
          .firstWhere((e) => e.name == data['cinsiyet']),
      aktiviteSeviyesi: AktiviteSeviyesi.values
          .firstWhere((e) => e.name == data['aktivite_seviyesi']),
      hedef: Hedef.values.firstWhere((e) => e.name == data['hedef']),
      diyetTipi: DiyetTipi.values
          .firstWhere((e) => e.name == data['diyet_tipi']),
      manuelAlerjiler: (data['manuel_alerjiler'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      kayitTarihi: DateTime.parse(data['kayit_tarihi']?.toString() ??
          DateTime.now().toIso8601String()),
    );
  }
}

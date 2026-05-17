// lib/data/repositories/meal_plan_repository_impl.dart

import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/logger.dart';
import '../../domain/entities/nutrition/gunluk_plan.dart';
import '../../domain/entities/nutrition/makro_hedefleri.dart';
import '../../domain/entities/nutrition/yemek.dart';
import '../../domain/repositories/meal_plan_repository.dart';
import '../../domain/usecases/meal_planning/generate_daily_plan.dart';
import '../datasources/remote/supabase_meal_datasource.dart';
import '../datasources/local/local_storage_datasource.dart';

/// Yemek plan1 repository implementasyonu
class MealPlanRepositoryImpl implements MealPlanRepository {
  final SupabaseMealDataSource _remote;
  final LocalStorageDataSource _local;
  final GenerateDailyPlan _generateDailyPlan;

  const MealPlanRepositoryImpl({
    required SupabaseMealDataSource remote,
    required LocalStorageDataSource local,
    required GenerateDailyPlan generateDailyPlan,
  })  : _remote = remote,
        _local = local,
        _generateDailyPlan = generateDailyPlan;

  @override
  Future<Either<Failure, GunlukPlan?>> gunlukPlanGetir(
      String userId, DateTime tarih) async {
    try {
      final tarihKey = Formatters.supabaseGunFormatla(tarih);

      // Önce Supabase'den dene
      final data = await _remote.gunlukPlanGetir(userId, tarih);
      if (data != null) {
        final plan = _jsondenPlanOlustur(data);
        // Yerel önbelleğe kaydet
        await _local.planKaydet(tarihKey, json.encode(data));
        return Right(plan);
      }

      // Supabase'de yoksa yerel önbellekten bak
      final yerelJson = await _local.planGetir(tarihKey);
      if (yerelJson != null) {
        final plan = _jsondenPlanOlustur(json.decode(yerelJson));
        return Right(plan);
      }

      return const Right(null);
    } on SunucuIstisnasi catch (e) {
      // Yerel önbellekten dön
      final tarihKey = Formatters.supabaseGunFormatla(tarih);
      final yerelJson = await _local.planGetir(tarihKey);
      if (yerelJson != null) {
        final plan = _jsondenPlanOlustur(json.decode(yerelJson));
        return Right(plan);
      }
      return Left(SunucuHatasi(e.mesaj));
    } catch (e) {
      return Left(BilinmeyenHata(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GunlukPlan>> gunlukPlanOlustur({
    required String userId,
    required DateTime tarih,
    required MakroHedefleri hedefler,
    required List<Yemek> yemekHavuzu,
    required String hedef,
    required List<String> kisitlamalar,
    Map<String, int> haftalikKullanilanYemekler = const {},
  }) async {
    // Plan oluştur
    final planResult = await _generateDailyPlan(
      planId: '${userId}_${Formatters.supabaseGunFormatla(tarih)}',
      userId: userId,
      tarih: tarih,
      hedefler: hedefler,
      yemekHavuzu: yemekHavuzu,
      hedef: hedef,
      kisitlamalar: kisitlamalar,
      haftalikKullanilanYemekler: haftalikKullanilanYemekler,
    );

    return planResult.fold(
      (failure) => Left(failure),
      (plan) async {
        // Supabase'e kaydet
        return await gunlukPlanGuncelle(plan);
      },
    );
  }

  @override
  Future<Either<Failure, GunlukPlan>> gunlukPlanGuncelle(
      GunlukPlan plan) async {
    try {
      final data = _planToSupabaseJson(plan);
      await _remote.gunlukPlanKaydet(data);

      // Yerel önbelleğe kaydet
      final tarihKey = Formatters.supabaseGunFormatla(plan.tarih);
      await _local.planKaydet(tarihKey, json.encode(data));

      return Right(plan);
    } on SunucuIstisnasi catch (e) {
      AppLogger.uyari('Supabase hatas1, yalnızca yerel depoland1: ${e.mesaj}');
      return Right(plan);
    } catch (e) {
      return Left(BilinmeyenHata(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GunlukPlan>> ogunDurumuGuncelle({
    required String userId,
    required DateTime tarih,
    required String yemekId,
    required String durum,
  }) async {
    try {
      // Durum validasyonu - sadece geçerli durumları kabul et
      final gecerliDurumlar = ['bekliyor', 'yedi', 'onaylandi', 'atandi'];
      if (!gecerliDurumlar.contains(durum)) {
        return Left(BilinmeyenHata('Geçersiz durum: $durum'));
      }

      // Mevcut planı getir (in-memory cache'den veya DB'den)
      final planResult = await gunlukPlanGetir(userId, tarih);
      return planResult.fold(
        (f) => Left(f),
        (plan) async {
          if (plan == null) return const Left(BulunamadiHatasi('Plan bulunamadı'));
          
          // Yeni durum map'ini oluştur (in-memory, bilgi kaybı yok)
          final yeniDurumlar = Map<String, String>.from(plan.ogunDurumlari);
          yeniDurumlar[yemekId] = durum;
          
          final guncelPlan = plan.copyWith(
            ogunDurumlari: yeniDurumlar,
          );
          
          // Supabase'e güncellenmiş durumları kaydet (async fire-and-forget)
          try {
            await _remote.ogunDurumKaydet(
              userId: userId,
              tarih: tarih,
              yemekId: yemekId,
              durum: durum,
            );
          } catch (e) {
            AppLogger.uyari('Supabase durum kaydetme hatası: $e');
          }
          
          // Güncellenen planı hem yerel hem uzak veritabanına kaydet
          final kaydetResult = await gunlukPlanGuncelle(guncelPlan);
          return kaydetResult.fold(
            (f) => Right(guncelPlan), // Yerel kaydedildi bile, kullanıcıya güncel planı dön
            (savedPlan) => Right(guncelPlan),
          );
        },
      );
    } on SunucuIstisnasi catch (e) {
      return Left(SunucuHatasi(e.mesaj));
    }
  }

  @override
  Future<Either<Failure, List<GunlukPlan>>> haftalikPlanlarGetir(
      String userId, DateTime baslangic) async {
    try {
      final veriler = await _remote.haftalikPlanlarGetir(userId, baslangic);
      final planlar = veriler.map((d) => _jsondenPlanOlustur(d)).toList();
      return Right(planlar);
    } on SunucuIstisnasi catch (e) {
      return Left(SunucuHatasi(e.mesaj));
    }
  }

  @override
  Future<Either<Failure, void>> gunlukPlanSil(
      String userId, DateTime tarih) async {
    try {
      await _remote.gunlukPlanSil(userId, tarih);
      final tarihKey = Formatters.supabaseGunFormatla(tarih);
      await _local.planSil(tarihKey); // BUG FIXED: Eskiden planGetir cagrilip havada birakiliyordu
      return const Right(null);
    } on SunucuIstisnasi catch (e) {
      return Left(SunucuHatasi(e.mesaj));
    }
  }

  // ─── Yardımcılar ─────────────────────────────────────────────────────────
  GunlukPlan _jsondenPlanOlustur(Map<String, dynamic> data) {
    Yemek? parseYemek(dynamic json) {
      if (json == null) return null;
      final map = json is String ? jsonDecode(json) : json;
      return Yemek.fromJson(map as Map<String, dynamic>);
    }

    MakroHedefleri parseMakro(dynamic json) {
      final map = json is String ? jsonDecode(json) : json;
      return MakroHedefleri.fromJson(map as Map<String, dynamic>);
    }

    Map<String, String> parseOgunDurumlari(dynamic json) {
      if (json == null) return {};
      final map = json is String ? jsonDecode(json) : json;
      if (map is Map<String, dynamic>) {
        final result = <String, String>{};
        for (final entry in map.entries) {
          if (entry.value is bool) {
            // V1 format: Map<String, bool> → V2 format
            result[entry.key] = entry.value == true ? 'onaylandi' : 'bekliyor';
          } else if (entry.value is String) {
            // V2 format: Map<String, String> - doğrudan kullan
            result[entry.key] = entry.value;
          } else {
            result[entry.key] = 'bekliyor';
          }
        }
        return result;
      }
      return {};
    }

    return GunlukPlan(
      id: data['id']?.toString() ?? '',
      userId: data['user_id']?.toString() ?? '',
      tarih: DateTime.parse(data['tarih']?.toString() ?? DateTime.now().toIso8601String()),
      hedefler: parseMakro(data['hedefler']),
      kahvalti: parseYemek(data['kahvalti']),
      araOgun1: parseYemek(data['ara_ogun_1']),
      ogleYemegi: parseYemek(data['ogle']),
      araOgun2: parseYemek(data['ara_ogun_2']),
      aksamYemegi: parseYemek(data['aksam']),
      geceAtistirma: parseYemek(data['gece_atistirmasi'] ?? data['gece_atistirma']),
      ogunDurumlari: parseOgunDurumlari(data['ogun_durumlari'] ?? data['tamamlanan_ogunler']),
    );
  }

  Map<String, dynamic> _planToSupabaseJson(GunlukPlan plan) {
    // V2 format: 4-durumlu string map kaydet
    // Hem V1 uyumluluk hem V2 durumlarını taşır
    final encodedOgunDurumlari = <String, dynamic>{};
    plan.ogunDurumlari.forEach((yemekId, durum) {
      encodedOgunDurumlari[yemekId] = durum; // V2: string olarak kaydet
    });

    return {
      'user_id': plan.userId,
      'tarih': Formatters.supabaseGunFormatla(plan.tarih),
      'kahvalti': plan.kahvalti?.toJson(),
      'ara_ogun_1': plan.araOgun1?.toJson(),
      'ogle': plan.ogleYemegi?.toJson(),
      'ara_ogun_2': plan.araOgun2?.toJson(),
      'aksam': plan.aksamYemegi?.toJson(),
      'gece_atistirmasi': plan.geceAtistirma?.toJson(),
      'hedefler': plan.hedefler.toJson(),
      // V2 format: string durumları kaydet (V1 tamamlanan_ogunler alanına)
      'tamamlanan_ogunler': encodedOgunDurumlari,
    };
  }
}

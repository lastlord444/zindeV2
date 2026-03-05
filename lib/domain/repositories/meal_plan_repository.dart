// lib/domain/repositories/meal_plan_repository.dart

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../entities/nutrition/gunluk_plan.dart';
import '../entities/nutrition/makro_hedefleri.dart';
import '../entities/nutrition/yemek.dart';

/// Yemek plan1 repository arayüzü
abstract class MealPlanRepository {
  /// Belirli bir tarihe ait günlük plan1 getir
  Future<Either<Failure, GunlukPlan?>> gunlukPlanGetir(String userId, DateTime tarih);

  /// Yeni günlük plan oluştur ve kaydet
  Future<Either<Failure, GunlukPlan>> gunlukPlanOlustur({
    required String userId,
    required DateTime tarih,
    required MakroHedefleri hedefler,
    required List<Yemek> yemekHavuzu,
    required String hedef, // bulk/cut/maintain
    required List<String> kisitlamalar,
    Map<String, int> haftalikKullanilanYemekler = const {},
  });

  /// Günlük plan1 güncelle (yemek değişimi sonras1)
  Future<Either<Failure, GunlukPlan>> gunlukPlanGuncelle(GunlukPlan plan);

  /// Öğün durumunu güncelle (yenildi/atland1/onayland1)
  Future<Either<Failure, GunlukPlan>> ogunDurumuGuncelle({
    required String userId,
    required DateTime tarih,
    required String yemekId,
    required String durum, // 'yenildi', 'atlandi', 'onaylandi'
  });

  /// Haftalık planlar1 getir (son 7 gün)
  Future<Either<Failure, List<GunlukPlan>>> haftalikPlanlarGetir(
      String userId, DateTime baslangic);

  /// Plan1 sil
  Future<Either<Failure, void>> gunlukPlanSil(String userId, DateTime tarih);
}

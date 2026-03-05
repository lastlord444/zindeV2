// lib/domain/repositories/analytics_repository.dart

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../entities/nutrition/gunluk_plan.dart';
import '../entities/analytics/haftalik_rapor.dart';
import '../entities/analytics/alisveris_listesi.dart';

/// Analitik repository arayüzü
abstract class AnalyticsRepository {
  /// Haftalık rapor oluştur
  Future<Either<Failure, HaftalikRapor>> haftalikRaporOlustur({
    required String userId,
    required DateTime baslangic,
  });

  /// Aylık planlar1 getir (30 gün)
  Future<Either<Failure, List<GunlukPlan>>> aylikPlanlarGetir(
      String userId, DateTime ay);

  /// Haftalık alışveriş listesi oluştur
  Future<Either<Failure, AlisverisListesi>> alisverisListesiOlustur({
    required String userId,
    required DateTime haftaBasi,
  });
}

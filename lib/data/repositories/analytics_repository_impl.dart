// lib/data/repositories/analytics_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/logger.dart';
import '../../domain/entities/nutrition/gunluk_plan.dart';
import '../../domain/entities/analytics/haftalik_rapor.dart';
import '../../domain/entities/analytics/alisveris_listesi.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/repositories/meal_plan_repository.dart';

/// Analitik repository implementasyonu
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final MealPlanRepository _planRepo;

  const AnalyticsRepositoryImpl({required MealPlanRepository planRepo})
      : _planRepo = planRepo;

  @override
  Future<Either<Failure, HaftalikRapor>> haftalikRaporOlustur({
    required String userId,
    required DateTime baslangic,
  }) async {
    try {
      final planlarResult =
          await _planRepo.haftalikPlanlarGetir(userId, baslangic);

      return planlarResult.fold(
        (hata) => Left(hata),
        (planlar) {
          if (planlar.isEmpty) {
            return Right(HaftalikRapor.bos(userId, baslangic));
          }

          // İstatistikleri hesapla
          final ortalamKalori =
              planlar.map((p) => p.toplamKalori).reduce((a, b) => a + b) /
                  planlar.length;
          final ortalamProtein =
              planlar.map((p) => p.toplamProtein).reduce((a, b) => a + b) /
                  planlar.length;
          final ortalamKarb =
              planlar.map((p) => p.toplamKarbonhidrat).reduce((a, b) => a + b) /
                  planlar.length;
          final ortalamYag =
              planlar.map((p) => p.toplamYag).reduce((a, b) => a + b) /
                  planlar.length;

          return Right(HaftalikRapor.v1(
            userId: userId,
            haftaBaslangic: baslangic,
            haftaBitis: baslangic.add(const Duration(days: 6)),
            gunlukPlanlar: planlar,
            ortalamKalori: ortalamKalori,
            ortalamProtein: ortalamProtein,
            ortalamKarb: ortalamKarb,
            ortalamYag: ortalamYag,
            uyumYuzdesi: _uyumHesapla(planlar),
            tavsiyeler: _tavsiyeOlustur(ortalamKalori, ortalamProtein),
          ));
        },
      );
    } catch (e) {
      AppLogger.hata('Haftalık rapor hatas1', e);
      return Left(BilinmeyenHata(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GunlukPlan>>> aylikPlanlarGetir(
      String userId, DateTime ay) async {
    // 4 haftalık planlar1 topla
    final tumPlanlar = <GunlukPlan>[];
    for (int i = 0; i < 4; i++) {
      final hafta = ay.add(Duration(days: i * 7));
      final result = await _planRepo.haftalikPlanlarGetir(userId, hafta);
      result.fold((f) => null, (planlar) => tumPlanlar.addAll(planlar));
    }
    return Right(tumPlanlar);
  }


  @override
  Future<Either<Failure, AlisverisListesi>> alisverisListesiOlustur({
    required String userId,
    required DateTime haftaBasi,
  }) async {
    try {
      final planlarResult =
          await _planRepo.haftalikPlanlarGetir(userId, haftaBasi);

      return planlarResult.fold(
        (hata) => Left(hata),
        (planlar) {
          return Right(
              AlisverisListesi.planlardan(userId, haftaBasi, planlar));
        },
      );
    } catch (e) {
      return Left(BilinmeyenHata(e.toString()));
    }
  }

  double _uyumHesapla(List<GunlukPlan> planlar) {
    if (planlar.isEmpty) return 0;
    final tamamlanan = planlar
        .map((p) => p.tamamlananOgunler.values.where((v) => v).length)
        .reduce((a, b) => a + b);
    final toplam = planlar
        .map((p) => p.tamamlananOgunler.length)
        .reduce((a, b) => a + b);
    return toplam > 0 ? tamamlanan / toplam : 0;
  }

  List<String> _tavsiyeOlustur(double kalori, double protein) {
    final tavsiyeler = <String>[];
    if (kalori < 1500) {
      tavsiyeler.add('📊 Günlük kaloriniz hedefin altında. Porsiyon miktarların1 artırmay1 deneyin.');
    }
    if (protein < 100) {
      tavsiyeler.add('💪 Protein alımınız düşük. Öğünlere yumurta veya tavuk eklemeyi deneyin.');
    }
    if (tavsiyeler.isEmpty) {
      tavsiyeler.add('✅ Harika gidiyorsunuz! Beslenme planınıza iyi uyum sağladınız.');
    }
    return tavsiyeler;
  }
}

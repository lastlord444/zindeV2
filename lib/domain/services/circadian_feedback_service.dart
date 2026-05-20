// lib/domain/services/circadian_feedback_service.dart
// V4 - Sirkadiyen Geri Bildirim Servisi
// Sabah "Uykusuzum/Yorgunum" butonu → Karbonhidrat -10%, Yağ +eşdeğer kalori → Plan yenile

import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/nutrition/makro_hedefleri.dart';
import '../entities/nutrition/gunluk_plan.dart';
import '../entities/nutrition/yemek.dart';
import '../entities/user/kullanici_profili.dart';
import '../repositories/meal_plan_repository.dart';
import '../repositories/meal_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';
import 'meal_optimizer.dart';

/// Sirkadiyen Geri Bildirim Servisi
/// 
/// Kullanıcının enerji seviyesine göre günlük makro hedeflerini dinamik ayarlar
/// ve yemek planını yeniden optimize eder.
class CircadianFeedbackService {
  final MealPlanRepository _planRepo;
  final MealRepository _mealRepo;
  late final MealOptimizer _optimizer;

  CircadianFeedbackService({
    required MealPlanRepository planRepo,
    required MealRepository mealRepo,
    SupabaseClient? supabase,
  }) : _planRepo = planRepo,
       _mealRepo = mealRepo {
    _optimizer = MealOptimizer(supabase: supabase);
  }

  /// Sabah uykusuzluk/yorgunluk bildirimi → Karb düşür, yağ artır, planı yenile
  Future<GunlukPlan> applyFatigueAdjustment({
    required String userId,
    required DateTime tarih,
    required KullaniciProfili kullanici,
    required String fatigueLevel, // 'hafif', 'orta', 'agir'
  }) async {
    AppLogger.bilgi('🌙 Sirkadiyen feedback: $fatigueLevel — karb/yağ swap başlıyor');

    // 1. Mevcut günlük planı çek
    final planResult = await _planRepo.gunlukPlanGetir(userId, tarih);
    final GunlukPlan mevcutPlan;

    if (planResult.isRight() && planResult.getOrElse(() => null) != null) {
      mevcutPlan = planResult.getOrElse(() => throw Exception('Plan null'))!;
    } else {
      // Plan yoksa önce oluştur
      final yeniPlanResult = await _createDailyPlan(userId, tarih, kullanici);
      if (yeniPlanResult.isLeft()) {
        final errorMsg = yeniPlanResult.fold((l) => l.mesaj, (r) => 'Bilinmeyen Hata');
        throw Exception('Plan oluşturulamadı: $errorMsg');
      }
      mevcutPlan = yeniPlanResult.getOrElse(() => throw Exception('Yeni plan null'));
    }

    // 2. Makro hedeflerini klonla ve ayarla
    final orijinalHedefler = mevcutPlan.hedefler;
    final ayarlanmisHedefler = _adjustMacrosForFatigue(
      orijinalHedefler,
      fatigueLevel,
    );

    AppLogger.bilgi(
      '📊 Makro ayarlaması:\n'
      '  Önceki: K=${orijinalHedefler.gunlukKarbonhidrat.toStringAsFixed(1)}g, '
      'Y=${orijinalHedefler.gunlukYag.toStringAsFixed(1)}g\n'
      '  Yeni:   K=${ayarlanmisHedefler.gunlukKarbonhidrat.toStringAsFixed(1)}g, '
      'Y=${ayarlanmisHedefler.gunlukYag.toStringAsFixed(1)}g',
    );

    // 3. Tüm öğünleri yeniden optimize et
    final Map<String, Yemek?> yenidenOgunler = {};

    final ogunlerMap = {
      'kahvalti': mevcutPlan.kahvalti,
      'araOgun1': mevcutPlan.araOgun1,
      'ogle': mevcutPlan.ogleYemegi,  // DB'de 'ogle', entity'de ogleYemegi
      'araOgun2': mevcutPlan.araOgun2,
      'aksam': mevcutPlan.aksamYemegi,
      'geceAtistirma': mevcutPlan.geceAtistirma,
    };

    // Haftalık blacklist (tekrar eden yemekleri hariç tutmak için)
    final weekStart = tarih.subtract(Duration(days: tarih.weekday - 1));
    final blacklist = await _optimizer.getWeeklyBlacklist(
      userId: userId,
      weekStart: weekStart,
    );

    // Öğün dağılımı (NutritionConstraints'ten)
    final hedef = kullanici.hedef.name;
    final dagilim = await _getOgunDagilimi(hedef);

    for (final entry in ogunlerMap.entries) {
      final ogunAdi = entry.key;
      final mevcutYemek = entry.value;
      if (mevcutYemek == null) continue;

      final yuzde = dagilim[ogunAdi] ?? 0.15;
      final hedefKalori = ayarlanmisHedefler.gunlukKalori * yuzde;

      try {
        final result = await _optimizer.optimize(
          targetCalories: hedefKalori,
          hedefler: ayarlanmisHedefler,
          mealType: ogunAdi,
          blacklistIds: blacklist,
        );

        yenidenOgunler[ogunAdi] = result.mainMeal;
        AppLogger.bilgi(
          '🔄 $ogunAdi: ${mevcutYemek.ad} → ${result.mainMeal.ad} '
          '(${result.scaledGrams.toStringAsFixed(1)}g)',
        );
      } catch (e) {
        // Optimizasyon hatası → mevcut yemeği koru, sadece ölçekle
        AppLogger.uyari('⚠️ $ogunAdi optimizasyon hatası: $e → mevcut ölçekleniyor');
        final ratio = hedefKalori / (mevcutYemek.kalori > 0 ? mevcutYemek.kalori : 1);
        try {
          yenidenOgunler[ogunAdi] = mevcutYemek.scale(ratio);
        } catch (scaleError) {
          // Scale de başarısız olursa mevcut yemeği aynen koru
          AppLogger.hata('❌ $ogunAdi scale hatası: $scaleError → mevcut korunuyor');
          yenidenOgunler[ogunAdi] = mevcutYemek;
        }
      }
    }

    // 4. Yeni planı kaydet
    final yeniPlan = GunlukPlan(
      id: mevcutPlan.id,
      userId: mevcutPlan.userId,
      tarih: mevcutPlan.tarih,
      hedefler: ayarlanmisHedefler,
      kahvalti: yenidenOgunler['kahvalti'],
      araOgun1: yenidenOgunler['araOgun1'],
      ogleYemegi: yenidenOgunler['ogle'],
      araOgun2: yenidenOgunler['araOgun2'],
      aksamYemegi: yenidenOgunler['aksam'],
      geceAtistirma: yenidenOgunler['geceAtistirma'],
      ogunDurumlari: mevcutPlan.ogunDurumlari,
    );

    final kaydetResult = await _planRepo.gunlukPlanGuncelle(yeniPlan);
    if (kaydetResult.isLeft()) {
      final errorMsg = kaydetResult.fold((l) => l.mesaj, (r) => 'Bilinmeyen Hata');
      throw Exception('Plan güncellenemedi: $errorMsg');
    }

    AppLogger.bilgi('✅ Sirkadiyen feedback tamamlandı — plan yenilendi');

    return kaydetResult.getOrElse(() => yeniPlan);
  }

  /// Makro hedeflerini yorgunluk seviyesine göre ayarla
  /// 
  /// Karbonhidrat: -10% (hafif), -20% (orta), -30% (ağır)
  /// Yağ: +eşdeğer kalori (4 kcal/g karb ↔ 9 kcal/g yağ)
  MakroHedefleri _adjustMacrosForFatigue(
    MakroHedefleri orijinal,
    String fatigueLevel,
  ) {
    double karbAzalmaYuzdesi;
    switch (fatigueLevel.toLowerCase()) {
      case 'hafif':
        karbAzalmaYuzdesi = 0.10;
        break;
      case 'orta':
        karbAzalmaYuzdesi = 0.20;
        break;
      case 'agir':
        karbAzalmaYuzdesi = 0.30;
        break;
      default:
        karbAzalmaYuzdesi = 0.10;
    }

    // Karbonhidratı azalt
    final azaltilmisKarb =
        orijinal.gunlukKarbonhidrat * (1.0 - karbAzalmaYuzdesi);
    final karbKaloriFarki =
        (orijinal.gunlukKarbonhidrat - azaltilmisKarb) * 4.0;

    // Yağı eşdeğer kaloride artır (9 kcal/g yağ)
    final artanYagGram = karbKaloriFarki / 9.0;
    final ayarlanmisYag = orijinal.gunlukYag + artanYagGram;

    return MakroHedefleri(
      gunlukKalori: orijinal.gunlukKalori, // Toplam kalori sabit
      gunlukProtein: orijinal.gunlukProtein,
      gunlukKarbonhidrat: azaltilmisKarb,
      gunlukYag: ayarlanmisYag,
    );
  }

  /// Öğün dağılımını alır (geçici implementasyon, production'da NutritionConstraints kullan)
  Future<Map<String, double>> _getOgunDagilimi(String hedef) async {
    // Basit dağılım — production'da core/config/NutritionConstraints'ten al
    return {
      'kahvalti': 0.20,
      'araOgun1': 0.10,
      'ogle': 0.30,
      'araOgun2': 0.10,
      'aksam': 0.25,
      'geceAtistirma': 0.05,
    };
  }

  /// Yeni günlük plan oluştur (yardımcı)
  Future<Either<Failure, GunlukPlan>> _createDailyPlan(
    String userId,
    DateTime tarih,
    KullaniciProfili kullanici,
  ) async {
    // Bu metod mevcut GenerateDailyPlan use case'ini çağırmalı
    // Şimdilik Left döndür, production'da dependency injection ile yap
    return const Left(BilinmeyenHata('_createDailyPlan implementasyonu için GenerateDailyPlan use case\'ini kullan'));
  }
}

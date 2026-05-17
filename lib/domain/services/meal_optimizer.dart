// lib/domain/services/meal_optimizer.dart
// V4 - Supabase RPC tabanlı, Euclidean Distance, deterministik, ±%2 tolerans

import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/nutrition/yemek.dart';
import '../entities/nutrition/makro_hedefleri.dart';
import '../entities/nutrition/meal_optimization_result.dart';
import '../../core/utils/logger.dart';

/// Supabase RPC yanıtını geçici olarak tutan yardımcı model
class _FoodCandidate {
  final String foodId;
  final String foodName;
  final double caloriesPer100g;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double euclideanDistance;
  final double scaledGrams;
  final double scalingFactor;

  const _FoodCandidate({
    required this.foodId,
    required this.foodName,
    required this.caloriesPer100g,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.euclideanDistance,
    required this.scaledGrams,
    required this.scalingFactor,
  });

  factory _FoodCandidate.fromJson(Map<String, dynamic> json) {
    return _FoodCandidate(
      foodId: json['food_id']?.toString() ?? '',
      foodName: json['food_name']?.toString() ?? '',
      caloriesPer100g: (json['calories_per_100g'] as num?)?.toDouble() ?? 0.0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0.0,
      euclideanDistance: (json['euclidean_distance'] as num?)?.toDouble() ?? double.infinity,
      scaledGrams: (json['scaled_grams'] as num?)?.toDouble() ?? 0.0,
      scalingFactor: (json['scaling_factor'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Meal Optimizer
/// 
/// Supabase get_best_fit_foods RPC'sini çağırır,
/// Euclidean Distance ile en iyi 3 adayı alır,
/// 400g sınırını Dart tarafında da doğrular,
/// ±%2 tolerans kontrolü yapar.
class MealOptimizer {
  static const double _maxGramsLimit = 400.0;
  static const double _tolerancePercent = 0.02; // ±%2

  final SupabaseClient _supabase;

  MealOptimizer({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Belirtilen öğün için en iyi yemeği + 2 alternatifi bulur.
  ///
  /// [targetCalories]: öğün için hedef kalori
  /// [hedefler]:       kullanıcının günlük makro hedefleri
  /// [mealType]:       'kahvalti', 'ara_ogun_1', 'ogle' vb.
  /// [blacklistIds]:   bu hafta yenilmiş yemek ID'leri (tekrar seçilmesin)
  Future<MealOptimizationResult> optimize({
    required double targetCalories,
    required MakroHedefleri hedefler,
    required String mealType,
    List<String> blacklistIds = const [],
  }) async {
    // Hedef makro rasyolarını hesapla (kaloriden %)
    final totalKcal = hedefler.gunlukKalori > 0 ? hedefler.gunlukKalori : 2000.0;
    final targetPRatio = (hedefler.gunlukProtein * 4.0) / totalKcal;
    final targetCRatio = (hedefler.gunlukKarbonhidrat * 4.0) / totalKcal;
    final targetFRatio = (hedefler.gunlukYag * 9.0) / totalKcal;

    AppLogger.bilgi(
      '🔍 MealOptimizer: mealType=$mealType, '
      'targetCal=${targetCalories.toStringAsFixed(1)}, '
      'P=${ (targetPRatio*100).toStringAsFixed(1)}% '
      'C=${ (targetCRatio*100).toStringAsFixed(1)}% '
      'F=${ (targetFRatio*100).toStringAsFixed(1)}%',
    );

    // Supabase RPC çağrısı — filtreleme, blacklist ve Euclidean Distance PostgreSQL içinde
    final List<dynamic> rpcResult = await _supabase.rpc(
      'get_best_fit_foods',
      params: {
        'p_target_calories': targetCalories,
        'p_target_p_ratio': targetPRatio,
        'p_target_c_ratio': targetCRatio,
        'p_target_f_ratio': targetFRatio,
        'p_meal_type': Yemek.ogunTipiFromString(mealType).canonicalName,
        'p_blacklist_array': blacklistIds,
        'p_limit': 3,
      },
    );

    if (rpcResult.isEmpty) {
      throw Exception(
          'get_best_fit_foods RPC boş döndü — '
          'mealType=$mealType, blacklist=$blacklistIds');
    }

    // Ham verileri parse et
    final candidates = rpcResult
        .map((row) => _FoodCandidate.fromJson(row as Map<String, dynamic>))
        .toList();

    // Dart tarafında 400g sınırı + ±%2 tolerans doğrulaması
    final validCandidates = <_FoodCandidate>[];
    for (final c in candidates) {
      // 400 gram sınırı
      if (c.scaledGrams > _maxGramsLimit) {
        AppLogger.uyari(
          '⚠️  ${c.foodName} → ${c.scaledGrams.toStringAsFixed(1)}g > 400g sınırı, elendi',
        );
        continue;
      }

      // ±%2 tolerans: ölçeklendirilmiş kaloriler hedeften sapıyor mu?
      final scaledCalories = c.caloriesPer100g * c.scalingFactor;
      final toleranceDiff = (scaledCalories - targetCalories).abs() / targetCalories;
      if (toleranceDiff > _tolerancePercent) {
        AppLogger.uyari(
          '⚠️  ${c.foodName} tolerans dışı: '
          '${(toleranceDiff * 100).toStringAsFixed(2)}% sapma (max %2)',
        );
        // Fallback: tolerans aşılıyorsa scaling factor'ı yeniden hesapla
        final correctedSF = targetCalories / (c.caloriesPer100g > 0 ? c.caloriesPer100g : 1);
        final correctedGrams = 100.0 * correctedSF;

        if (correctedGrams > _maxGramsLimit) {
          AppLogger.uyari('   Düzeltilmiş gramaj ${correctedGrams.toStringAsFixed(1)}g > 400g, elendi');
          continue;
        }

        // Corrected scaling factor ile kabul et
        validCandidates.add(_FoodCandidate(
          foodId: c.foodId,
          foodName: c.foodName,
          caloriesPer100g: c.caloriesPer100g,
          proteinG: c.proteinG,
          carbsG: c.carbsG,
          fatG: c.fatG,
          euclideanDistance: c.euclideanDistance,
          scaledGrams: correctedGrams,
          scalingFactor: correctedSF,
        ));
        continue;
      }

      validCandidates.add(c);
    }

    if (validCandidates.isEmpty) {
      throw Exception(
          'Tüm adaylar 400g veya ±%2 tolerans sınırını aştı — '
          'targetCalories=$targetCalories, mealType=$mealType');
    }

    // En iyi aday → Ana yemek
    final mainCandidate = validCandidates.first;
    final Yemek mainYemek = _candidateToYemek(mainCandidate, mealType);

    // Kalan adaylar → Alternatifler (max 2)
    final altCandidates = validCandidates.skip(1).take(2).toList();
    final List<Yemek> alternatives =
        altCandidates.map((c) => _candidateToYemek(c, mealType)).toList();

    if (alternatives.length < 2) {
      throw Exception('Yeterli alternatif bulunamadı ($mealType). Bulunan: ${alternatives.length}, İstenen: 2. Alternatif Hard Gate devrede.');
    }

    final result = MealOptimizationResult(
      mainMeal: mainYemek,
      alternatives: alternatives,
      targetCalories: targetCalories,
      scalingFactor: mainCandidate.scalingFactor,
      scaledGrams: mainCandidate.scaledGrams,
      mealType: mealType,
    );

    AppLogger.bilgi(
      '✅ MealOptimizer: ${mainYemek.ad} seçildi — '
      '${mainCandidate.scaledGrams.toStringAsFixed(1)}g, '
      'dist=${mainCandidate.euclideanDistance.toStringAsFixed(4)}, '
      '${alternatives.length} alternatif',
    );

    return result;
  }

  /// Haftalık blacklist'i Supabase'den çeker
  Future<List<String>> getWeeklyBlacklist({
    required String userId,
    required DateTime weekStart,
  }) async {
    final weekEnd = weekStart.add(const Duration(days: 6));
    try {
      final List<dynamic> result = await _supabase.rpc(
        'get_weekly_consumed_food_ids',
        params: {
          'p_user_id': userId,
          'p_start_date': _dateToString(weekStart),
          'p_end_date': _dateToString(weekEnd),
        },
      );
      return result
          .map((row) => (row as Map<String, dynamic>)['food_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      AppLogger.uyari('Blacklist çekilemedi: $e — boş liste ile devam');
      return [];
    }
  }

  // ─── Yardımcılar ─────────────────────────────────────────────────────────

  Yemek _candidateToYemek(_FoodCandidate c, String mealType) {
    // Ölçeklendirilmiş makrolar — baseWeightG = scaledGrams
    final sf = c.scalingFactor;
    return Yemek(
      id: c.foodId,
      ad: c.foodName,
      ogun: Yemek.ogunTipiFromString(mealType),
      kalori: c.caloriesPer100g * sf,
      protein: c.proteinG * sf,
      karbonhidrat: c.carbsG * sf,
      yag: c.fatG * sf,
      malzemeler: ['${c.scaledGrams.toStringAsFixed(1)}g ${c.foodName}'],
      hazirlamaSuresi: 15,
      zorluk: Zorluk.kolay,
      baseWeightG: c.scaledGrams,
      dominantMacro: _computeDominantMacro(c.proteinG, c.carbsG, c.fatG),
      minMultiplier: 0.5,
      maxMultiplier: (_maxGramsLimit / max(c.scaledGrams, 1.0)).clamp(1.0, 4.0),
      unitName: 'gram',
    );
  }

  String _computeDominantMacro(double p, double c, double f) {
    final pCal = p * 4;
    final cCal = c * 4;
    final fCal = f * 9;
    if (pCal >= cCal && pCal >= fCal) return 'protein';
    if (cCal >= pCal && cCal >= fCal) return 'carb';
    return 'fat';
  }

  String _dateToString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

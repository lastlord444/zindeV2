// lib/domain/entities/nutrition/meal_optimization_result.dart
// V4 - Meal Optimizer Result Entity

import 'package:equatable/equatable.dart';
import 'yemek.dart';

/// Meal Optimizer Sonucu
/// 1 Ana Yemek + 2 Alternatif Yemek içerir
class MealOptimizationResult extends Equatable {
  final Yemek mainMeal;           // Ana yemek (en iyi Euclidean Distance)
  final List<Yemek> alternatives;  // 2 alternatif yemek
  final double targetCalories;
  final double scalingFactor;
  final double scaledGrams;
  final String mealType;

  const MealOptimizationResult({
    required this.mainMeal,
    required this.alternatives,
    required this.targetCalories,
    required this.scalingFactor,
    required this.scaledGrams,
    required this.mealType,
  });

  /// Scaled meal (ölçeklendirilmiş ana yemek)
  Yemek get scaledMainMeal {
    return Yemek(
      id: mainMeal.id,
      ad: mainMeal.ad,
      ogun: mainMeal.ogun,
      kalori: mainMeal.kalori * scalingFactor,
      protein: mainMeal.protein * scalingFactor,
      karbonhidrat: mainMeal.karbonhidrat * scalingFactor,
      yag: mainMeal.yag * scalingFactor,
      malzemeler: _scaleIngredients(mainMeal.malzemeler, scalingFactor),
      alternatifler: mainMeal.alternatifler,
      alternatifYemekler: mainMeal.alternatifYemekler,
      hazirlamaSuresi: mainMeal.hazirlamaSuresi,
      zorluk: mainMeal.zorluk,
      etiketler: mainMeal.etiketler,
      tarif: mainMeal.tarif,
      gorselUrl: mainMeal.gorselUrl,
      proteinKaynagi: mainMeal.proteinKaynagi,
      baseWeightG: mainMeal.baseWeightG * scalingFactor,
      dominantMacro: mainMeal.dominantMacro,
      minMultiplier: mainMeal.minMultiplier,
      maxMultiplier: mainMeal.maxMultiplier,
      unitName: mainMeal.unitName,
    );
  }

  /// Scaled alternatives
  List<Yemek> get scaledAlternatives => alternatives.map((alt) {
    final ratio = targetCalories / (alt.kalori > 0 ? alt.kalori : 1);
    return Yemek(
      id: alt.id,
      ad: alt.ad,
      ogun: alt.ogun,
      kalori: alt.kalori * ratio,
      protein: alt.protein * ratio,
      karbonhidrat: alt.karbonhidrat * ratio,
      yag: alt.yag * ratio,
      malzemeler: _scaleIngredients(alt.malzemeler, ratio),
      alternatifler: alt.alternatifler,
      alternatifYemekler: alt.alternatifYemekler,
      hazirlamaSuresi: alt.hazirlamaSuresi,
      zorluk: alt.zorluk,
      etiketler: alt.etiketler,
      tarif: alt.tarif,
      gorselUrl: alt.gorselUrl,
      proteinKaynagi: alt.proteinKaynagi,
      baseWeightG: alt.baseWeightG * ratio,
      dominantMacro: alt.dominantMacro,
      minMultiplier: alt.minMultiplier,
      maxMultiplier: alt.maxMultiplier,
      unitName: alt.unitName,
    );
  }).toList();

  List<String> _scaleIngredients(List<String> ingredients, double factor) {
    return ingredients.map((ing) {
      final regex = RegExp(r'^(\d+(?:[.,/]\d+)?)\s*(.*)$');
      final match = regex.firstMatch(ing);
      if (match == null) return ing;

      final numStr = match.group(1)!;
      final rest = match.group(2)!;

      double? value;
      if (numStr.contains('/')) {
        final parts = numStr.split('/');
        value = (double.tryParse(parts[0]) ?? 0) / (double.tryParse(parts[1]) ?? 1);
      } else {
        value = double.tryParse(numStr.replaceAll(',', '.'));
      }

      if (value == null) return ing;

      final scaled = value * factor;
      final formatted = scaled % 1 == 0 ? scaled.toInt().toString() : scaled.toStringAsFixed(1);
      return '$formatted $rest';
    }).toList();
  }

  @override
  List<Object?> get props => [
        mainMeal,
        alternatives,
        targetCalories,
        scalingFactor,
        scaledGrams,
        mealType,
      ];
}

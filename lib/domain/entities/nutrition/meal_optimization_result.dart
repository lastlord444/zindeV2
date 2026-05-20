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

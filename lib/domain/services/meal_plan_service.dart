// lib/domain/services/meal_plan_service.dart
// V2 meal plan servisi - domain service shim

import 'package:get_it/get_it.dart';
import '../usecases/user/calculate_macros.dart';

import '../entities/nutrition/makro_hedefleri.dart';

/// MealPlanService - V1 uyumluluğu iin shim
/// Gerek uygulamada HomeBloc ve repository'ler kullanılır
class MealPlanService {
  MealPlanService();

  // V1 UI iin static shim metodu
  static MakroHedefleri calculateTargets(dynamic profil) {
    try {
      final calculator = GetIt.instance<CalculateMacros>();
      final res = calculator.call(profil);
      return res;
    } catch (_) {
      return MakroHedefleri.varsayilan();
    }
  }
}

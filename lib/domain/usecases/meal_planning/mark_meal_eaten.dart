// lib/domain/usecases/meal_planning/mark_meal_eaten.dart

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/nutrition/gunluk_plan.dart';
import '../../repositories/meal_plan_repository.dart';

/// Öğünü yenildi olarak işaretle use case'i
class MarkMealEaten {
  final MealPlanRepository _repository;

  const MarkMealEaten(this._repository);

  Future<Either<Failure, GunlukPlan>> call({
    required String userId,
    required DateTime tarih,
    required String yemekId,
    String durum = 'yenildi',
  }) {
    return _repository.ogunDurumuGuncelle(
      userId: userId,
      tarih: tarih,
      yemekId: yemekId,
      durum: durum,
    );
  }
}

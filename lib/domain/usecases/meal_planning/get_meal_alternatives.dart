// lib/domain/usecases/meal_planning/get_meal_alternatives.dart

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/nutrition/yemek.dart';
import '../../repositories/meal_repository.dart';

/// Alternatif yemekleri getir use case'i
class GetMealAlternatives {
  final MealRepository _repository;

  const GetMealAlternatives(this._repository);

  Future<Either<Failure, List<Yemek>>> call({
    required Yemek mevcutYemek,
    required List<String> kisitlamalar,
    int sayi = 5,
  }) {
    return _repository.alternatifYemekleriGetir(
      mevcutYemek: mevcutYemek,
      kisitlamalar: kisitlamalar,
      sayi: sayi,
    );
  }
}

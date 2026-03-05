// lib/domain/usecases/analytics/generate_shopping_list.dart

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/analytics/alisveris_listesi.dart';
import '../../repositories/analytics_repository.dart';

/// Alışveriş listesi oluştur use case'i
class GenerateShoppingList {
  final AnalyticsRepository _repository;

  const GenerateShoppingList(this._repository);

  Future<Either<Failure, AlisverisListesi>> call({
    required String userId,
    required DateTime haftaBasi,
  }) {
    return _repository.alisverisListesiOlustur(
      userId: userId,
      haftaBasi: haftaBasi,
    );
  }
}

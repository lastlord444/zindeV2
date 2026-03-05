// lib/domain/repositories/meal_repository.dart

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../entities/nutrition/yemek.dart';

/// Yemek repository arayüzü (yemek havuzu)
abstract class MealRepository {
  /// Tüm yemekleri getir (yemek havuzu)
  Future<Either<Failure, List<Yemek>>> tumYemekleriGetir();

  /// Öğün tipine göre yemekleri getir
  Future<Either<Failure, List<Yemek>>> ogunYemekleriGetir(String ogunTipi);

  /// Kısıtlamalara uygun yemekleri filtrele
  Future<Either<Failure, List<Yemek>>> uygunYemekleriGetir({
    required String ogunTipi,
    required List<String> kisitlamalar,
  });

  /// Favori yemekleri getir
  Future<Either<Failure, List<Yemek>>> favoriYemekleriGetir(String userId);

  /// Yemeği favorilere ekle
  Future<Either<Failure, void>> favoriyeEkle(String userId, String yemekId);

  /// Yemeği favorilerden ıkar
  Future<Either<Failure, void>> favoridenCikar(String userId, String yemekId);

  /// Alternatif yemekleri getir
  Future<Either<Failure, List<Yemek>>> alternatifYemekleriGetir({
    required Yemek mevcutYemek,
    required List<String> kisitlamalar,
    int sayi = 5,
  });
}

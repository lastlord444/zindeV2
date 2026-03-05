// lib/domain/repositories/workout_repository.dart

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../entities/workout/antrenman_plani.dart';

/// Antrenman repository arayüzü
abstract class WorkoutRepository {
  /// Tüm antrenman programların1 getir
  Future<Either<Failure, List<AntrenmanPlani>>> programlariGetir();

  /// Zorluk seviyesine göre filtrele
  Future<Either<Failure, List<AntrenmanPlani>>> programlariFiltrele(String zorluk);

  /// Antrenman tamamlamay1 kaydet
  Future<Either<Failure, void>> antrenmanKaydet({
    required String userId,
    required String programId,
    required String programAdi,
    required DateTime tarih,
    required int sureDakika,
    required List<String> tamamlananEgzersizler,
  });

  /// Antrenman gemişini getir
  Future<Either<Failure, List<Map<String, dynamic>>>> gecmisiGetir(String userId);
}

// lib/domain/usecases/workout/get_workout_programs.dart

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/workout/antrenman_plani.dart';
import '../../repositories/workout_repository.dart';

/// Antrenman programların1 getir use case'i
class GetWorkoutPrograms {
  final WorkoutRepository _repository;

  const GetWorkoutPrograms(this._repository);

  Future<Either<Failure, List<AntrenmanPlani>>> call({String? zorluk}) {
    if (zorluk != null) {
      return _repository.programlariFiltrele(zorluk);
    }
    return _repository.programlariGetir();
  }
}

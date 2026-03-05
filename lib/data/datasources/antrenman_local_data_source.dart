// lib/data/datasources/antrenman_local_data_source.dart
// V1 uyumluluk shim - WorkoutRepository'e yönlendirir

import 'package:get_it/get_it.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../domain/entities/workout/antrenman_plani.dart';

/// AntrenmanLocalDataSource - V1 uyumluluğu
/// Gerekte WorkoutRepository kullanılır (Supabase + yerel sabit program)
class AntrenmanLocalDataSource {
  final WorkoutRepository _workoutRepo;

  AntrenmanLocalDataSource()
      : _workoutRepo = GetIt.instance<WorkoutRepository>();

  Future<List<AntrenmanPlani>> programlariGetir() async {
    final result = await _workoutRepo.programlariGetir();
    return result.fold((_) => [], (p) => p);
  }
}

// lib/presentation/bloc/workout/workout_event.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/workout/antrenman_plani.dart';
// Zorluk enum iin

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();
  @override
  List<Object?> get props => [];
}

class LoadAntrenmanProgramlari extends WorkoutEvent {
  const LoadAntrenmanProgramlari();
}

class FilterByZorluk extends WorkoutEvent {
  final String zorluk; // 'kolay', 'orta', 'zor'
  const FilterByZorluk(this.zorluk);
  @override
  List<Object?> get props => [zorluk];
}

class StartAntrenman extends WorkoutEvent {
  final AntrenmanPlani program;
  const StartAntrenman(this.program);
  @override
  List<Object?> get props => [program];
}

class CompleteEgzersiz extends WorkoutEvent {
  final String egzersizId;
  const CompleteEgzersiz(this.egzersizId);
  @override
  List<Object?> get props => [egzersizId];
}

class CompleteAntrenman extends WorkoutEvent {
  final String programId;
  final String programAdi;
  final int sureDakika;
  const CompleteAntrenman({
    required this.programId,
    required this.programAdi,
    required this.sureDakika,
  });
  @override
  List<Object?> get props => [programId, sureDakika];
}

class LoadAntrenmanGecmisi extends WorkoutEvent {
  const LoadAntrenmanGecmisi();
}


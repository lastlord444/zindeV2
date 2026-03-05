// lib/presentation/bloc/workout/workout_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/repositories/workout_repository.dart';
import 'workout_event.dart';
import 'workout_state.dart';

/// Antrenman BLoC
class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository _workoutRepo;
  final String? _userId;

  WorkoutBloc({
    required WorkoutRepository workoutRepo,
    String? userId,
  })  : _workoutRepo = workoutRepo,
        _userId = userId,
        super(const AntrenmanInitial()) {
    on<LoadAntrenmanProgramlari>(_onLoadProgramlar);
    on<FilterByZorluk>(_onFilterByZorluk);
    on<StartAntrenman>(_onStartAntrenman);
    on<CompleteEgzersiz>(_onCompleteEgzersiz);
    on<CompleteAntrenman>(_onCompleteAntrenman);
    on<LoadAntrenmanGecmisi>(_onLoadGecmis);
  }

  Future<void> _onLoadProgramlar(
      LoadAntrenmanProgramlari event, Emitter<WorkoutState> emit) async {
    emit(const AntrenmanYukleniyor());
    final result = await _workoutRepo.programlariGetir();
    result.fold(
      (hata) => emit(AntrenmanHata(hata.mesaj)),
      (programlar) => emit(AntrenmanProgramlariLoaded(programlar: programlar)),
    );
  }

  Future<void> _onFilterByZorluk(
      FilterByZorluk event, Emitter<WorkoutState> emit) async {
    emit(const AntrenmanYukleniyor());
    final result = await _workoutRepo.programlariFiltrele(event.zorluk);
    result.fold(
      (hata) => emit(AntrenmanHata(hata.mesaj)),
      (programlar) => emit(AntrenmanProgramlariLoaded(
          programlar: programlar, aktifFiltre: event.zorluk)),
    );
  }

  void _onStartAntrenman(
      StartAntrenman event, Emitter<WorkoutState> emit) {
    emit(AntrenmanAktif(aktifProgram: event.program));
  }

  void _onCompleteEgzersiz(
      CompleteEgzersiz event, Emitter<WorkoutState> emit) {
    if (state is! AntrenmanAktif) return;
    final mevcutState = state as AntrenmanAktif;
    final tamamlananlar = [...mevcutState.tamamlananEgzersizler, event.egzersizId];
    emit(AntrenmanAktif(
      aktifProgram: mevcutState.aktifProgram,
      tamamlananEgzersizler: tamamlananlar,
    ));
  }

  Future<void> _onCompleteAntrenman(
      CompleteAntrenman event, Emitter<WorkoutState> emit) async {
    if (_userId == null) return;
    await _workoutRepo.antrenmanKaydet(
      userId: _userId!,
      programId: event.programId,
      programAdi: event.programAdi,
      tarih: DateTime.now(),
      sureDakika: event.sureDakika,
      tamamlananEgzersizler: state is AntrenmanAktif
          ? (state as AntrenmanAktif).tamamlananEgzersizler
          : [],
    );
    AppLogger.bilgi('✅ Antrenman tamamland1: ${event.programAdi}');
    add(const LoadAntrenmanProgramlari());
  }

  Future<void> _onLoadGecmis(
      LoadAntrenmanGecmisi event, Emitter<WorkoutState> emit) async {
    if (_userId == null) return;
    final result = await _workoutRepo.gecmisiGetir(_userId!);
    result.fold(
      (hata) => emit(AntrenmanHata(hata.mesaj)),
      (gecmis) => emit(AntrenmanGecmisiLoaded(gecmis)),
    );
  }
}


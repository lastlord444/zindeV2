// lib/presentation/bloc/workout/workout_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/workout/antrenman_plani.dart';

abstract class WorkoutState extends Equatable {
  const WorkoutState();
  @override
  List<Object?> get props => [];
}

class AntrenmanInitial extends WorkoutState {
  const AntrenmanInitial();
}

class AntrenmanYukleniyor extends WorkoutState {
  const AntrenmanYukleniyor();
}

/// V1 UI uyumluluk alias
typedef AntrenmanLoading = AntrenmanYukleniyor;

class AntrenmanProgramlariLoaded extends WorkoutState {
  final List<AntrenmanPlani> programlar;
  final String? aktifFiltre;
  const AntrenmanProgramlariLoaded({required this.programlar, this.aktifFiltre});

  /// UI 'filtreZorluk' bekliyor
  String? get filtreZorluk => aktifFiltre;

  @override
  List<Object?> get props => [programlar, aktifFiltre];
}

class AntrenmanAktif extends WorkoutState {
  final AntrenmanPlani aktifProgram;
  final List<String> tamamlananEgzersizler;
  const AntrenmanAktif({
    required this.aktifProgram,
    this.tamamlananEgzersizler = const [],
  });
  @override
  List<Object?> get props => [aktifProgram, tamamlananEgzersizler];
}

/// V1 UI uyumluluk alias - AntrenmanActive
typedef AntrenmanActive = AntrenmanAktif;

/// UI'nın 'AntrenmanProgrami' beklediği yerler iin alias
typedef AntrenmanProgrami = AntrenmanPlani;

class AntrenmanGecmisiLoaded extends WorkoutState {
  final List<Map<String, dynamic>> gecmis;
  const AntrenmanGecmisiLoaded(this.gecmis);

  /// Son 7 gün antrenman sayıs1
  int get son7GunAntrenmanSayisi => gecmis.length;

  /// Toplam kalori (tahmini)
  int get toplamKalori => gecmis.fold(0,
      (t, e) => t + ((e['sure_dakika'] as int? ?? 45) * 6));

  @override
  List<Object?> get props => [gecmis];
}

class AntrenmanHata extends WorkoutState {
  final String mesaj;
  const AntrenmanHata(this.mesaj);
  @override
  List<Object?> get props => [mesaj];
}

/// V1 UI uyumluluk alias
typedef AntrenmanError = AntrenmanHata;

/// TamamlananAntrenman gerekte Map<String,dynamic> (gecmis listesindeki)
/// UI iin tip alias
typedef TamamlananAntrenman = Map<String, dynamic>;



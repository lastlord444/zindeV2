// lib/presentation/bloc/home/home_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/nutrition/gunluk_plan.dart';
import '../../../domain/entities/nutrition/makro_hedefleri.dart';
import '../../../domain/entities/nutrition/yemek.dart';
import '../../../domain/entities/nutrition/alternatif_besin.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  final double progress;
  final String mesaj;

  const HomeLoading({this.progress = 0.0, this.mesaj = 'Yükleniyor...'});

  /// V1 uyumluluk alias
  String get message => mesaj;

  @override
  List<Object?> get props => [progress, mesaj];
}

class HomeLoaded extends HomeState {
  final GunlukPlan plan;
  final MakroHedefleri hedefler;
  final Map<String, bool> tamamlananOgunler;
  final List<Yemek>? alternatifYemekler;
  final DateTime secilenTarih;

  const HomeLoaded({
    required this.plan,
    required this.hedefler,
    required this.tamamlananOgunler,
    this.alternatifYemekler,
    required this.secilenTarih,
  });

  /// V1 uyumluluk - UI 'currentDate' bekliyor
  DateTime get currentDate => secilenTarih;

  /// Tamamlanan kalori (GunlukPlan'dan)
  double get tamamlananKalori => plan.tamamlananKalori;
  double get tamamlananProtein => plan.tamamlananProtein;
  double get tamamlananKarb => plan.tamamlananKarb;
  double get tamamlananYag => plan.tamamlananYag;

  /// Günlük onay durumu
  Map<String, bool> get gunlukOnayDurumu => plan.gunlukOnayDurumu;

  @override
  List<Object?> get props => [plan, hedefler, tamamlananOgunler, secilenTarih, alternatifYemekler];
}

class AlternativeMealsLoaded extends HomeLoaded {
  final Yemek mevcutYemek;

  const AlternativeMealsLoaded({
    required super.plan,
    required super.hedefler,
    required super.tamamlananOgunler,
    required super.secilenTarih,
    required this.mevcutYemek,
    required super.alternatifYemekler,
  });

  @override
  List<Object?> get props => [plan, hedefler, tamamlananOgunler, secilenTarih, mevcutYemek, alternatifYemekler];
}

class AlternativeIngredientsLoaded extends HomeState {
  final GunlukPlan plan;
  final MakroHedefleri hedefler;
  final Map<String, bool> tamamlananOgunler;
  final DateTime secilenTarih;
  final String ogunId;
  final String besinAdi;
  final List<AlternatifBesin> alternatifler;
  final Yemek? yemek;
  final int malzemeIndex;
  final String malzemeMetni;

  const AlternativeIngredientsLoaded({
    required this.plan,
    required this.hedefler,
    required this.tamamlananOgunler,
    required this.secilenTarih,
    required this.ogunId,
    required this.besinAdi,
    required this.alternatifler,
    this.yemek,
    this.malzemeIndex = 0,
    this.malzemeMetni = '',
  });

  /// V1 uyumluluk alias'lar
  DateTime get currentDate => secilenTarih;
  Map<String, bool> get gunlukOnayDurumu => plan.gunlukOnayDurumu;
  String get orijinalMalzemeMetni => malzemeMetni;
  List<AlternatifBesin> get alternatifBesinler => alternatifler;

  @override
  List<Object?> get props => [plan, secilenTarih, ogunId, besinAdi, alternatifler];
}

class HomeError extends HomeState {
  final String mesaj;
  const HomeError(this.mesaj);

  /// V1 uyumluluk alias
  String get message => mesaj;

  @override
  List<Object?> get props => [mesaj];
}



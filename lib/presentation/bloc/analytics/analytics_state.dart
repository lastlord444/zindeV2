// lib/presentation/bloc/analytics/analytics_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/analytics/haftalik_rapor.dart';
import '../../../domain/entities/nutrition/gunluk_plan.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();
  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

class AnalyticsYukleniyor extends AnalyticsState {
  const AnalyticsYukleniyor();
}

/// V1 UI uyumluluk alias
typedef AnalyticsLoading = AnalyticsYukleniyor;

class WeeklyAnalyticsLoaded extends AnalyticsState {
  final HaftalikRapor rapor;
  final List<GunlukPlan> planlar;
  const WeeklyAnalyticsLoaded({required this.rapor, required this.planlar});

  /// V1 UI 'data' getter'1 â†’ rapor
  HaftalikRapor get data => rapor;

  /// Haftalık ortalama kalori
  double get ortalamaKalori => planlar.isEmpty
      ? 0
      : planlar.map((p) => p.toplamKalori).reduce((a, b) => a + b) / planlar.length;

  /// Haftalık ortalama protein
  double get ortalamaProtein => planlar.isEmpty
      ? 0
      : planlar.map((p) => p.toplamProtein).reduce((a, b) => a + b) / planlar.length;

  @override
  List<Object?> get props => [rapor, planlar];
}

class MonthlyAnalyticsLoaded extends AnalyticsState {
  final List<GunlukPlan> planlar;
  const MonthlyAnalyticsLoaded(this.planlar);

  /// V1 UI 'data' getter'1 â†’ planlar
  List<GunlukPlan> get data => planlar;

  @override
  List<Object?> get props => [planlar];
}

class AnalyticsHata extends AnalyticsState {
  final String mesaj;
  const AnalyticsHata(this.mesaj);
  @override
  List<Object?> get props => [mesaj];
}

/// V1 UI uyumluluk alias
typedef AnalyticsError = AnalyticsHata;



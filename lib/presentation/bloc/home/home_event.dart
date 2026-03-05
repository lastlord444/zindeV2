// lib/presentation/bloc/home/home_event.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/nutrition/yemek.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomePage extends HomeEvent {
  const LoadHomePage();
}

class LoadPlanByDate extends HomeEvent {
  final DateTime tarih;
  const LoadPlanByDate(this.tarih);

  @override
  List<Object?> get props => [tarih];
}

class RefreshDailyPlan extends HomeEvent {
  final bool forceRegenerate;
  const RefreshDailyPlan({this.forceRegenerate = false});

  @override
  List<Object?> get props => [forceRegenerate];
}

class GenerateWeeklyPlan extends HomeEvent {
  final bool forceRegenerate;
  const GenerateWeeklyPlan({this.forceRegenerate = false});

  @override
  List<Object?> get props => [forceRegenerate];
}

class MarkMealAsEaten extends HomeEvent {
  final String yemekId;
  const MarkMealAsEaten(this.yemekId);

  @override
  List<Object?> get props => [yemekId];
}

class SkipMeal extends HomeEvent {
  final String yemekId;
  const SkipMeal(this.yemekId);

  @override
  List<Object?> get props => [yemekId];
}

class ConfirmMealEaten extends HomeEvent {
  final String yemekId;
  const ConfirmMealEaten(this.yemekId);

  @override
  List<Object?> get props => [yemekId];
}

class ResetMealStatus extends HomeEvent {
  final String yemekId;
  const ResetMealStatus(this.yemekId);

  @override
  List<Object?> get props => [yemekId];
}

class GenerateAlternativeMeals extends HomeEvent {
  final Yemek mevcutYemek;
  final int sayi;
  const GenerateAlternativeMeals(this.mevcutYemek, {this.sayi = 5});

  @override
  List<Object?> get props => [mevcutYemek, sayi];
}

class ReplaceMealWith extends HomeEvent {
  final Yemek eskiYemek;
  final Yemek yeniYemek;
  const ReplaceMealWith(this.eskiYemek, this.yeniYemek);

  @override
  List<Object?> get props => [eskiYemek, yeniYemek];
}

class GenerateIngredientAlternatives extends HomeEvent {
  final Yemek yemek;
  final String malzemeMetni;
  final int malzemeIndex;

  const GenerateIngredientAlternatives({
    required this.yemek,
    required this.malzemeMetni,
    required this.malzemeIndex,
  });

  @override
  List<Object?> get props => [yemek, malzemeMetni, malzemeIndex];
}

class ReplaceIngredientWith extends HomeEvent {
  final Yemek yemek;
  final int malzemeIndex;
  final String yeniMalzemeMetni;

  const ReplaceIngredientWith({
    required this.yemek,
    required this.malzemeIndex,
    required this.yeniMalzemeMetni,
  });

  @override
  List<Object?> get props => [yemek, malzemeIndex, yeniMalzemeMetni];
}

class CancelAlternativeSelection extends HomeEvent {
  const CancelAlternativeSelection();
}

class CancelAlternativeMealSelection extends HomeEvent {
  const CancelAlternativeMealSelection();
}


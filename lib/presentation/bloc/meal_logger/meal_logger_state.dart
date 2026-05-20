// lib/presentation/bloc/meal_logger/meal_logger_state.dart

import 'package:equatable/equatable.dart';

/// Meal Logger BLoC States
abstract class MealLoggerState extends Equatable {
  const MealLoggerState();
  
  @override
  List<Object?> get props => [];
}

class MealLoggerInitial extends MealLoggerState {
  const MealLoggerInitial();
}

class MealLoggerLoading extends MealLoggerState {
  final String message;

  const MealLoggerLoading({this.message = 'İşleniyor...'});

  @override
  List<Object?> get props => [message];
}

class MealLoggerLoaded extends MealLoggerState {
  final Map<String, Map<String, dynamic>> weeklyLogs; // {date: {mealType: log}}

  const MealLoggerLoaded(this.weeklyLogs);

  @override
  List<Object?> get props => [weeklyLogs];
}

class MealLogSaved extends MealLoggerState {
  final String logId;
  final String foodName;

  const MealLogSaved({required this.logId, required this.foodName});

  @override
  List<Object?> get props => [logId, foodName];
}

class MealLoggerError extends MealLoggerState {
  final String message;
  final String? details;

  const MealLoggerError({required this.message, this.details});

  @override
  List<Object?> get props => [message, details];
}

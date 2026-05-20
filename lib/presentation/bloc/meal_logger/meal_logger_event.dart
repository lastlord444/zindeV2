// lib/presentation/bloc/meal_logger/meal_logger_event.dart


/// Meal Logger BLoC Events
abstract class MealLoggerEvent {}

class MealLoggerInit extends MealLoggerEvent {}

class MarkAsConsumed extends MealLoggerEvent {
  final String foodId;
  final String mealType;
  final double consumedGrams;

  MarkAsConsumed({
    required this.foodId,
    required this.mealType,
    required this.consumedGrams,
  });
}

class MarkAsSkipped extends MealLoggerEvent {
  final String foodId;
  final String mealType;

  MarkAsSkipped({
    required this.foodId,
    required this.mealType,
  });
}

class UndoMealLog extends MealLoggerEvent {
  final String logId;

  UndoMealLog({required this.logId});
}

class LoadWeeklyLogs extends MealLoggerEvent {
  final DateTime weekStart;

  LoadWeeklyLogs({required this.weekStart});
}

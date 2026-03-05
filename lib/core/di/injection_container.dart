// lib/core/di/injection_container.dart
// Dependency Injection - get_it ile servis kayd1

import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../network/network_info.dart';
import '../utils/logger.dart';

// Data - DataSources
import '../../data/datasources/local/local_storage_datasource.dart';
import '../../data/datasources/remote/supabase_user_datasource.dart';
import '../../data/datasources/remote/supabase_meal_datasource.dart';

// Data - Repositories
import '../../data/repositories/user_repository_impl.dart';
import '../../data/repositories/meal_plan_repository_impl.dart';

// Domain - Repositories
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/meal_repository.dart';
import '../../domain/repositories/meal_plan_repository.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../domain/repositories/analytics_repository.dart';

// Domain - UseCases
import '../../domain/usecases/user/get_user_profile.dart';
import '../../domain/usecases/user/update_user_profile.dart';
import '../../domain/usecases/user/calculate_macros.dart';
import '../../domain/usecases/meal_planning/generate_daily_plan.dart';
import '../../domain/usecases/meal_planning/mark_meal_eaten.dart';
import '../../domain/usecases/meal_planning/get_meal_alternatives.dart';
import '../../domain/usecases/workout/get_workout_programs.dart';
import '../../domain/usecases/analytics/get_weekly_report.dart';
import '../../domain/usecases/analytics/generate_shopping_list.dart';

// Presentation - BLoC
import '../../presentation/bloc/home/home_bloc.dart';
import '../../presentation/bloc/profil/profil_bloc.dart';

// Yemek havuzu - yerel veri kaynaklar1
import '../../data/repositories/meal_repository_impl.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../../data/repositories/analytics_repository_impl.dart';

final sl = GetIt.instance;

/// Tüm bağımlılıklar1 kaydet
Future<void> initDependencies() async {
  AppLogger.bilgi('🔧 Bağımlılıklar başlatılıyor...');

  // ─── Supabase ────────────────────────────────────────────────────────────
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  sl.registerLazySingleton<SupabaseClient>(
      () => Supabase.instance.client);

  // ─── Ağ ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(
      InternetConnectionChecker.createInstance(),
    ),
  );

  // ─── Yerel Depolama ───────────────────────────────────────────────────────
  sl.registerLazySingleton<LocalStorageDataSource>(
      () => LocalStorageDataSource());

  // ─── Remote DataSources ───────────────────────────────────────────────────
  sl.registerLazySingleton<SupabaseUserDataSource>(
      () => SupabaseUserDataSource(sl<SupabaseClient>()));
  sl.registerLazySingleton<SupabaseMealDataSource>(
      () => SupabaseMealDataSource(sl<SupabaseClient>()));

  // ─── Use Cases (bağımsız) ─────────────────────────────────────────────────
  sl.registerLazySingleton<GenerateDailyPlan>(() => GenerateDailyPlan());
  sl.registerLazySingleton<CalculateMacros>(() => CalculateMacros());

  // ─── Repository Implementations ───────────────────────────────────────────
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remote: sl<SupabaseUserDataSource>(),
      local: sl<LocalStorageDataSource>(),
    ),
  );

  sl.registerLazySingleton<MealPlanRepository>(
    () => MealPlanRepositoryImpl(
      remote: sl<SupabaseMealDataSource>(),
      local: sl<LocalStorageDataSource>(),
      generateDailyPlan: sl<GenerateDailyPlan>(),
    ),
  );

  sl.registerLazySingleton<MealRepository>(() => MealRepositoryImpl(remoteDataSource: sl<SupabaseMealDataSource>()));
  sl.registerLazySingleton<WorkoutRepository>(() => WorkoutRepositoryImpl());
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(
      planRepo: sl<MealPlanRepository>(),
    ),
  );

  // ─── Use Cases (repository bağıml1) ──────────────────────────────────────
  sl.registerLazySingleton<GetUserProfile>(
      () => GetUserProfile(sl<UserRepository>()));
  sl.registerLazySingleton<UpdateUserProfile>(
      () => UpdateUserProfile(sl<UserRepository>()));
  sl.registerLazySingleton<MarkMealEaten>(
      () => MarkMealEaten(sl<MealPlanRepository>()));
  sl.registerLazySingleton<GetMealAlternatives>(
      () => GetMealAlternatives(sl<MealRepository>()));
  sl.registerLazySingleton<GetWorkoutPrograms>(
      () => GetWorkoutPrograms(sl<WorkoutRepository>()));
  sl.registerLazySingleton<GetWeeklyReport>(
      () => GetWeeklyReport(sl<AnalyticsRepository>()));
  sl.registerLazySingleton<GenerateShoppingList>(
      () => GenerateShoppingList(sl<AnalyticsRepository>()));

  // ─── BLoC'lar ─────────────────────────────────────────────────────────────
  sl.registerFactory<HomeBloc>(
    () => HomeBloc(
      userRepo: sl<UserRepository>(),
      planRepo: sl<MealPlanRepository>(),
      mealRepo: sl<MealRepository>(),
      calculateMacros: sl<CalculateMacros>(),
      markMealEaten: sl<MarkMealEaten>(),
      getMealAlternatives: sl<GetMealAlternatives>(),
    ),
  );

  sl.registerFactory<ProfilBloc>(
    () => ProfilBloc(
      getProfil: sl<GetUserProfile>(),
      updateProfil: sl<UpdateUserProfile>(),
      calculateMacros: sl<CalculateMacros>(),
    ),
  );

  AppLogger.bilgi('✅ Tüm bağımlılıklar başlatıld1');
}

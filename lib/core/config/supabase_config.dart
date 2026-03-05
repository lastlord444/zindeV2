// lib/core/config/supabase_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'URL_BULUNAMADI';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'KEY_BULUNAMADI';

  // Veritaban1 tablolar1
  static const String tabloKullaniciProfili = 'kullanici_profili';
  static const String tabloMeals = 'meals';
  static const String tabloWorkouts = 'workouts';
  static const String tabloDailyPlans = 'daily_plans';
  static const String tabloMealConfirmations = 'meal_confirmations';
}

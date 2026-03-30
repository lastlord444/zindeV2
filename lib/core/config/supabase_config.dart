// lib/core/config/supabase_config.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Web için fallback değerler (development)
  static const String _defaultUrl = 'http://127.0.0.1:54331';
  static const String _defaultKey = 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';
  
  static String get supabaseUrl {
    // Web'de .env yüklenemediyse default kullan
    if (kIsWeb && !dotenv.isInitialized) {
      return _defaultUrl;
    }
    return dotenv.env['SUPABASE_URL'] ?? _defaultUrl;
  }
  
  static String get supabaseAnonKey {
    // Web'de .env yüklenemediyse default kullan
    if (kIsWeb && !dotenv.isInitialized) {
      return _defaultKey;
    }
    return dotenv.env['SUPABASE_ANON_KEY'] ?? _defaultKey;
  }

  // Veritabanı tabloları
  static const String tabloKullaniciProfili = 'kullanici_profili';
  static const String tabloMeals = 'meals';
  static const String tabloWorkouts = 'workouts';
  static const String tabloDailyPlans = 'daily_plans';
  static const String tabloMealConfirmations = 'meal_confirmations';
}

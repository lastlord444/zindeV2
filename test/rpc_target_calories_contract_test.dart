import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RPC Target Calories Contract & Regression Tests', () {
    test('Dart MealOptimizer passes p_target_calories in RPC params map', () {
      final file = File('lib/domain/services/meal_optimizer.dart');
      expect(file.existsSync(), isTrue, reason: 'meal_optimizer.dart bulunamadı.');
      final content = file.readAsStringSync();

      expect(content, contains("'p_target_calories': targetCalories"),
          reason: 'MealOptimizer.optimize içinde get_best_fit_foods çağrısına p_target_calories geçilmiyor.');
      expect(content, contains("'p_target_p_ratio': targetPRatio"));
      expect(content, contains("'p_target_c_ratio': targetCRatio"));
      expect(content, contains("'p_target_f_ratio': targetFRatio"));
      expect(content, contains("'p_meal_type':"));
      expect(content, contains("'p_blacklist_array': blacklistIds"));
      expect(content, contains("'p_limit': 3"));
    });

    test('V5 Migration has p_target_calories parameter and removes hardcoded 500', () {
      final v5File = File('supabase/migrations/20260515130000_v5_meal_optimizer_fix.sql');
      expect(v5File.existsSync(), isTrue, reason: 'V5 migration file bulunamadı.');
      final v5Content = v5File.readAsStringSync();

      expect(v5Content, contains('p_target_calories NUMERIC'),
          reason: 'V5 migration içinde p_target_calories parametresi yok.');
      expect(v5Content, isNot(contains('v_target_calories NUMERIC := 500.0')),
          reason: 'V5 migration içinde hala 500.0 sabiti var!');
      expect(v5Content, contains('p_target_calories / NULLIF(fr.calories_per_100g, 0) AS scaling_factor'),
          reason: 'V5 migration scaling_factor hesabı p_target_calories kullanmıyor.');
    });

    test('V4 Migration had the 500 constant (Documenting the risk)', () {
      final v4File = File('supabase/migrations/20260316_v4_meal_optimizer_rpc.sql');
      if (v4File.existsSync()) {
        final v4Content = v4File.readAsStringSync();
        // V4 içinde bu sabitin olması regression sebebiydi. Bu test, bu gerçeği belgelemek içindir.
        // V4 dosyası değiştirilmez, V5 ile override edilir.
        expect(v4Content, contains('v_target_calories NUMERIC := 500.0'));
      } else {
        markTestSkipped('V4 migration file not found locally, skipping historical assertion.');
      }
    });
  });
}

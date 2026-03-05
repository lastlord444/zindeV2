import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:zinde_ai/domain/entities/gunluk_plan.dart';
import 'package:zinde_ai/domain/entities/makro_hedefleri.dart';
import 'package:zinde_ai/domain/entities/yemek.dart';
import 'package:zinde_ai/domain/usecases/meal_planning/generate_daily_plan.dart';

void main() {
  group('Meal Generation Smoke Test', () {
    final random = Random();
    
    // Generate a diverse pool of 150 meals
    List<Yemek> generateMealPool() {
      final List<Yemek> pool = [];
      int idCounter = 1;
      
      for (final OgunTipi ogun in OgunTipi.values) {
        if (ogun == OgunTipi.cheatMeal) continue;
        
        // Generate 500 meals for each meal type
        for (int i = 0; i < 500; i++) {
          final kalori = 100.0 + random.nextInt(600);
          final protein = kalori * (0.1 + random.nextDouble() * 0.3) / 4.0;
          final carb = kalori * (0.3 + random.nextDouble() * 0.3) / 4.0;
          final fat = (kalori - (protein * 4) - (carb * 4)) / 9.0;
          
          pool.add(Yemek(
            id: 'meal_$idCounter',
            ad: '${ogun.name} Meal $i',
            ogun: ogun,
            kalori: kalori,
            protein: protein,
            karbonhidrat: carb,
            yag: fat > 0 ? fat : 5.0,
            malzemeler: ['Ingredient A', 'Ingredient B'],
            hazirlamaSuresi: 10,
            zorluk: Zorluk.kolay,
            minMultiplier: 0.5,
            maxMultiplier: 3.0,
          ));
          idCounter++;
        }
      }
      return pool;
    }

    test('100 Profiles over 7 Days - Max 2 Repeats and <15% Tolerance', () async {
      final pool = generateMealPool();
      final generator = GenerateDailyPlan();
      
      int totalDaysGenerated = 0;
      int failedToleranceCount = 0;

      // 100 iterations (Profiles)
      for (int p = 0; p < 100; p++) {
        // Random profile 1500 - 3500 calories
        final targetKcal = 1500.0 + random.nextInt(2000);
        final targets = MakroHedefleri(
          gunlukKalori: targetKcal,
          gunlukProtein: targetKcal * 0.3 / 4.0,
          gunlukKarbonhidrat: targetKcal * 0.4 / 4.0,
          gunlukYag: targetKcal * 0.3 / 9.0,
        );

        final Map<String, int> weeklyUsage = {};
        
        // 7 Days
        for (int day = 0; day < 7; day++) {
          final result = await generator.call(
            planId: 'plan_${p}_$day',
            userId: 'user_$p',
            tarih: DateTime.now().add(Duration(days: day)),
            hedefler: targets,
            yemekHavuzu: pool,
            hedef: 'maintain',
            kisitlamalar: [],
            haftalikKullanilanYemekler: weeklyUsage,
          );

          expect(result.isRight(), isTrue, reason: 'Plan failed to generate for Profile $p Day $day');
          
          final plan = result.getOrElse(() => throw Exception('Failed!'));
          
          // Verify Day's Tolerance is within ~10% limit
          final deviation = (plan.toplamKalori - targets.gunlukKalori).abs() / targets.gunlukKalori;
          if (deviation > 0.105) { // Add 0.005 for floating point epsilon
            failedToleranceCount++;
            print('Tolerance exceeded: Profile $p, Day $day, Target: ${targets.gunlukKalori.toStringAsFixed(0)}, Actual: ${plan.toplamKalori.toStringAsFixed(0)}, Deviation: ${(deviation*100).toStringAsFixed(1)}%');
          }
          
          // Register meals in weekly usage tracker and Verify within Day rules
          final dayMeals = plan.tumOgunler;
          final uniqueDayMeals = dayMeals.map((y) => y.id).toSet();
          expect(dayMeals.length, equals(uniqueDayMeals.length), reason: 'A meal was repeated on the same day!');

          for (final meal in dayMeals) {
            weeklyUsage[meal.id] = (weeklyUsage[meal.id] ?? 0) + 1;
            // Immediate assertion: No meal should ever exceed 2 uses in the week
            expect(weeklyUsage[meal.id]! <= 2, isTrue, reason: 'Meal ${meal.id} was used more than 2 times in the week!');
          }
          
          totalDaysGenerated++;
        }
      }

      print('Total Generated Days: $totalDaysGenerated');
      print('Warnings (Tolerance > 10%): $failedToleranceCount');
      
      // Ideally failedToleranceCount should be 0 or very small (meaning our greedy algorithm is stable)
      expect(failedToleranceCount, lessThan(10), reason: 'Too many days exceeded the 10% tolerance hard limit.');
    });
  });
}

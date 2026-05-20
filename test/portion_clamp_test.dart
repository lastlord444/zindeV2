import 'package:flutter_test/flutter_test.dart';
import 'package:zinde_ai/domain/entities/nutrition/yemek.dart';
import 'package:zinde_ai/domain/entities/nutrition/makro_hedefleri.dart';
import 'package:zinde_ai/domain/usecases/meal_planning/generate_daily_plan.dart';

void main() {
  group('Portion Clamping Tests', () {
    late GenerateDailyPlan generateDailyPlan;

    setUp(() {
      generateDailyPlan = GenerateDailyPlan();
    });

    List<Yemek> createMockMeals(OgunTipi ogun, String namePrefix) {
      return List.generate(3, (i) => Yemek(
        id: '${ogun.canonicalName}_$i',
        ad: '$namePrefix $i',
        ogun: ogun,
        kalori: 500.0,
        protein: 25.0,
        karbonhidrat: 75.0,
        yag: 10.0,
        malzemeler: const ['100g Test Malzeme'],
        hazirlamaSuresi: 5,
        zorluk: Zorluk.kolay,
        maxMultiplier: 4.0,
      ));
    }

    test('Should clamp scaled weight to 600g even when target calories require higher multiplier', () async {
      // All meals have 5g protein, 15g carb, 2g fat per 100 kcal ratio.
      // Large meal: 400 kcal, baseWeightG = 300g (so 133 kcal per 100g)
      final largeMeal = Yemek(
        id: 'large_meal_1',
        ad: 'Kıymalı Makarna',
        ogun: OgunTipi.ogle,
        kalori: 400.0,
        protein: 20.0,
        karbonhidrat: 60.0,
        yag: 8.0,
        malzemeler: const ['300g Kıymalı Makarna'],
        hazirlamaSuresi: 20,
        zorluk: Zorluk.orta,
        baseWeightG: 300.0,
        minMultiplier: 0.5,
        maxMultiplier: 3.0,
      );

      // Alternatives (we need at least 2)
      final alt1 = Yemek(
        id: 'large_meal_alt1',
        ad: 'Tavuklu Makarna',
        ogun: OgunTipi.ogle,
        kalori: 400.0,
        protein: 20.0,
        karbonhidrat: 60.0,
        yag: 8.0,
        malzemeler: const ['300g Tavuklu Makarna'],
        hazirlamaSuresi: 20,
        zorluk: Zorluk.orta,
        baseWeightG: 300.0,
        minMultiplier: 0.5,
        maxMultiplier: 3.0,
      );

      final alt2 = Yemek(
        id: 'large_meal_alt2',
        ad: 'Peynirli Makarna',
        ogun: OgunTipi.ogle,
        kalori: 400.0,
        protein: 20.0,
        karbonhidrat: 60.0,
        yag: 8.0,
        malzemeler: const ['300g Peynirli Makarna'],
        hazirlamaSuresi: 15,
        zorluk: Zorluk.kolay,
        baseWeightG: 300.0,
        minMultiplier: 0.5,
        maxMultiplier: 3.0,
      );

      // Other meals to make sure plan generation succeeds
      final kahvaltiList = createMockMeals(OgunTipi.kahvalti, 'Kahvaltı');
      final ara1List = createMockMeals(OgunTipi.araOgun1, 'Ara Ogun 1');
      final ara2List = createMockMeals(OgunTipi.araOgun2, 'Ara Ogun 2');
      final aksamList = createMockMeals(OgunTipi.aksam, 'Aksam');

      final yemekHavuzu = [
        largeMeal, alt1, alt2,
        ...kahvaltiList,
        ...ara1List,
        ...ara2List,
        ...aksamList,
      ];

      // Target calories for lunch is: 3000 * 0.3 = 900 kcal.
      // 900 / 400 = 2.25 multiplier.
      // 300g * 2.25 = 675g portion size.
      // Since our limit is 600g, multiplier should be capped at 2.0x, so scaled weight is 600g (not 675g).
      const hedefler = MakroHedefleri(
        gunlukKalori: 3000,
        gunlukProtein: 150,
        gunlukKarbonhidrat: 450,
        gunlukYag: 60,
      );

      final resultEither = await generateDailyPlan.call(
        planId: 'plan_123',
        userId: 'user_123',
        tarih: DateTime(2026, 5, 20), // static seed date
        hedefler: hedefler,
        yemekHavuzu: yemekHavuzu,
        hedef: 'gain',
        kisitlamalar: const [],
      );

      expect(resultEither.isRight(), isTrue);
      final plan = resultEither.getOrElse(() => throw Exception('Plan failed'));

      // Check lunch meal
      final lunch = plan.ogleYemegi;
      expect(lunch, isNotNull);
      expect(lunch!.baseWeightG, lessThanOrEqualTo(600.001));
      expect(lunch.baseWeightG, closeTo(600.0, 0.1));

      // Check alternatives are also capped
      expect(lunch.alternatifYemekler.length, equals(2));
      for (final alt in lunch.alternatifYemekler) {
        expect(alt.baseWeightG, lessThanOrEqualTo(600.001));
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:zinde_ai/core/errors/failures.dart';
import 'package:zinde_ai/domain/entities/nutrition/makro_hedefleri.dart';
import 'package:zinde_ai/domain/entities/nutrition/yemek.dart';
import 'package:zinde_ai/domain/usecases/meal_planning/generate_daily_plan.dart';

void main() {
  group('Hard Gates Negative Tests', () {
    test('Alternatif sayisi 2 den az ise PlanHatasi donmeli', () async {
      final generator = GenerateDailyPlan();
      
      // Sadece 2 tane kahvalti yemegi veriyoruz. 
      // Biri ana yemek secilince geriye 1 alternatif kalacak, hard gate'e takilacak.
      final List<Yemek> limitedPool = [];
      for (final ogun in OgunTipi.values) {
        if (ogun == OgunTipi.cheatMeal) continue;
        int count = (ogun == OgunTipi.kahvalti) ? 2 : 10;
        for (int i = 0; i < count; i++) {
          limitedPool.add(Yemek(
            id: '${ogun.name}_$i',
            ad: '${ogun.name} Meal $i',
            ogun: ogun,
            kalori: 400,
            protein: 20,
            karbonhidrat: 40,
            yag: 15,
            malzemeler: const ['Malzeme 1'],
            hazirlamaSuresi: 10,
            zorluk: Zorluk.kolay,
            minMultiplier: 0.5,
            maxMultiplier: 3.0,
          ));
        }
      }

      const hedefler = MakroHedefleri(
        gunlukKalori: 2000,
        gunlukProtein: 100,
        gunlukKarbonhidrat: 200,
        gunlukYag: 65,
      );

      final result = await generator.call(
        planId: 'test_plan_1',
        userId: 'test_user_1',
        tarih: DateTime.now(),
        hedefler: hedefler,
        yemekHavuzu: limitedPool,
        hedef: 'maintain',
        kisitlamalar: [],
      );

      expect(result.isLeft(), isTrue, reason: '2 alternatif olmadigi halde Right(plan) dondu!');
      result.fold(
        (failure) {
          expect(failure, isA<PlanHatasi>());
          expect(failure.mesaj.contains('Yeterli alternatif bulunamadı'), isTrue);
        },
        (plan) => fail('Right donmemeliydi'),
      );
    });

    test('Final makro sapmasi %15 uzerindeyse PlanHatasi donmeli', () async {
      final generator = GenerateDailyPlan();
      
      // Tum ogunler icin sadece kalori=125 ve maxMultiplier=1.0 olan 3'er yemek verelim.
      // Hedef kalori ise ogun basina 500 kcal (ratio 4.0) olacak.
      // Alternatifler gecer, ama maxMultiplier 1.0 oldugu icin 125 kcal'de kalir.
      final List<Yemek> limitedPool = [];
      for (final ogun in OgunTipi.values) {
        if (ogun == OgunTipi.cheatMeal) continue;
        for (int i = 0; i < 3; i++) {
          limitedPool.add(Yemek(
            id: '${ogun.name}_$i',
            ad: '${ogun.name} Meal $i',
            ogun: ogun,
            kalori: 400,
            protein: 20.0,
            karbonhidrat: 40.0,
            yag: 13.0,
            malzemeler: const ['Malzeme 1'],
            hazirlamaSuresi: 10,
            zorluk: Zorluk.kolay,
            minMultiplier: 0.3,
            maxMultiplier: 0.3, // Scale olmasina izin vermiyoruz, cok kucuk!
          ));
        }
      }

      // 2000 hedeflersek kahvalti 500 olur (ratio = 4.0 gecerli)
      const hedefler = MakroHedefleri(
        gunlukKalori: 2000,
        gunlukProtein: 100,
        gunlukKarbonhidrat: 200,
        gunlukYag: 65,
      );

      final result = await generator.call(
        planId: 'test_plan_2',
        userId: 'test_user_2',
        tarih: DateTime.now(),
        hedefler: hedefler,
        yemekHavuzu: limitedPool,
        hedef: 'maintain',
        kisitlamalar: [],
      );

      expect(result.isLeft(), isTrue, reason: 'Sapma %15 i astigi halde Right(plan) dondu!');
      result.fold(
        (failure) {
          expect(failure, isA<PlanHatasi>());
          expect(failure.mesaj.contains('Final Validasyon Hatası'), isTrue);
        },
        (plan) => fail('Right donmemeliydi'),
      );
    });
  });
}

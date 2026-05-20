import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zinde_ai/core/errors/failures.dart';
import 'package:zinde_ai/domain/entities/nutrition/yemek.dart';
import 'package:zinde_ai/domain/entities/nutrition/makro_hedefleri.dart';
import 'package:zinde_ai/domain/entities/nutrition/meal_optimization_result.dart';
import 'package:zinde_ai/domain/entities/nutrition/gunluk_plan.dart';
import 'package:zinde_ai/domain/repositories/meal_plan_repository.dart';
import 'package:zinde_ai/domain/repositories/meal_repository.dart';
import 'package:zinde_ai/domain/services/circadian_feedback_service.dart';
import 'package:zinde_ai/domain/entities/user/kullanici_profili.dart';
import 'package:zinde_ai/domain/entities/user/hedef.dart';

class FakePostgrestFilterBuilder<T> implements PostgrestFilterBuilder<T> {
  final List<dynamic> _value;
  FakePostgrestFilterBuilder(this._value);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return this;
  }

  @override
  Future<S> then<S>(FutureOr<S> Function(T value) onValue, {Function? onError}) {
    return Future.value(_value as T).then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    return Future.value(_value as T).catchError(onError, test: test);
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) {
    return Future.value(_value as T).timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return Future.value(_value as T).whenComplete(action);
  }

  @override
  Stream<T> asStream() {
    return Future.value(_value as T).asStream();
  }
}

class FakeSupabaseClient implements SupabaseClient {
  final List<dynamic> rpcResult;
  FakeSupabaseClient(this.rpcResult);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #rpc) {
      final fnName = invocation.positionalArguments.first;
      if (fnName == 'get_best_fit_foods') {
        return FakePostgrestFilterBuilder<List<dynamic>>(rpcResult);
      }
      return FakePostgrestFilterBuilder<List<dynamic>>([]);
    }
    throw UnimplementedError('Method ${invocation.memberName} not implemented');
  }
}

class FakeMealPlanRepository implements MealPlanRepository {
  GunlukPlan? plan;
  GunlukPlan? updatedPlan;

  @override
  Future<Either<Failure, GunlukPlan?>> gunlukPlanGetir(String userId, DateTime tarih) async {
    return Right(plan);
  }

  @override
  Future<Either<Failure, GunlukPlan>> gunlukPlanOlustur({
    required String userId,
    required DateTime tarih,
    required MakroHedefleri hedefler,
    required List<Yemek> yemekHavuzu,
    required String hedef,
    required List<String> kisitlamalar,
    Map<String, int> haftalikKullanilanYemekler = const {},
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, GunlukPlan>> gunlukPlanGuncelle(GunlukPlan plan) async {
    updatedPlan = plan;
    return Right(plan);
  }

  @override
  Future<Either<Failure, GunlukPlan>> ogunDurumuGuncelle({
    required String userId,
    required DateTime tarih,
    required String yemekId,
    required String durum,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<GunlukPlan>>> haftalikPlanlarGetir(String userId, DateTime baslangic) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> gunlukPlanSil(String userId, DateTime tarih) async {
    throw UnimplementedError();
  }
}

class FakeMealRepository implements MealRepository {
  @override
  Future<Either<Failure, List<Yemek>>> tumYemekleriGetir() async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Yemek>>> ogunYemekleriGetir(String ogunTipi) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Yemek>>> uygunYemekleriGetir({
    required String ogunTipi,
    required List<String> kisitlamalar,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Yemek>>> favoriYemekleriGetir(String userId) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> favoriyeEkle(String userId, String yemekId) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> favoridenCikar(String userId, String yemekId) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Yemek>>> alternatifYemekleriGetir({
    required Yemek mevcutYemek,
    required List<String> kisitlamalar,
    int sayi = 5,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('Meal Optimization Result and CircadianFeedbackService Double-Scaling Tests', () {
    test('MealOptimizationResult should store and use mainMeal without double-scaling', () {
      final mainMeal = Yemek(
        id: '1',
        ad: 'Fit Pankek',
        ogun: OgunTipi.kahvalti,
        kalori: 400.0,
        protein: 20.0,
        karbonhidrat: 40.0,
        yag: 15.0,
        malzemeler: const ['1 Yumurta', '50g Yulaf Unu'],
        hazirlamaSuresi: 10,
        zorluk: Zorluk.kolay,
        minMultiplier: 0.5,
        maxMultiplier: 3.0,
        baseWeightG: 200.0,
      );

      final result = MealOptimizationResult(
        mainMeal: mainMeal,
        alternatives: const [],
        targetCalories: 400.0,
        scalingFactor: 2.0,
        scaledGrams: 200.0,
        mealType: 'kahvalti',
      );

      // Verify that mainMeal fields are matched exactly and no additional scaling was applied by getters (as getters are removed)
      expect(result.mainMeal.kalori, 400.0);
      expect(result.mainMeal.protein, 20.0);
      expect(result.mainMeal.karbonhidrat, 40.0);
      expect(result.mainMeal.yag, 15.0);
      expect(result.mainMeal.baseWeightG, 200.0);
    });

    test('CircadianFeedbackService should apply fatigue adjustment and update meals without double-scaling', () async {
      final baseMeal = Yemek(
        id: 'kahvalti_1',
        ad: 'Yulaf Lapası',
        ogun: OgunTipi.kahvalti,
        kalori: 300.0,
        protein: 10.0,
        karbonhidrat: 50.0,
        yag: 5.0,
        malzemeler: const ['100g Yulaf'],
        hazirlamaSuresi: 10,
        zorluk: Zorluk.kolay,
        minMultiplier: 0.5,
        maxMultiplier: 3.0,
        baseWeightG: 100.0,
      );

      const hedefler = MakroHedefleri(
        gunlukKalori: 2000,
        gunlukProtein: 100,
        gunlukKarbonhidrat: 250,
        gunlukYag: 60,
      );

      final plan = GunlukPlan(
        id: 'plan_1',
        userId: 'user_1',
        tarih: DateTime.now(),
        hedefler: hedefler,
        kahvalti: baseMeal,
        ogunDurumlari: const {
          'kahvalti_1': 'bekliyor',
        },
      );

      final fakePlanRepo = FakeMealPlanRepository()..plan = plan;
      final fakeMealRepo = FakeMealRepository();

      // RPC mock output. Calories per 100g is 150 kcal.
      // Scaling factor is 2.6666666666666665. So calories will be 400 kcal (which matches target calories).
      final mockRpcResult = [
        {
          'food_id': 'fit_pankek_id',
          'food_name': 'Fit Pankek',
          'calories_per_100g': 150.0,
          'protein_g': 10.0,
          'carbs_g': 20.0,
          'fat_g': 3.33,
          'euclidean_distance': 0.01,
          'scaled_grams': 266.6666666666667,
          'scaling_factor': 2.6666666666666665
        },
        {
          'food_id': 'alt_1',
          'food_name': 'Alt 1',
          'calories_per_100g': 150.0,
          'protein_g': 10.0,
          'carbs_g': 20.0,
          'fat_g': 3.33,
          'euclidean_distance': 0.02,
          'scaled_grams': 266.6666666666667,
          'scaling_factor': 2.6666666666666665
        },
        {
          'food_id': 'alt_2',
          'food_name': 'Alt 2',
          'calories_per_100g': 150.0,
          'protein_g': 10.0,
          'carbs_g': 20.0,
          'fat_g': 3.33,
          'euclidean_distance': 0.03,
          'scaled_grams': 266.6666666666667,
          'scaling_factor': 2.6666666666666665
        }
      ];

      final fakeSupabase = FakeSupabaseClient(mockRpcResult);

      final service = CircadianFeedbackService(
        planRepo: fakePlanRepo,
        mealRepo: fakeMealRepo,
        supabase: fakeSupabase,
      );

      final userProfile = KullaniciProfili(
        id: 'user_1',
        ad: 'Test',
        soyad: 'User',
        yas: 25,
        boy: 175.0,
        mevcutKilo: 70.0,
        hedefKilo: 70.0,
        cinsiyet: Cinsiyet.erkek,
        aktiviteSeviyesi: AktiviteSeviyesi.ortaAktif,
        hedef: Hedef.maintain,
        diyetTipi: DiyetTipi.normal,
        kayitTarihi: DateTime.now(),
      );

      // Apply fatigue level 'high'
      // Under high fatigue, circadian_feedback_service adjusts goals:
      // Kahvaltı target calories becomes: baseMeal.kalori + fatigueAdjustment
      final resultEither = await service.applyFatigueAdjustment(
        userId: 'user_1',
        tarih: DateTime.now(),
        kullanici: userProfile,
        fatigueLevel: 'high',
      );

      expect(resultEither, isNotNull);

      final updatedPlan = fakePlanRepo.updatedPlan;
      expect(updatedPlan, isNotNull);

      final newKahvalti = updatedPlan!.kahvalti;
      expect(newKahvalti, isNotNull);
      expect(newKahvalti!.id, 'fit_pankek_id');

      // Crucial Check:
      // The meal generated by optimizer has baseWeightG = 266.67g (150 kcal/100g * 2.6667 = 400 kcal).
      // Under double scaling, it would have been scaled by 2.6667 AGAIN:
      // Kalori: 400 * 2.6667 = 1066.7 kcal.
      // With our fix, it should be exactly 400.0 kcal (no second scaling applied!).
      expect(newKahvalti.kalori, equals(400.0));
      expect(newKahvalti.baseWeightG, closeTo(266.67, 0.01));
      expect(newKahvalti.protein, closeTo(26.67, 0.01));
      expect(newKahvalti.karbonhidrat, closeTo(53.33, 0.01));
      expect(newKahvalti.yag, closeTo(8.88, 0.01));
    });
  });
}

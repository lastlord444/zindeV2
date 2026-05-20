import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zinde_ai/core/errors/failures.dart';
import 'package:zinde_ai/domain/entities/nutrition/yemek.dart';
import 'package:zinde_ai/domain/entities/nutrition/makro_hedefleri.dart';
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
  final List<String> calledMealTypes = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #rpc) {
      final fnName = invocation.positionalArguments.first;
      if (fnName == 'get_best_fit_foods') {
        final Map<String, dynamic> params = invocation.namedArguments[#params] ?? {};
        final pMealType = params['p_meal_type'] as String?;
        if (pMealType != null) {
          calledMealTypes.add(pMealType);
        }

        final double targetCal = (params['p_target_calories'] as num?)?.toDouble() ?? 400.0;
        final double scalingFactor = targetCal / 150.0;
        final double scaledGrams = scalingFactor * 100.0;

        return FakePostgrestFilterBuilder<List<dynamic>>([
          {
            'food_id': 'fit_pankek_id',
            'food_name': 'Fit Pankek',
            'calories_per_100g': 150.0,
            'protein_g': 10.0,
            'carbs_g': 20.0,
            'fat_g': 3.33,
            'euclidean_distance': 0.01,
            'scaled_grams': scaledGrams,
            'scaling_factor': scalingFactor,
          },
          {
            'food_id': 'alt_1',
            'food_name': 'Alt 1',
            'calories_per_100g': 150.0,
            'protein_g': 10.0,
            'carbs_g': 20.0,
            'fat_g': 3.33,
            'euclidean_distance': 0.02,
            'scaled_grams': scaledGrams,
            'scaling_factor': scalingFactor,
          },
          {
            'food_id': 'alt_2',
            'food_name': 'Alt 2',
            'calories_per_100g': 150.0,
            'protein_g': 10.0,
            'carbs_g': 20.0,
            'fat_g': 3.33,
            'euclidean_distance': 0.03,
            'scaled_grams': scaledGrams,
            'scaling_factor': scalingFactor,
          }
        ]);
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
  group('CircadianFeedbackService Goal-Specific Meal Distribution Tests', () {
    late FakeMealPlanRepository fakePlanRepo;
    late FakeMealRepository fakeMealRepo;

    final mockYemek = Yemek(
      id: 'fit_pankek_id',
      ad: 'Fit Pankek',
      ogun: OgunTipi.kahvalti,
      kalori: 400.0,
      protein: 20.0,
      karbonhidrat: 40.0,
      yag: 10.0,
      malzemeler: const ['1 adet Yumurta'],
      hazirlamaSuresi: 10,
      zorluk: Zorluk.kolay,
      minMultiplier: 0.5,
      maxMultiplier: 3.0,
      baseWeightG: 100.0,
    );

    setUp(() {
      fakePlanRepo = FakeMealPlanRepository();
      fakeMealRepo = FakeMealRepository();

      // Pre-fill existing plan with all 6 meals to test skipped ones
      fakePlanRepo.plan = GunlukPlan(
        id: 'plan_1',
        userId: 'user_1',
        tarih: DateTime.now(),
        hedefler: const MakroHedefleri(
          gunlukKalori: 2000.0,
          gunlukProtein: 100.0,
          gunlukKarbonhidrat: 250.0,
          gunlukYag: 60.0,
        ),
        kahvalti: mockYemek.copyWith(id: 'kahvalti_id', ad: 'Kahvaltı Yemek'),
        araOgun1: mockYemek.copyWith(id: 'ara_1_id', ad: 'Ara 1 Yemek'),
        ogleYemegi: mockYemek.copyWith(id: 'ogle_id', ad: 'Öğle Yemek'),
        araOgun2: mockYemek.copyWith(id: 'ara_2_id', ad: 'Ara 2 Yemek'),
        aksamYemegi: mockYemek.copyWith(id: 'aksam_id', ad: 'Akşam Yemek'),
        geceAtistirma: mockYemek.copyWith(id: 'gece_id', ad: 'Gece Yemek'),
      );
    });

    test('should skip araOgun2 and geceAtistirma under cut target', () async {
      final fakeSupabase = FakeSupabaseClient();
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
        hedef: Hedef.cut,
        diyetTipi: DiyetTipi.normal,
        kayitTarihi: DateTime.now(),
      );

      await service.applyFatigueAdjustment(
        userId: 'user_1',
        tarih: DateTime.now(),
        kullanici: userProfile,
        fatigueLevel: 'high',
      );

      // Verify called meal types (canonical names)
      expect(fakeSupabase.calledMealTypes, contains('kahvalti'));
      expect(fakeSupabase.calledMealTypes, contains('ara_ogun_1'));
      expect(fakeSupabase.calledMealTypes, contains('ogle'));
      expect(fakeSupabase.calledMealTypes, contains('aksam'));

      // Should NOT call araOgun2 (ara_ogun_2) and geceAtistirma (gece_atistirmasi)
      expect(fakeSupabase.calledMealTypes, isNot(contains('ara_ogun_2')));
      expect(fakeSupabase.calledMealTypes, isNot(contains('gece_atistirmasi')));

      // Should keep original values in updated plan for skipped meals
      final updatedPlan = fakePlanRepo.updatedPlan;
      expect(updatedPlan, isNotNull);
      expect(updatedPlan!.araOgun2!.id, 'ara_2_id'); // Untouched
      expect(updatedPlan.geceAtistirma!.id, 'gece_id'); // Untouched
    });

    test('should skip geceAtistirma under maintain target', () async {
      final fakeSupabase = FakeSupabaseClient();
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

      await service.applyFatigueAdjustment(
        userId: 'user_1',
        tarih: DateTime.now(),
        kullanici: userProfile,
        fatigueLevel: 'high',
      );

      // Verify called meal types
      expect(fakeSupabase.calledMealTypes, contains('kahvalti'));
      expect(fakeSupabase.calledMealTypes, contains('ara_ogun_1'));
      expect(fakeSupabase.calledMealTypes, contains('ogle'));
      expect(fakeSupabase.calledMealTypes, contains('ara_ogun_2'));
      expect(fakeSupabase.calledMealTypes, contains('aksam'));

      // Should NOT call geceAtistirma (gece_atistirmasi)
      expect(fakeSupabase.calledMealTypes, isNot(contains('gece_atistirmasi')));

      final updatedPlan = fakePlanRepo.updatedPlan;
      expect(updatedPlan, isNotNull);
      expect(updatedPlan!.geceAtistirma!.id, 'gece_id'); // Untouched
    });

    test('should optimize all 6 meals under bulk target', () async {
      final fakeSupabase = FakeSupabaseClient();
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
        hedef: Hedef.bulk,
        diyetTipi: DiyetTipi.normal,
        kayitTarihi: DateTime.now(),
      );

      await service.applyFatigueAdjustment(
        userId: 'user_1',
        tarih: DateTime.now(),
        kullanici: userProfile,
        fatigueLevel: 'high',
      );

      // Verify called meal types
      expect(fakeSupabase.calledMealTypes, contains('kahvalti'));
      expect(fakeSupabase.calledMealTypes, contains('ara_ogun_1'));
      expect(fakeSupabase.calledMealTypes, contains('ogle'));
      expect(fakeSupabase.calledMealTypes, contains('ara_ogun_2'));
      expect(fakeSupabase.calledMealTypes, contains('aksam'));
      expect(fakeSupabase.calledMealTypes, contains('gece_atistirmasi'));

      final updatedPlan = fakePlanRepo.updatedPlan;
      expect(updatedPlan, isNotNull);
      // All of them should be optimized (their IDs should be updated to match the mock RPC result, which is fit_pankek_id)
      expect(updatedPlan!.kahvalti!.id, 'fit_pankek_id');
      expect(updatedPlan.araOgun1!.id, 'fit_pankek_id');
      expect(updatedPlan.ogleYemegi!.id, 'fit_pankek_id');
      expect(updatedPlan.araOgun2!.id, 'fit_pankek_id');
      expect(updatedPlan.aksamYemegi!.id, 'fit_pankek_id');
      expect(updatedPlan.geceAtistirma!.id, 'fit_pankek_id');
    });
  });
}

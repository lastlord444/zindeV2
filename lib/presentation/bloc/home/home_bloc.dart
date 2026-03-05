// lib/presentation/bloc/home/home_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/repositories/meal_repository.dart';
import '../../../domain/repositories/meal_plan_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/usecases/user/calculate_macros.dart';
import '../../../domain/usecases/meal_planning/mark_meal_eaten.dart';
import '../../../domain/usecases/meal_planning/get_meal_alternatives.dart';
import 'home_event.dart';
import 'home_state.dart';

/// Ana Sayfa BLoC
/// Günlük beslenme planın1 yönetir
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final UserRepository _userRepo;
  final MealPlanRepository _planRepo;
  final MealRepository _mealRepo;
  final CalculateMacros _calculateMacros;
  final MarkMealEaten _markMealEaten;
  final GetMealAlternatives _getMealAlternatives;

  String? _userId;
  DateTime _secilenTarih = DateTime.now();

  HomeBloc({
    required UserRepository userRepo,
    required MealPlanRepository planRepo,
    required MealRepository mealRepo,
    required CalculateMacros calculateMacros,
    required MarkMealEaten markMealEaten,
    required GetMealAlternatives getMealAlternatives,
  })  : _userRepo = userRepo,
        _planRepo = planRepo,
        _mealRepo = mealRepo,
        _calculateMacros = calculateMacros,
        _markMealEaten = markMealEaten,
        _getMealAlternatives = getMealAlternatives,
        super(const HomeInitial()) {
    on<LoadHomePage>(_onLoadHomePage);
    on<LoadPlanByDate>(_onLoadPlanByDate);
    on<RefreshDailyPlan>(_onRefreshDailyPlan);
    on<MarkMealAsEaten>(_onMarkMealAsEaten);
    on<SkipMeal>(_onSkipMeal);
    on<ConfirmMealEaten>(_onConfirmMealEaten);
    on<ResetMealStatus>(_onResetMealStatus);
    on<GenerateAlternativeMeals>(_onGenerateAlternativeMeals);
    on<ReplaceMealWith>(_onReplaceMealWith);
    on<GenerateIngredientAlternatives>(_onGenerateIngredientAlternatives);
    on<ReplaceIngredientWith>(_onReplaceIngredientWith);
    on<CancelAlternativeSelection>(_onCancelAlternativeSelection);
    on<CancelAlternativeMealSelection>(_onCancelAlternativeMealSelection);
  }

  Future<void> _onLoadHomePage(
      LoadHomePage event, Emitter<HomeState> emit) async {
    emit(const HomeLoading(progress: 0.1, mesaj: 'Profil yükleniyor...'));

    // Kullanıc1 profilini getir
    final profilResult = await _userRepo.onbellektenProfilGetir();
    if (profilResult == null) {
      emit(const HomeError('Profil bulunamad1. Lütfen önce profilinizi oluşturun.'));
      return;
    }

    _userId = profilResult.id;
    final makrolar = _calculateMacros(profilResult);

    emit(const HomeLoading(
      progress: 0.4,
      mesaj: 'Beslenme plan1 aranıyor...',
    ));

    // Bugünkü plan1 getir
    final planResult = await _planRepo.gunlukPlanGetir(_userId!, _secilenTarih);

    await planResult.fold(
      (hata) async => emit(HomeError(hata.mesaj)),
      (plan) async {
        if (plan != null) {
          emit(HomeLoaded(
            plan: plan,
            hedefler: makrolar,
            tamamlananOgunler: plan.tamamlananOgunler,
            secilenTarih: _secilenTarih,
          ));
        } else {
          // Plan yok â†’ yeni plan oluştur
          emit(const HomeLoading(progress: 0.6, mesaj: 'Plan oluşturuluyor...'));

          final yemeklerResult = await _mealRepo.tumYemekleriGetir();
          await yemeklerResult.fold(
            (hata) async => emit(HomeError(hata.mesaj)),
            (yemekler) async {
              // Haftalık kullanılan yemek frekansini topla (max 2 limit icin)
              final haftaBasi = _secilenTarih.subtract(
                Duration(days: _secilenTarih.weekday - 1),
              );
              final haftalikResult = await _planRepo.haftalikPlanlarGetir(
                _userId!, haftaBasi,
              );
              final haftalikKullanim = <String, int>{};
              haftalikResult.fold(
                (_) {}, // hata durumunda boş map ile devam et
                (planlar) {
                  for (final p in planlar) {
                    for (final y in p.tumOgunler) {
                      haftalikKullanim[y.id] = (haftalikKullanim[y.id] ?? 0) + 1;
                    }
                  }
                },
              );

              final yeniPlanResult = await _planRepo.gunlukPlanOlustur(
                userId: _userId!,
                tarih: _secilenTarih,
                hedefler: makrolar,
                yemekHavuzu: yemekler,
                hedef: profilResult.hedef.name,
                kisitlamalar: profilResult.tumKisitlamalar,
                haftalikKullanilanYemekler: haftalikKullanim,
              );

              yeniPlanResult.fold(
                (hata) => emit(HomeError(hata.mesaj)),
                (yeniPlan) => emit(HomeLoaded(
                  plan: yeniPlan,
                  hedefler: makrolar,
                  tamamlananOgunler: yeniPlan.tamamlananOgunler,
                  secilenTarih: _secilenTarih,
                )),
              );
            },
          );
        }
      },
    );
  }

  Future<void> _onLoadPlanByDate(
      LoadPlanByDate event, Emitter<HomeState> emit) async {
    _secilenTarih = event.tarih;
    add(const LoadHomePage());
  }

  Future<void> _onRefreshDailyPlan(
      RefreshDailyPlan event, Emitter<HomeState> emit) async {
    if (_userId == null) {
      add(const LoadHomePage());
      return;
    }
    if (event.forceRegenerate) {
      await _planRepo.gunlukPlanSil(_userId!, _secilenTarih);
    }
    add(const LoadHomePage());
  }

  Future<void> _onMarkMealAsEaten(
      MarkMealAsEaten event, Emitter<HomeState> emit) async {
    await _guncelleOgunDurumu(event.yemekId, 'yenildi', emit);
  }

  Future<void> _onSkipMeal(SkipMeal event, Emitter<HomeState> emit) async {
    await _guncelleOgunDurumu(event.yemekId, 'atlandi', emit);
  }

  Future<void> _onConfirmMealEaten(
      ConfirmMealEaten event, Emitter<HomeState> emit) async {
    await _guncelleOgunDurumu(event.yemekId, 'onaylandi', emit);
  }

  Future<void> _onResetMealStatus(
      ResetMealStatus event, Emitter<HomeState> emit) async {
    await _guncelleOgunDurumu(event.yemekId, 'yenilecek', emit);
  }

  Future<void> _guncelleOgunDurumu(
      String yemekId, String durum, Emitter<HomeState> emit) async {
    if (_userId == null || state is! HomeLoaded) return;
    final mevcutState = state as HomeLoaded;

    final sonuc = await _markMealEaten(
      userId: _userId!,
      tarih: _secilenTarih,
      yemekId: yemekId,
      durum: durum,
    );

    sonuc.fold(
      (hata) => AppLogger.uyari('Öğün durumu güncellenemedi: ${hata.mesaj}'),
      (guncelPlan) => emit(HomeLoaded(
        plan: guncelPlan,
        hedefler: mevcutState.hedefler,
        tamamlananOgunler: guncelPlan.tamamlananOgunler,
        secilenTarih: _secilenTarih,
      )),
    );
  }

  Future<void> _onGenerateAlternativeMeals(
      GenerateAlternativeMeals event, Emitter<HomeState> emit) async {
    if (state is! HomeLoaded) return;
    final mevcutState = state as HomeLoaded;

    // Profil kısıtlamaların1 al
    final profil = await _userRepo.onbellektenProfilGetir();
    final kisitlamalar = profil?.tumKisitlamalar ?? [];

    final sonuc = await _getMealAlternatives(
      mevcutYemek: event.mevcutYemek,
      kisitlamalar: kisitlamalar,
      sayi: event.sayi,
    );

    sonuc.fold(
      (hata) => AppLogger.uyari('Alternatifler alınamad1: ${hata.mesaj}'),
      (alternatifler) => emit(AlternativeMealsLoaded(
        plan: mevcutState.plan,
        hedefler: mevcutState.hedefler,
        tamamlananOgunler: mevcutState.tamamlananOgunler,
        alternatifYemekler: alternatifler,
        secilenTarih: _secilenTarih,
        mevcutYemek: event.mevcutYemek,
      )),
    );
  }

  Future<void> _onReplaceMealWith(
      ReplaceMealWith event, Emitter<HomeState> emit) async {
    if (_userId == null || state is! HomeLoaded) return;
    final mevcutState = state as HomeLoaded;

    // Plan iindeki yemeği güncelle
    final guncelPlan = mevcutState.plan.yemekDegistir(
      event.eskiYemek,
      event.yeniYemek,
    );

    await _planRepo.gunlukPlanGuncelle(guncelPlan);

    emit(HomeLoaded(
      plan: guncelPlan,
      hedefler: mevcutState.hedefler,
      tamamlananOgunler: mevcutState.tamamlananOgunler,
      secilenTarih: _secilenTarih,
    ));
  }

  Future<void> _onGenerateIngredientAlternatives(
      GenerateIngredientAlternatives event, Emitter<HomeState> emit) async {
    if (state is! HomeLoaded) return;
    final mevcutState = state as HomeLoaded;

    emit(AlternativeIngredientsLoaded(
      plan: mevcutState.plan,
      hedefler: mevcutState.hedefler,
      tamamlananOgunler: mevcutState.tamamlananOgunler,
      secilenTarih: mevcutState.secilenTarih,
      ogunId: event.yemek.id.toString(),
      besinAdi: event.malzemeMetni,
      alternatifler: const [], // V2 malzeme alternatifi backend bağlandığında güncellenecek
      yemek: event.yemek,
      malzemeIndex: event.malzemeIndex,
      malzemeMetni: event.malzemeMetni,
    ));
  }

  Future<void> _onReplaceIngredientWith(
      ReplaceIngredientWith event, Emitter<HomeState> emit) async {
    if (_userId == null || state is! AlternativeIngredientsLoaded) {
      if (state is HomeLoaded) {
          // AlternativeIngredientsLoaded olmadan buraya geldiyse
          // Mevcut state'i koru
      }
      return;
    }
    
    final altState = state as AlternativeIngredientsLoaded;

    final updatedMalzemeler = List<String>.from(event.yemek.malzemeler);
    if (event.malzemeIndex >= 0 && event.malzemeIndex < updatedMalzemeler.length) {
      updatedMalzemeler[event.malzemeIndex] = event.yeniMalzemeMetni;
    }

    final yeniYemek = event.yemek.copyWith(malzemeler: updatedMalzemeler);
    final guncelPlan = altState.plan.yemekDegistir(event.yemek, yeniYemek);

    await _planRepo.gunlukPlanGuncelle(guncelPlan);

    emit(HomeLoaded(
      plan: guncelPlan,
      hedefler: altState.hedefler,
      tamamlananOgunler: altState.tamamlananOgunler,
      secilenTarih: altState.secilenTarih,
    ));
  }

  void _onCancelAlternativeSelection(
      CancelAlternativeSelection event, Emitter<HomeState> emit) {
    if (state is AlternativeIngredientsLoaded) {
      add(const LoadHomePage());
    }
  }

  void _onCancelAlternativeMealSelection(
      CancelAlternativeMealSelection event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final mevcutState = state as HomeLoaded;
      emit(HomeLoaded(
        plan: mevcutState.plan,
        hedefler: mevcutState.hedefler,
        tamamlananOgunler: mevcutState.tamamlananOgunler,
        alternatifYemekler: null,
        secilenTarih: _secilenTarih,
      ));
    }
  }
}


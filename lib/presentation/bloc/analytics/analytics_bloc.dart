// lib/presentation/bloc/analytics/analytics_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/analytics_repository.dart';
import '../../../domain/repositories/meal_plan_repository.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

/// Analitik BLoC
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository _analyticsRepo;
  final MealPlanRepository _planRepo;
  final String? _userId;
  AnalyticsBloc({
    required AnalyticsRepository analyticsRepo,
    required MealPlanRepository planRepo,
    String? userId,
  })  : _analyticsRepo = analyticsRepo,
        _planRepo = planRepo,
        _userId = userId,
        super(const AnalyticsInitial()) {
    on<LoadWeeklyAnalytics>(_onLoadWeeklyAnalytics);
    on<LoadMonthlyAnalytics>(_onLoadMonthlyAnalytics);
  }

  Future<void> _onLoadWeeklyAnalytics(
      LoadWeeklyAnalytics event, Emitter<AnalyticsState> emit) async {
    if (_userId == null) {
      emit(const AnalyticsHata('Kullanıc1 oturumu bulunamad1'));
      return;
    }
    emit(const AnalyticsYukleniyor());

    final haftaBasi = _buHaftaninBasi();
    final raporResult = await _analyticsRepo.haftalikRaporOlustur(
      userId: _userId!,
      baslangic: haftaBasi,
    );
    final planlarResult = await _planRepo.haftalikPlanlarGetir(_userId!, haftaBasi);

    raporResult.fold(
      (hata) => emit(AnalyticsHata(hata.mesaj)),
      (rapor) => planlarResult.fold(
        (hata) => emit(AnalyticsHata(hata.mesaj)),
        (planlar) => emit(WeeklyAnalyticsLoaded(rapor: rapor, planlar: planlar)),
      ),
    );
  }

  Future<void> _onLoadMonthlyAnalytics(
      LoadMonthlyAnalytics event, Emitter<AnalyticsState> emit) async {
    if (_userId == null) return;
    emit(const AnalyticsYukleniyor());
    final ay = DateTime.now();
    final result = await _analyticsRepo.aylikPlanlarGetir(_userId!, ay);
    result.fold(
      (hata) => emit(AnalyticsHata(hata.mesaj)),
      (planlar) => emit(MonthlyAnalyticsLoaded(planlar)),
    );
  }

  DateTime _buHaftaninBasi() {
    final simdi = DateTime.now();
    return simdi.subtract(Duration(days: simdi.weekday - 1));
  }
}


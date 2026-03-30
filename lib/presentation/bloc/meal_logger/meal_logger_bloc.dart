// lib/presentation/bloc/meal_logger/meal_logger_bloc.dart
// V4 - Production-ready BLoC with error-safe optimistic UI

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/user/kullanici_profili.dart';
import '../../../domain/repositories/user_repository.dart';
import 'meal_logger_event.dart';
import 'meal_logger_state.dart';

/// Meal Logger BLoC
/// 
/// - "Yedim" butonuna basınca UI loading'e girer (optimistic UI YOK)
/// - Supabase user_meal_logs tablosuna insert başarılı olursa AsyncData
/// - İnternet/DB hatası durumunda AsyncError — UI'daki tik geri alınır
class MealLoggerBloc extends Bloc<MealLoggerEvent, MealLoggerState> {
  final UserRepository _userRepo;
  late final SupabaseClient _supabase;
  String? _currentUserId;

  MealLoggerBloc({required UserRepository userRepo})
      : _userRepo = userRepo,
        super(const MealLoggerInitial()) {
    _supabase = Supabase.instance.client;
    on<MealLoggerInit>(_onInit);
    on<MarkAsConsumed>(_onMarkAsConsumed);
    on<MarkAsSkipped>(_onMarkAsSkipped);
    on<UndoMealLog>(_onUndoMealLog);
    on<LoadWeeklyLogs>(_onLoadWeeklyLogs);
  }

  Future<void> _onInit(
      MealLoggerInit event, Emitter<MealLoggerState> emit) async {
    // Kullanıcı ID'sini önbelleğe al
    try {
      final user = await _userRepo.onbellektenProfilGetir();
      if (user == null) {
        emit(const MealLoggerError(message: 'Kullanıcı profili bulunamadı'));
        return;
      }
      _currentUserId = user.id;
      emit(const MealLoggerLoaded({}));
    } catch (e) {
      emit(MealLoggerError(message: 'Başlangıç hatası', details: e.toString()));
    }
  }

  Future<void> _onMarkAsConsumed(
      MarkAsConsumed event, Emitter<MealLoggerState> emit) async {
    if (_currentUserId == null) {
      emit(const MealLoggerError(message: 'Kullanıcı oturum açmamış'));
      return;
    }

    // UI'ı loading yap (optimistic YOK)
    emit(const MealLoggerLoading(message: 'Kaydediliyor...'));

    try {
      // Supabase RPC çağrısı — mark_meal_consumed
      final result = await _supabase.rpc(
        'mark_meal_consumed',
        params: {
          'p_user_id': _currentUserId,
          'p_date': _dateToString(DateTime.now()),
          'p_meal_type': event.mealType,
          'p_food_id': event.foodId,
          'p_consumed_grams': event.consumedGrams,
          'p_status': 'yedi',
        },
      );

      if (result == null) {
        throw Exception('Supabase RPC null döndü');
      }

      final logId = result.toString();
      AppLogger.bilgi('✅ Meal kaydedildi: logId=$logId, foodId=${event.foodId}');

      emit(MealLogSaved(
        logId: logId,
        foodName: event.foodId,
      ));
    } catch (e, stackTrace) {
      AppLogger.hata('❌ Meal kaydedilemedi', e, stackTrace);
      
      // Hata durumunda state AsyncError yap → UI'daki yeşil tik geri alınır
      emit(MealLoggerError(
        message: 'Öğün kaydedilemedi. İnternet bağlantınızı kontrol edin.',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onMarkAsSkipped(
      MarkAsSkipped event, Emitter<MealLoggerState> emit) async {
    if (_currentUserId == null) {
      emit(const MealLoggerError(message: 'Kullanıcı oturum açmamış'));
      return;
    }

    emit(const MealLoggerLoading(message: 'Kaydediliyor...'));

    try {
      final result = await _supabase.rpc(
        'mark_meal_consumed',
        params: {
          'p_user_id': _currentUserId,
          'p_date': _dateToString(DateTime.now()),
          'p_meal_type': event.mealType,
          'p_food_id': event.foodId,
          'p_consumed_grams': 0.0,
          'p_status': 'yemedim',
        },
      );

      if (result == null) throw Exception('Supabase RPC null döndü');

      final logId = result.toString();
      AppLogger.bilgi('⏭️ Meal atlandı: logId=$logId');

      emit(MealLogSaved(logId: logId, foodName: '${event.foodId} (atlandı)'));
    } catch (e, stackTrace) {
      AppLogger.hata('❌ Atlanma kaydedilemedi', e, stackTrace);
      emit(MealLoggerError(
        message: 'İşlem kaydedilemedi. Tekrar deneyin.',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onUndoMealLog(
      UndoMealLog event, Emitter<MealLoggerState> emit) async {
    // Undo için user_meal_logs tablosunda silme/güncelleme yapılabilir
    // Şimdilik basit implementasyon
    try {
      await _supabase
          .from('user_meal_logs')
          .delete()
          .eq('id', event.logId)
          .select();

      AppLogger.bilgi('↩️ Meal log silindi: ${event.logId}');
      emit(const MealLoggerLoaded({}));
    } catch (e) {
      emit(MealLoggerError(message: 'Geri alınamadı', details: e.toString()));
    }
  }

  Future<void> _onLoadWeeklyLogs(
      LoadWeeklyLogs event, Emitter<MealLoggerState> emit) async {
    if (_currentUserId == null) {
      emit(const MealLoggerError(message: 'Kullanıcı oturum açmamış'));
      return;
    }

    final weekEnd = event.weekStart.add(const Duration(days: 6));

    try {
      final data = await _supabase
          .from('user_meal_logs')
          .select()
          .eq('user_id', _currentUserId)
          .gte('date', _dateToString(event.weekStart))
          .lte('date', _dateToString(weekEnd))
          .order('date', ascending: false);

      final Map<String, Map<String, dynamic>> logs = {};
      for (final row in data) {
        final dateStr = row['date']?.toString() ?? '';
        logs[dateStr] = row as Map<String, dynamic>;
      }

      emit(MealLoggerLoaded(logs));
    } catch (e) {
      emit(MealLoggerError(message: 'Haftalık loglar çekilemedi', details: e.toString()));
    }
  }

  String _dateToString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

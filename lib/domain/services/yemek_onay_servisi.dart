// lib/domain/services/yemek_onay_servisi.dart
// Yemek onay servisi shim - Supabase tabanl1

import '../repositories/meal_plan_repository.dart';
import 'package:get_it/get_it.dart';

class YemekOnayServisi {
  final MealPlanRepository _planRepo;

  YemekOnayServisi() : _planRepo = GetIt.instance<MealPlanRepository>();

  Future<void> ogunOnayla(String userId, DateTime tarih, String yemekId) async {
    await _planRepo.ogunDurumuGuncelle(
      userId: userId,
      tarih: tarih,
      yemekId: yemekId,
      durum: 'onaylandi',
    );
  }
}

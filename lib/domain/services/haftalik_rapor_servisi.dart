// lib/domain/services/haftalik_rapor_servisi.dart
// Haftalık rapor servisi shim

import '../repositories/analytics_repository.dart';
import '../entities/analytics/haftalik_rapor.dart';
import 'package:get_it/get_it.dart';

class HaftalikRaporServisi {
  final AnalyticsRepository _analyticsRepo;

  HaftalikRaporServisi()
      : _analyticsRepo = GetIt.instance<AnalyticsRepository>();

  Future<HaftalikRapor?> haftalikRaporGetir(
      String userId, DateTime baslangic) async {
    final result = await _analyticsRepo.haftalikRaporOlustur(
      userId: userId,
      baslangic: baslangic,
    );
    return result.fold((_) => null, (r) => r);
  }

  /// V1 UI uyumluluk - haftalikRaporOlustur metodu alias
  Future<HaftalikRapor?> haftalikRaporOlustur(
      String userId, DateTime baslangic) =>
      haftalikRaporGetir(userId, baslangic);

  /// V1 UI alias - haftalikUyumRaporu
  Future<HaftalikRapor?> haftalikUyumRaporu(
      String userId, DateTime baslangic) =>
      haftalikRaporGetir(userId, baslangic);
}

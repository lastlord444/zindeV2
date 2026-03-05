// lib/domain/services/haftalik_alisveris_servisi.dart
// Alışveriş listesi servisi shim

import '../repositories/analytics_repository.dart';
import '../entities/analytics/alisveris_listesi.dart';
import 'package:get_it/get_it.dart';

class HaftalikAlisverisServisi {
  final AnalyticsRepository _analyticsRepo;

  HaftalikAlisverisServisi()
      : _analyticsRepo = GetIt.instance<AnalyticsRepository>();

  Future<AlisverisListesi?> alisverisListesiOlustur(
      String userId, DateTime haftaBasi) async {
    final result = await _analyticsRepo.alisverisListesiOlustur(
      userId: userId,
      haftaBasi: haftaBasi,
    );
    return result.fold((_) => null, (r) => r);
  }

  /// V1 UI uyumluluk - haftalikAlisverisListesiOlustur metod alias
  Future<AlisverisListesi?> haftalikAlisverisListesiOlustur(
      String userId, DateTime haftaBasi) =>
      alisverisListesiOlustur(userId, haftaBasi);
}

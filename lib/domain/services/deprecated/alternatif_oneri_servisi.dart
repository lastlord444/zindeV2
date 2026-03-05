// lib/domain/services/deprecated/alternatif_oneri_servisi.dart
// ⚠️ Kullanımdan kaldırılmış - GetMealAlternatives use case kullanın

import '../../entities/nutrition/alternatif_besin.dart';

/// V1 uyumlu AlternatifBesinLegacy type alias
typedef AlternatifBesinLegacy = AlternatifBesin;

@Deprecated('GetMealAlternatives use case kullanın')
class AlternatifOneriServisi {
  List<AlternatifBesin> alternatifGetir(String yemekId) => [];

  /// V1 UI uyumluluk - otomatik alternatif üretimi (stub)
  Future<List<AlternatifBesin>> otomatikAlternatifUret({
    required String yemekId,
    required String ogunTipi,
    Map<String, double> hedefMakrolar = const {},
  }) async {
    return []; // Gerekte GetMealAlternatives use case kullanılır
  }
}


// lib/core/config/nutrition_constraints.dart
// ⚡ KRİTİK: Tolerans Sistemi - Diyetisyen Standard1 ±%10

/// Beslenme kısıtlar1 ve tolerans sistemi
class NutritionConstraints {
  // ─── Tolerans Oranlar1 ───────────────────────────────────────────────────
  /// Günlük kalori tolerans1: ±%10
  static const double caloriTolerancePct = 0.10;

  /// Makro (protein/karb/yağ) tolerans1: ±%10
  static const double macroTolerancePct = 0.10;

  /// Öğün başına tolerans: ±%20 (daha geniş)
  static const double mealTolerancePct = 0.20;

  /// Fallback tolerans: %10 (4. aşama)
  static const double fallbackTolerancePct = 0.10;

  // ─── Hedef Bazl1 Öğün Sayıs1 ─────────────────────────────────────────────
  /// Hedef bazl1 günlük öğün sayıs1
  static int ogunSayisiGetir(String hedef) {
    switch (hedef.toLowerCase()) {
      case 'bulk':
        return 6; // Kahvalt1 + Ara1 + Öğle + Ara2 + Akşam + Gece
      case 'maintain':
        return 5; // Kahvalt1 + Ara1 + Öğle + Ara2 + Akşam
      case 'cut':
        return 4; // Kahvalt1 + Ara1 + Öğle + Akşam
      default:
        return 5;
    }
  }

  // ─── Hedef Bazl1 Öğün Kalori Dağılım1 ────────────────────────────────────
  /// Hedef bazl1 öğün kalori dağılım1 (0.0-1.0 aras1 oran)
  static Map<String, double> ogunDagilimGetir(String hedef) {
    switch (hedef.toLowerCase()) {
      case 'bulk':
        return {
          'kahvalti': 0.20,
          'araOgun1': 0.10,
          'ogle': 0.27,
          'araOgun2': 0.10,
          'aksam': 0.25,
          'geceAtistirma': 0.08,
        };
      case 'maintain':
        return {
          'kahvalti': 0.25,
          'araOgun1': 0.10,
          'ogle': 0.30,
          'araOgun2': 0.10,
          'aksam': 0.25,
        };
      case 'cut':
        return {
          'kahvalti': 0.25,
          'araOgun1': 0.10,
          'ogle': 0.40,
          'aksam': 0.25,
        };
      default:
        return ogunDagilimGetir('maintain');
    }
  }

  // ─── Tolerans Kontrol Yardımcılar1 ───────────────────────────────────────
  /// Belirtilen tolerans iinde mi?
  static bool toleranstaIse(double mevcut, double hedef, double tolerans) {
    if (hedef == 0) return true;
    final fark = (mevcut - hedef).abs();
    return fark <= hedef * tolerans;
  }

  /// Sapma yüzdesini hesapla
  static double sapimaYuzdesi(double mevcut, double hedef) {
    if (hedef == 0) return 0;
    return ((mevcut - hedef).abs() / hedef) * 100;
  }

  // ─── Makro Hesaplama (Mifflin-St Jeor) ───────────────────────────────────
  /// BMR hesapla
  static double bmrHesapla({
    required double kilo,     // kg
    required double boy,      // cm
    required int yas,
    required bool erkekMi,
  }) {
    final bmr = (10 * kilo) + (6.25 * boy) - (5 * yas);
    return erkekMi ? bmr + 5 : bmr - 161;
  }

  /// Aktivite katsayılar1
  static const Map<String, double> aktiviteKatsayilari = {
    'sedanter': 1.2,
    'hafifAktif': 1.375,
    'ortaAktif': 1.55,
    'cokAktif': 1.725,
    'atletik': 1.9,
  };

  /// TDEE = BMR × aktivite katsayıs1
  static double tdeeHesapla(double bmr, String aktiviteSeviyesi) {
    final katsayi = aktiviteKatsayilari[aktiviteSeviyesi] ?? 1.55;
    return bmr * katsayi;
  }

  /// Hedef bazl1 günlük kalori
  static double gunlukKaloriHesapla(double tdee, String hedef) {
    switch (hedef.toLowerCase()) {
      case 'bulk':
        return tdee + 400; // +400 kcal surplus
      case 'cut':
        return tdee - 400; // -400 kcal deficit
      case 'maintain':
      default:
        return tdee;
    }
  }

  /// Protein gram1 = hedef kilo × 2.0-2.2 g/kg
  static double proteinHesapla(double hedefKilo) => hedefKilo * 2.1;

  /// Yağ gram1 = toplam kalorinin %30'u ÷ 9 kcal/g
  static double yagHesapla(double gunlukKalori) => (gunlukKalori * 0.30) / 9;

  /// Karbonhidrat gram1 = kalan kalori ÷ 4 kcal/g
  static double karbonhidratHesapla(
      double gunlukKalori, double protein, double yag) {
    final proteinKalori = protein * 4;
    final yagKalori = yag * 9;
    final kalanKalori = gunlukKalori - proteinKalori - yagKalori;
    return (kalanKalori / 4).clamp(0, double.infinity);
  }

  // ─── V1 UI Uyumluluk - İngilizce Takma Metotlar ─────────────────────────
  /// Aktif tolerans yüzdesi (getter olarak)
  static double get tolerancePct => caloriTolerancePct;

  /// Kalori toleransta m1?
  static bool isCalorieWithinTolerance(double mevcut, double hedef) =>
      toleranstaIse(mevcut, hedef, caloriTolerancePct);

  /// Protein toleransta m1?
  static bool isProteinWithinTolerance(double mevcut, double hedef) =>
      toleranstaIse(mevcut, hedef, macroTolerancePct);

  /// Karbonhidrat toleransta m1?
  static bool isCarbsWithinTolerance(double mevcut, double hedef) =>
      toleranstaIse(mevcut, hedef, macroTolerancePct);

  /// Yağ toleransta m1?
  static bool isFatWithinTolerance(double mevcut, double hedef) =>
      toleranstaIse(mevcut, hedef, macroTolerancePct);
}


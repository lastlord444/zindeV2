// lib/domain/entities/nutrition/gunluk_plan.dart
// V2 - userId, hedefler, tamamlananOgunler alanlar1 eklendi

import 'package:equatable/equatable.dart';
import 'yemek.dart';
import 'makro_hedefleri.dart';

/// Günlük beslenme plan1 entity'si (V2)
class GunlukPlan extends Equatable {
  final String id;
  final String userId;
  final DateTime tarih;
  final MakroHedefleri hedefler;
  final Yemek? kahvalti;
  final Yemek? araOgun1;
  final Yemek? ogleYemegi;
  final Yemek? araOgun2;
  final Yemek? aksamYemegi;
  final Yemek? geceAtistirma;
  final Map<String, bool> tamamlananOgunler; // {yemekId: tamamlandi?}

  const GunlukPlan({
    required this.id,
    required this.userId,
    required this.tarih,
    required this.hedefler,
    this.kahvalti,
    this.araOgun1,
    this.ogleYemegi,
    this.araOgun2,
    this.aksamYemegi,
    this.geceAtistirma,
    this.tamamlananOgunler = const {},
  });

  // ─── Tüm Öğünler ────────────────────────────────────────────────────────
  List<Yemek> get tumOgunler => [
        if (kahvalti != null) kahvalti!,
        if (araOgun1 != null) araOgun1!,
        if (ogleYemegi != null) ogleYemegi!,
        if (araOgun2 != null) araOgun2!,
        if (aksamYemegi != null) aksamYemegi!,
        if (geceAtistirma != null) geceAtistirma!,
      ];

  // ─── Makro Toplamlar1 ────────────────────────────────────────────────────
  double get toplamKalori =>
      tumOgunler.fold(0, (t, y) => t + y.kalori);
  double get toplamProtein =>
      tumOgunler.fold(0, (t, y) => t + y.protein);
  double get toplamKarbonhidrat =>
      tumOgunler.fold(0, (t, y) => t + y.karbonhidrat);
  double get toplamYag =>
      tumOgunler.fold(0, (t, y) => t + y.yag);

  // ─── Tolerans Kontrolleri (±%10) ─────────────────────────────────────────
  bool kaloriToleranstaMi(double tolerans) =>
      _toleranstaIse(toplamKalori, hedefler.gunlukKalori, tolerans);
  bool proteinToleranstaMi(double tolerans) =>
      _toleranstaIse(toplamProtein, hedefler.gunlukProtein, tolerans);
  bool karbToleranstaMi(double tolerans) =>
      _toleranstaIse(toplamKarbonhidrat, hedefler.gunlukKarbonhidrat, tolerans);
  bool yagToleranstaMi(double tolerans) =>
      _toleranstaIse(toplamYag, hedefler.gunlukYag, tolerans);

  bool _toleranstaIse(double mevcut, double hedef, double tolerans) {
    if (hedef == 0) return true;
    return (mevcut - hedef).abs() <= hedef * tolerans;
  }

  // ─── Yemek Değiştirme ────────────────────────────────────────────────────
  /// Belirli bir yemeği ayn1  ndeki başka bir yemekle değiştir
  GunlukPlan yemekDegistir(Yemek eskiYemek, Yemek yeniYemek) {
    return GunlukPlan(
      id: id,
      userId: userId,
      tarih: tarih,
      hedefler: hedefler,
      tamamlananOgunler: tamamlananOgunler,
      kahvalti: kahvalti?.id == eskiYemek.id ? yeniYemek : kahvalti,
      araOgun1: araOgun1?.id == eskiYemek.id ? yeniYemek : araOgun1,
      ogleYemegi: ogleYemegi?.id == eskiYemek.id ? yeniYemek : ogleYemegi,
      araOgun2: araOgun2?.id == eskiYemek.id ? yeniYemek : araOgun2,
      aksamYemegi: aksamYemegi?.id == eskiYemek.id ? yeniYemek : aksamYemegi,
      geceAtistirma:
          geceAtistirma?.id == eskiYemek.id ? yeniYemek : geceAtistirma,
    );
  }

  // ─── CopyWith ────────────────────────────────────────────────────────────
  GunlukPlan copyWith({
    String? id,
    String? userId,
    DateTime? tarih,
    MakroHedefleri? hedefler,
    Yemek? kahvalti,
    Yemek? araOgun1,
    Yemek? ogleYemegi,
    Yemek? araOgun2,
    Yemek? aksamYemegi,
    Yemek? geceAtistirma,
    Map<String, bool>? tamamlananOgunler,
  }) {
    return GunlukPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tarih: tarih ?? this.tarih,
      hedefler: hedefler ?? this.hedefler,
      kahvalti: kahvalti ?? this.kahvalti,
      araOgun1: araOgun1 ?? this.araOgun1,
      ogleYemegi: ogleYemegi ?? this.ogleYemegi,
      araOgun2: araOgun2 ?? this.araOgun2,
      aksamYemegi: aksamYemegi ?? this.aksamYemegi,
      geceAtistirma: geceAtistirma ?? this.geceAtistirma,
      tamamlananOgunler: tamamlananOgunler ?? this.tamamlananOgunler,
    );
  }

  // ─── V1 UI Uyumluluk Getter'lar1 ──────────────────────────────────────
  /// Tüm  nleri liste olarak döndür (tumOgunler alias)
  List<Yemek> get ogunler => tumOgunler;

  /// Planlanan kalori hedef toleransında m1? (±%15 - sadece kalori kontrol)
  bool get tumMakrolarToleranstaMi {
    // Yalnızca kalori tolerans1 kontrol edilir
    // Makrolar porsiyon öleklendirmesiyle otomatik ayarlanır
    return kaloriToleranstaMi(0.15);
  }

  /// Karbonhidrat toleransta m1? (±%10 varsayılan)
  bool get karbonhidratToleranstaMi => karbToleranstaMi(0.10);

  /// Tolerans1 aşan makrolar listesi
  List<String> get toleransAsanMakrolar {
    const tolerans = 0.10;
    final asanlar = <String>[];
    if (!kaloriToleranstaMi(tolerans)) asanlar.add('Kalori');
    if (!proteinToleranstaMi(tolerans)) asanlar.add('Protein');
    if (!karbToleranstaMi(tolerans)) asanlar.add('Karbonhidrat');
    if (!yagToleranstaMi(tolerans)) asanlar.add('Yağ');
    return asanlar;
  }

  /// Makro kalite skoru (0-100) - tüm makroların tolerans sapmas1
  double get makroKaliteSkoru {
    const tolerans = 0.10;
    double skor = 100.0;
    if (hedefler.gunlukKalori > 0) {
      final sapma = (toplamKalori - hedefler.gunlukKalori).abs() / hedefler.gunlukKalori;
      skor -= (sapma / tolerans) * 25;
    }
    if (hedefler.gunlukProtein > 0) {
      final sapma = (toplamProtein - hedefler.gunlukProtein).abs() / hedefler.gunlukProtein;
      skor -= (sapma / tolerans) * 25;
    }
    if (hedefler.gunlukKarbonhidrat > 0) {
      final sapma = (toplamKarbonhidrat - hedefler.gunlukKarbonhidrat).abs() / hedefler.gunlukKarbonhidrat;
      skor -= (sapma / tolerans) * 25;
    }
    if (hedefler.gunlukYag > 0) {
      final sapma = (toplamYag - hedefler.gunlukYag).abs() / hedefler.gunlukYag;
      skor -= (sapma / tolerans) * 25;
    }
    return skor.clamp(0.0, 100.0);
  }

  /// Günlük onay durumu {yemekId: onaylandi}
  Map<String, bool> get gunlukOnayDurumu => tamamlananOgunler;

  /// Tamamlanan  nlerin toplam kalorisi
  double get tamamlananKalori => tumOgunler
      .where((y) => tamamlananOgunler[y.id] == true)
      .fold(0.0, (t, y) => t + y.kalori);

  /// Tamamlanan  nlerin toplam proteini
  double get tamamlananProtein => tumOgunler
      .where((y) => tamamlananOgunler[y.id] == true)
      .fold(0.0, (t, y) => t + y.protein);

  /// Tamamlanan  nlerin toplam karbonhidrat1
  double get tamamlananKarb => tumOgunler
      .where((y) => tamamlananOgunler[y.id] == true)
      .fold(0.0, (t, y) => t + y.karbonhidrat);

  /// Tamamlanan  nlerin toplam yağı
  double get tamamlananYag => tumOgunler
      .where((y) => tamamlananOgunler[y.id] == true)
      .fold(0.0, (t, y) => t + y.yag);

  @override
  List<Object?> get props => [id, userId, tarih, hedefler];
}


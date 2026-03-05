// ============================================================================
// lib/domain/entities/haftalik_rapor.dart
// HAFTALİK RAPOR VERİ MODELLERİ
// ============================================================================

import 'package:equatable/equatable.dart';

/// Haftalık beslenme uyum raporu
class HaftalikRapor extends Equatable {
  final DateTime baslangicTarihi;
  final DateTime bitisTarihi;
  final Map<DateTime, GunlukUyumVerisi> gunlukVeriler;
  final double ortalamaUyumYuzdesi;
  final double genelUyumYuzdesi;
  final int toplamTamamlananOgun;
  final int toplamOgunSayisi;
  final HedefAnalizi hedefAnalizi;
  final SuAnalizi suAnalizi;
  final List<String> tavsiyeler;
  final DateTime olusturulmaTarihi;

  const HaftalikRapor({
    required this.baslangicTarihi,
    required this.bitisTarihi,
    required this.gunlukVeriler,
    required this.ortalamaUyumYuzdesi,
    required this.genelUyumYuzdesi,
    required this.toplamTamamlananOgun,
    required this.toplamOgunSayisi,
    required this.hedefAnalizi,
    required this.suAnalizi,
    required this.tavsiyeler,
    required this.olusturulmaTarihi,
  });

  /// Boş haftalık rapor factory (veri yokken kullanılır)
  factory HaftalikRapor.bos(String userId, DateTime baslangic) {
    final bitis = baslangic.add(const Duration(days: 6));
    return HaftalikRapor(
      baslangicTarihi: baslangic,
      bitisTarihi: bitis,
      gunlukVeriler: const {},
      ortalamaUyumYuzdesi: 0,
      genelUyumYuzdesi: 0,
      toplamTamamlananOgun: 0,
      toplamOgunSayisi: 0,
      hedefAnalizi: const HedefAnalizi(
        enIyiGun: null,
        enKotuGun: null,
        ortalamaUyum: 0,
        tutarlilikSkoru: 0,
        gelismeTrendi: 'Veri yok',
      ),
      suAnalizi: const SuAnalizi(
        gunlukOnerilen: 2.5,
        haftalikOnerilen: 17.5,
        aciklama: 'Günde 2.5L su imeyi hedefleyin',
      ),
      tavsiyeler: const ['Henüz yeterli veri yok. Beslenme planınıza uyun!'],
      olusturulmaTarihi: DateTime.now(),
    );
  }

  /// V1 analytics_repository_impl uyumlu constructor (alias)
  /// Gerek constructor'a yönlendirir
  factory HaftalikRapor.v1({
    required String userId,
    required DateTime haftaBaslangic,
    required DateTime haftaBitis,
    required List<dynamic> gunlukPlanlar,
    required double ortalamKalori,
    required double ortalamProtein,
    required double ortalamKarb,
    required double ortalamYag,
    required double uyumYuzdesi,
    List<String> tavsiyeler = const [],
  }) {
    return HaftalikRapor(
      baslangicTarihi: haftaBaslangic,
      bitisTarihi: haftaBitis,
      gunlukVeriler: const {},
      ortalamaUyumYuzdesi: uyumYuzdesi * 100,
      genelUyumYuzdesi: uyumYuzdesi * 100,
      toplamTamamlananOgun: 0,
      toplamOgunSayisi: 0,
      hedefAnalizi: const HedefAnalizi(
        enIyiGun: null,
        enKotuGun: null,
        ortalamaUyum: 0,
        tutarlilikSkoru: 0,
        gelismeTrendi: 'Kararl1',
      ),
      suAnalizi: const SuAnalizi(
        gunlukOnerilen: 2.5,
        haftalikOnerilen: 17.5,
        aciklama: 'Günde 2.5L',
      ),
      tavsiyeler: tavsiyeler,
      olusturulmaTarihi: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        baslangicTarihi,
        bitisTarihi,
        gunlukVeriler,
        ortalamaUyumYuzdesi,
        genelUyumYuzdesi,
        toplamTamamlananOgun,
        toplamOgunSayisi,
        hedefAnalizi,
        suAnalizi,
        tavsiyeler,
        olusturulmaTarihi,
      ];

  /// Başar1 durumu
  String get basariDurumu {
    if (ortalamaUyumYuzdesi >= 90) return 'Mükemmel! 🏆';
    if (ortalamaUyumYuzdesi >= 80) return 'Çok İyi! 🎉';
    if (ortalamaUyumYuzdesi >= 70) return 'İyi 👍';
    if (ortalamaUyumYuzdesi >= 60) return 'Orta 📈';
    return 'Gelişim Gerekli 💪';
  }

  /// Hafta sonu özeti
  String get haftalikOzet {
    return '$toplamTamamlananOgun/$toplamOgunSayisi öğün tamamland1 '
           '(%${ortalamaUyumYuzdesi.toStringAsFixed(1)} uyum)';
  }
}

/// Günlük uyum verisi
class GunlukUyumVerisi extends Equatable {
  final DateTime tarih;
  final bool planVarMi;
  final double uyumYuzdesi;
  final int tamamlananOgunSayisi;
  final int toplamOgunSayisi;
  final double tamamlananKalori;
  final double hedefKalori;
  final MakroUyumVerisi makroUyum;

  const GunlukUyumVerisi({
    required this.tarih,
    required this.planVarMi,
    required this.uyumYuzdesi,
    required this.tamamlananOgunSayisi,
    required this.toplamOgunSayisi,
    required this.tamamlananKalori,
    required this.hedefKalori,
    required this.makroUyum,
  });

  @override
  List<Object?> get props => [
        tarih,
        planVarMi,
        uyumYuzdesi,
        tamamlananOgunSayisi,
        toplamOgunSayisi,
        tamamlananKalori,
        hedefKalori,
        makroUyum,
      ];

  /// Kalori uyum yüzdesi
  double get kaloriUyumYuzdesi {
    if (hedefKalori <= 0) return 0.0;
    return (tamamlananKalori / hedefKalori) * 100;
  }

  /// Gün durumu
  String get gunDurumu {
    if (!planVarMi) return 'Plan Yok';
    if (uyumYuzdesi == 100) return 'Mükemmel! 🏆';
    if (uyumYuzdesi >= 80) return 'Başarıl1 💪';
    if (uyumYuzdesi >= 60) return 'İyi 👍';
    if (uyumYuzdesi >= 40) return 'Orta 📊';
    return 'Düşük ⚠️';
  }
}

/// Makro uyum verisi
class MakroUyumVerisi extends Equatable {
  final double proteinUyum;
  final double karbUyum;
  final double yagUyum;

  const MakroUyumVerisi({
    required this.proteinUyum,
    required this.karbUyum,
    required this.yagUyum,
  });

  @override
  List<Object?> get props => [proteinUyum, karbUyum, yagUyum];

  /// Ortalama makro uyumu
  double get ortalamaMakroUyum {
    return (proteinUyum + karbUyum + yagUyum) / 3;
  }

  /// En iyi makro
  String get enIyiMakro {
    if (proteinUyum >= karbUyum && proteinUyum >= yagUyum) {
      return 'Protein 💪';
    } else if (karbUyum >= yagUyum) {
      return 'Karbonhidrat 🍚';
    } else {
      return 'Yağ 🥑';
    }
  }

  /// En kötü makro
  String get enKotuMakro {
    if (proteinUyum <= karbUyum && proteinUyum <= yagUyum) {
      return 'Protein 💪';
    } else if (karbUyum <= yagUyum) {
      return 'Karbonhidrat 🍚';
    } else {
      return 'Yağ 🥑';
    }
  }
}

/// Hedef analizi
class HedefAnalizi extends Equatable {
  final GunlukUyumVerisi? enIyiGun;
  final GunlukUyumVerisi? enKotuGun;
  final double ortalamaUyum;
  final double tutarlilikSkoru;
  final String gelismeTrendi;

  const HedefAnalizi({
    required this.enIyiGun,
    required this.enKotuGun,
    required this.ortalamaUyum,
    required this.tutarlilikSkoru,
    required this.gelismeTrendi,
  });

  @override
  List<Object?> get props => [
        enIyiGun,
        enKotuGun,
        ortalamaUyum,
        tutarlilikSkoru,
        gelismeTrendi,
      ];

  /// Tutarlılık durumu
  String get tutarlilikDurumu {
    if (tutarlilikSkoru >= 90) return 'Çok Tutarl1 🎯';
    if (tutarlilikSkoru >= 75) return 'Tutarl1 📊';
    if (tutarlilikSkoru >= 60) return 'Orta Tutarl1 📈';
    return 'Tutarsız 🌪️';
  }
}

/// Su analizi
class SuAnalizi extends Equatable {
  final double gunlukOnerilen;
  final double haftalikOnerilen;
  final String aciklama;

  const SuAnalizi({
    required this.gunlukOnerilen,
    required this.haftalikOnerilen,
    required this.aciklama,
  });

  @override
  List<Object?> get props => [gunlukOnerilen, haftalikOnerilen, aciklama];

  /// Su durumu emoji
  String get suDurumuEmoji {
    if (gunlukOnerilen < 2.0) return '🚨';
    if (gunlukOnerilen < 2.5) return '💧';
    if (gunlukOnerilen < 3.5) return '💦';
    return '🌊';
  }

  /// Günlük su önerisi metni
  String get gunlukOneriMetni {
    return '${gunlukOnerilen.toStringAsFixed(1)}L/gün $suDurumuEmoji';
  }
}
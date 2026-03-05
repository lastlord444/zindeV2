// ============================================================================
// lib/domain/entities/alisveris_listesi.dart
// ALIŞVERİŞ LİSTESİ VERİ MODELLERİ
// ============================================================================

class AlisverisListesi {
  final DateTime baslangicTarihi;
  final DateTime bitisTarihi;
  final Map<String, MalzemeDetayi> malzemeler;
  final Map<String, List<MalzemeDetayi>> kategoriler;
  final Map<String, List<MalzemeDetayi>> marketBolumleri;
  final double toplamMaliyetTahmini;
  final int toplamMalzemeSayisi;
  final int planliGunSayisi;
  final int toplamYemekSayisi;
  final List<String> oneriler;
  final DateTime olusturulmaTarihi;

  const AlisverisListesi({
    required this.baslangicTarihi,
    required this.bitisTarihi,
    required this.malzemeler,
    required this.kategoriler,
    required this.marketBolumleri,
    required this.toplamMaliyetTahmini,
    required this.toplamMalzemeSayisi,
    required this.planliGunSayisi,
    required this.toplamYemekSayisi,
    required this.oneriler,
    required this.olusturulmaTarihi,
  });

  /// GunlukPlan listesinden alışveriş listesi oluştur
  factory AlisverisListesi.planlardan(
      String userId, DateTime haftaBasi, List<dynamic> planlar) {
    final bitis = haftaBasi.add(const Duration(days: 6));
    return AlisverisListesi(
      baslangicTarihi: haftaBasi,
      bitisTarihi: bitis,
      malzemeler: const {},
      kategoriler: const {},
      marketBolumleri: const {},
      toplamMaliyetTahmini: 0,
      toplamMalzemeSayisi: 0,
      planliGunSayisi: planlar.length,
      toplamYemekSayisi: planlar.length * 3, // ortalama 3 öğün
      oneriler: const ['Taze ürünleri haftada 2 kez alın'],
      olusturulmaTarihi: DateTime.now(),
    );
  }

  /// Hafta süresi (gün)
  int get haftaSuresi => bitisTarihi.difference(baslangicTarihi).inDays + 1;

  /// Günlük ortalama maliyet
  double get gunlukOrtalamaMaliyet => toplamMaliyetTahmini / haftaSuresi;

  /// Yemek başına ortalama maliyet
  double get yemekBasinaOrtalamaMaliyet =>
      toplamYemekSayisi > 0 ? toplamMaliyetTahmini / toplamYemekSayisi : 0.0;

  /// En pahal1 kategori
  String get enPahaliKategori {
    double maxMaliyet = 0.0;
    String maxKategori = 'Bilinmiyor';

    for (final entry in kategoriler.entries) {
      final kategoriMaliyeti = entry.value
          .fold<double>(0.0, (sum, malzeme) => sum + malzeme.toplamMaliyet);

      if (kategoriMaliyeti > maxMaliyet) {
        maxMaliyet = kategoriMaliyeti;
        maxKategori = entry.key;
      }
    }

    return maxKategori;
  }

  /// Maliyet kategorisi
  String get maliyetKategorisi {
    if (toplamMaliyetTahmini < 200) return 'Ekonomik';
    if (toplamMaliyetTahmini < 400) return 'Orta';
    if (toplamMaliyetTahmini < 600) return 'Yüksek';
    return 'Çok Yüksek';
  }

  /// Market bölümü sayıs1
  int get marketBolumSayisi => marketBolumleri.length;

  @override
  String toString() {
    return 'AlisverisListesi($toplamMalzemeSayisi malzeme, ${toplamMaliyetTahmini.toStringAsFixed(0)}₺, $haftaSuresi gün)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlisverisListesi &&
          runtimeType == other.runtimeType &&
          baslangicTarihi == other.baslangicTarihi &&
          bitisTarihi == other.bitisTarihi;

  @override
  int get hashCode => baslangicTarihi.hashCode ^ bitisTarihi.hashCode;
}

class MalzemeDetayi {
  final String ad;
  final int miktar;
  final String birim;
  final String kategori;
  final int oncelik;
  final double tahminiMaliyet;
  final bool alindiMi;

  const MalzemeDetayi({
    required this.ad,
    required this.miktar,
    required this.birim,
    required this.kategori,
    required this.oncelik,
    required this.tahminiMaliyet,
    this.alindiMi = false,
  });

  /// Toplam maliyet (miktar x birim maliyet)
  double get toplamMaliyet {
    if (birim == 'gram' && miktar > 1) {
      return tahminiMaliyet * (miktar * 0.1); // 100g porsiyon varsayım1
    } else if (birim == 'ml' && miktar > 1) {
      return tahminiMaliyet * (miktar * 0.25); // 250ml porsiyon
    } else {
      return tahminiMaliyet * miktar;
    }
  }

  /// Öncelik metni
  String get oncelikMetni {
    switch (oncelik) {
      case 5:
        return 'Çok Önemli';
      case 4:
        return 'Önemli';
      case 3:
        return 'Orta';
      case 2:
        return 'Düşük';
      case 1:
        return 'İsteğe Bağl1';
      default:
        return 'Bilinmiyor';
    }
  }

  /// Öncelik renk kodu
  String get oncelikRengiKodu {
    switch (oncelik) {
      case 5:
        return '#FF5252'; // Kırmız1 - ok önemli
      case 4:
        return '#FF9800'; // Turuncu - önemli
      case 3:
        return '#FFC107'; // Sar1 - orta
      case 2:
        return '#4CAF50'; // Yeşil - düşük
      case 1:
        return '#9E9E9E'; // Gri - isteğe bağl1
      default:
        return '#9E9E9E';
    }
  }

  /// Miktar ve birim metni
  String get miktarBirimMetni {
    if (miktar == 1) {
      return birim == 'adet' ? '1 $birim' : '1 porsiyon';
    } else {
      return '$miktar $birim';
    }
  }

  MalzemeDetayi copyWith({
    String? ad,
    int? miktar,
    String? birim,
    String? kategori,
    int? oncelik,
    double? tahminiMaliyet,
    bool? alindiMi,
  }) {
    return MalzemeDetayi(
      ad: ad ?? this.ad,
      miktar: miktar ?? this.miktar,
      birim: birim ?? this.birim,
      kategori: kategori ?? this.kategori,
      oncelik: oncelik ?? this.oncelik,
      tahminiMaliyet: tahminiMaliyet ?? this.tahminiMaliyet,
      alindiMi: alindiMi ?? this.alindiMi,
    );
  }

  @override
  String toString() {
    return '$ad ($miktarBirimMetni, ${toplamMaliyet.toStringAsFixed(1)}₺)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MalzemeDetayi &&
          runtimeType == other.runtimeType &&
          ad == other.ad &&
          miktar == other.miktar &&
          birim == other.birim;

  @override
  int get hashCode => ad.hashCode ^ miktar.hashCode ^ birim.hashCode;
}

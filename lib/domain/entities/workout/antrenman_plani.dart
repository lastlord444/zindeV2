// ============================================================================
// lib/domain/entities/antrenman_plani.dart
// ANTRENMAN PLANI VERİ MODELLERİ
// ============================================================================

class AntrenmanPlani {
  final String planAdi;
  final String aciklama;
  final List<GunlukAntrenman> gunlukAntrenmanlar;
  final String haftalikStrateji;
  final String beslenmeEntegrasyonu;
  final String motivasyonMesaji;
  final DateTime olusturulmaTarihi;
  final int planSuresi;
  final String zorlukSeviyesi;

  const AntrenmanPlani({
    required this.planAdi,
    required this.aciklama,
    required this.gunlukAntrenmanlar,
    required this.haftalikStrateji,
    required this.beslenmeEntegrasyonu,
    required this.motivasyonMesaji,
    required this.olusturulmaTarihi,
    required this.planSuresi,
    required this.zorlukSeviyesi,
  });

  /// JSON'dan object oluştur
  factory AntrenmanPlani.fromJson(Map<String, dynamic> json) {
    final gunlukListe = <GunlukAntrenman>[];

    if (json['gunlukAntrenmanlar'] != null) {
      for (final gun in json['gunlukAntrenmanlar']) {
        gunlukListe.add(GunlukAntrenman.fromJson(gun));
      }
    }

    return AntrenmanPlani(
      planAdi: json['planAdi'] ?? 'Elite Antrenman Plan1',
      aciklama: json['aciklama'] ?? 'Profesyonel antrenman plan1',
      gunlukAntrenmanlar: gunlukListe,
      haftalikStrateji:
          json['haftalikStrateji'] ?? 'Progressive overload sistemi',
      beslenmeEntegrasyonu:
          json['beslenmeEntegrasyonu'] ?? 'Makro timing koordinasyonu',
      motivasyonMesaji: json['motivasyonMesaji'] ?? 'Başarıya odaklan! 💪',
      olusturulmaTarihi: DateTime.now(),
      planSuresi: json['planSuresi'] ?? 7,
      zorlukSeviyesi: json['zorlukSeviyesi'] ?? 'Orta',
    );
  }

  /// Toplam antrenman günü
  int get toplamGunSayisi => gunlukAntrenmanlar.length;

  /// Haftalık toplam antrenman süresi (dakika)
  int get haftalikToplamSure {
    int toplam = 0;
    for (final gun in gunlukAntrenmanlar) {
      toplam += gun.sureDakika;
    }
    return toplam;
  }

  /// Ortalama günlük antrenman süresi
  double get ortalamaSure =>
      toplamGunSayisi > 0 ? haftalikToplamSure / toplamGunSayisi : 0.0;

  /// Zorluk seviye skoru (1-5)
  int get zorlukSkoru {
    switch (zorlukSeviyesi.toLowerCase()) {
      case 'başlang1':
        return 1;
      case 'orta':
        return 2;
      case 'ileri':
        return 3;
      case 'profesyonel':
        return 4;
      case 'elite':
        return 5;
      default:
        return 2;
    }
  }

  /// Plan kategorisi
  String get planKategorisi {
    if (planAdi.toLowerCase().contains('hiit')) return 'Kardiyovasküler';
    if (planAdi.toLowerCase().contains('strength')) return 'Kuvvet';
    if (planAdi.toLowerCase().contains('kas')) return 'Kas Geliştirme';
    if (planAdi.toLowerCase().contains('kilo')) return 'Kilo Yönetimi';
    return 'Genel Fitness';
  }

  // ─── V1 UI Uyumluluk Getter'lar1 ──────────────────────────────────────
  /// V1 UI 'ad' getter'1 (planAdi alias)
  String get ad => planAdi;

  /// V1 UI 'ozet' getter'1 (aciklama alias)
  String get ozet => aciklama;

  /// V1 UI 'zorluk' getter'1 (zorlukSeviyesi alias)
  String get zorluk => zorlukSeviyesi;

  /// V1 UI 'toplamSureDakika' getter'1
  int get toplamSureDakika => haftalikToplamSure;

  /// V1 UI 'egzersizler' - tüm hareket listesi tek listede
  List<Hareket> get egzersizler => gunlukAntrenmanlar
      .expand((gun) => gun.hareketler)
      .toList();

  /// V1 UI 'egzersizSayisi' getter'1
  int get egzersizSayisi => egzersizler.length;

  /// V1 UI 'toplamKalori' tahmini
  int get toplamKalori {
    return gunlukAntrenmanlar.fold(0, (t, gun) => t + gun.tahminiKaloriYakimi);
  }

  /// V1 UI 'kasGruplariOzet' getter'1
  String get kasGruplariOzet {
    final odaklar = gunlukAntrenmanlar.map((g) => g.odak).toSet();
    if (odaklar.isEmpty) return 'Full Body';
    return odaklar.take(3).join(', ');
  }

  @override
  String toString() {
    return 'AntrenmanPlani($planAdi, $toplamGunSayisi gün, $zorlukSeviyesi)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AntrenmanPlani &&
          runtimeType == other.runtimeType &&
          planAdi == other.planAdi &&
          olusturulmaTarihi == other.olusturulmaTarihi;

  @override
  int get hashCode => planAdi.hashCode ^ olusturulmaTarihi.hashCode;
}

class GunlukAntrenman {
  final String gun;
  final String odak;
  final String sure;
  final List<Hareket> hareketler;
  final String ozelNotlar;

  const GunlukAntrenman({
    required this.gun,
    required this.odak,
    required this.sure,
    required this.hareketler,
    required this.ozelNotlar,
  });

  /// JSON'dan object oluştur
  factory GunlukAntrenman.fromJson(Map<String, dynamic> json) {
    final hareketListesi = <Hareket>[];

    if (json['hareketler'] != null) {
      for (final hareket in json['hareketler']) {
        hareketListesi.add(Hareket.fromJson(hareket));
      }
    }

    return GunlukAntrenman(
      gun: json['gun'] ?? 'Bilinmiyor',
      odak: json['odak'] ?? 'Genel Antrenman',
      sure: json['sure'] ?? '60 dk',
      hareketler: hareketListesi,
      ozelNotlar: json['ozel_notlar'] ?? json['ozelNotlar'] ?? '',
    );
  }

  /// Süreyi dakika olarak döndür
  int get sureDakika {
    final sureStr = sure.toLowerCase();
    if (sureStr.contains('dk')) {
      final number = RegExp(r'\d+').firstMatch(sureStr)?.group(0);
      return int.tryParse(number ?? '60') ?? 60;
    }
    return 60;
  }

  /// Toplam hareket sayıs1
  int get toplamHareketSayisi => hareketler.length;

  /// Tahminî kalori yakım1
  int get tahminiKaloriYakimi {
    int temelKalori = sureDakika * 5; // Dakika başı 5 kalori varsayım1

    // Odağa göre arpan
    if (odak.toLowerCase().contains('hiit') ||
        odak.toLowerCase().contains('cardio')) {
      temelKalori = (temelKalori * 1.5).round();
    } else if (odak.toLowerCase().contains('strength') ||
        odak.toLowerCase().contains('power')) {
      temelKalori = (temelKalori * 1.2).round();
    }

    return temelKalori;
  }

  @override
  String toString() {
    return '$gun: $odak ($sure, $toplamHareketSayisi hareket)';
  }
}

class Hareket {
  final String hareket;
  final int set;
  final String tekrar;
  final String dinlenme;
  final String ipucu;

  const Hareket({
    required this.hareket,
    required this.set,
    required this.tekrar,
    required this.dinlenme,
    required this.ipucu,
  });

  /// JSON'dan object oluştur
  factory Hareket.fromJson(Map<String, dynamic> json) {
    return Hareket(
      hareket: json['hareket'] ?? 'Bilinmiyor',
      set: json['set'] ?? 3,
      tekrar: json['tekrar'] ?? '10',
      dinlenme: json['dinlenme'] ?? '60s',
      ipucu: json['ipucu'] ?? '',
    );
  }

  /// Toplam volume hesapla (set x tekrar sayıs1)
  int get toplamVolume {
    // Tekrar string'inden say1 ıkar
    final tekrarSayisi = RegExp(r'\d+').firstMatch(tekrar)?.group(0);
    final tekrarInt = int.tryParse(tekrarSayisi ?? '10') ?? 10;

    return set * tekrarInt;
  }

  /// Dinlenme süresini saniye olarak döndür
  int get dinlenmeSaniye {
    final dinlenmeStr = dinlenme.toLowerCase();
    if (dinlenmeStr.contains('dk')) {
      final dakika = RegExp(r'\d+').firstMatch(dinlenmeStr)?.group(0);
      return (int.tryParse(dakika ?? '1') ?? 1) * 60;
    } else {
      final saniye = RegExp(r'\d+').firstMatch(dinlenmeStr)?.group(0);
      return int.tryParse(saniye ?? '60') ?? 60;
    }
  }

  /// Hareket kategorisi
  String get kategori {
    final hareketAdi = hareket.toLowerCase();

    if (hareketAdi.contains('squat') ||
        hareketAdi.contains('lunge') ||
        hareketAdi.contains('leg')) {
      return 'Alt Vücut';
    } else if (hareketAdi.contains('press') ||
        hareketAdi.contains('push') ||
        hareketAdi.contains('bench')) {
      return 'İtme Hareketi';
    } else if (hareketAdi.contains('pull') ||
        hareketAdi.contains('row') ||
        hareketAdi.contains('chin')) {
      return 'Çekme Hareketi';
    } else if (hareketAdi.contains('core') ||
        hareketAdi.contains('plank') ||
        hareketAdi.contains('abs')) {
      return 'Core';
    } else if (hareketAdi.contains('cardio') ||
        hareketAdi.contains('burpee') ||
        hareketAdi.contains('jump')) {
      return 'Kardiyovasküler';
    } else {
      return 'Compound';
    }
  }

  /// Zorluk seviyesi (1-5)
  int get zorlukSeviyesi {
    if (set >= 5 && toplamVolume > 50) return 5;
    if (set >= 4 && toplamVolume > 40) return 4;
    if (set >= 3 && toplamVolume > 30) return 3;
    if (set >= 2 && toplamVolume > 20) return 2;
    return 1;
  }

  @override
  String toString() {
    return '$hareket: ${set}x$tekrar ($dinlenme dinlenme)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hareket &&
          runtimeType == other.runtimeType &&
          hareket == other.hareket &&
          set == other.set &&
          tekrar == other.tekrar;

  @override
  int get hashCode => hareket.hashCode ^ set.hashCode ^ tekrar.hashCode;
}

// ============================================================================
// lib/domain/entities/kullanici_profili.dart
// Kullanıc1 Profili Entity
// ============================================================================

import 'package:equatable/equatable.dart';
import 'hedef.dart'; // Enum'lar1 buradan import et

class KullaniciProfili extends Equatable {
  final String id;
  final String ad;
  final String soyad;
  final int yas;
  final double boy; // cm
  final double mevcutKilo; // kg
  final double? hedefKilo; // kg
  final Cinsiyet cinsiyet;
  final AktiviteSeviyesi aktiviteSeviyesi;
  final Hedef hedef;
  final DiyetTipi diyetTipi;
  final List<String> manuelAlerjiler;
  final DateTime kayitTarihi;

  const KullaniciProfili({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.yas,
    required this.boy,
    required this.mevcutKilo,
    this.hedefKilo,
    required this.cinsiyet,
    required this.aktiviteSeviyesi,
    required this.hedef,
    required this.diyetTipi,
    this.manuelAlerjiler = const [],
    required this.kayitTarihi,
  });

  @override
  List<Object?> get props => [
        id,
        ad,
        soyad,
        yas,
        boy,
        mevcutKilo,
        hedefKilo,
        cinsiyet,
        aktiviteSeviyesi,
        hedef,
        diyetTipi,
        manuelAlerjiler,
        kayitTarihi,
      ];

  // Tüm kısıtlamalar1 birleştir (Diyet tipi + Manuel alerjiler)
  List<String> get tumKisitlamalar {
    final Set<String> kisitlamalar = {};

    // Diyet tipinden gelen varsayılan kısıtlamalar
    kisitlamalar.addAll(diyetTipi.varsayilanKisitlamalar);

    // Manuel eklenen alerjiler
    kisitlamalar.addAll(manuelAlerjiler);

    return kisitlamalar.toList();
  }

  // Bir yemeğin yenebilir olup olmadığın1 kontrol et
  bool yemekYenebilirMi(List<String> yemekIcerikleri) {
    final kisitlamalarKucuk =
        tumKisitlamalar.map((k) => k.toLowerCase()).toSet();

    for (final icerik in yemekIcerikleri) {
      if (kisitlamalarKucuk.contains(icerik.toLowerCase())) {
        return false; // Kısıtlama var, yenebilir değil
      }
    }
    return true; // Hibir kısıtlama yok
  }

  KullaniciProfili copyWith({
    String? id,
    String? ad,
    String? soyad,
    int? yas,
    double? boy,
    double? mevcutKilo,
    double? hedefKilo,
    Cinsiyet? cinsiyet,
    AktiviteSeviyesi? aktiviteSeviyesi,
    Hedef? hedef,
    DiyetTipi? diyetTipi,
    List<String>? manuelAlerjiler,
    DateTime? kayitTarihi,
  }) {
    return KullaniciProfili(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      soyad: soyad ?? this.soyad,
      yas: yas ?? this.yas,
      boy: boy ?? this.boy,
      mevcutKilo: mevcutKilo ?? this.mevcutKilo,
      hedefKilo: hedefKilo ?? this.hedefKilo,
      cinsiyet: cinsiyet ?? this.cinsiyet,
      aktiviteSeviyesi: aktiviteSeviyesi ?? this.aktiviteSeviyesi,
      hedef: hedef ?? this.hedef,
      diyetTipi: diyetTipi ?? this.diyetTipi,
      manuelAlerjiler: manuelAlerjiler ?? this.manuelAlerjiler,
      kayitTarihi: kayitTarihi ?? this.kayitTarihi,
    );
  }

  // 🔥 JSON Serialization Support
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad': ad,
      'soyad': soyad,
      'yas': yas,
      'boy': boy,
      'mevcutKilo': mevcutKilo,
      'hedefKilo': hedefKilo,
      'cinsiyet': cinsiyet.name,
      'aktiviteSeviyesi': aktiviteSeviyesi.name,
      'hedef': hedef.name,
      'diyetTipi': diyetTipi.name,
      'manuelAlerjiler': manuelAlerjiler,
      'kayitTarihi': kayitTarihi.toIso8601String(),
    };
  }

  factory KullaniciProfili.fromJson(Map<String, dynamic> json) {
    return KullaniciProfili(
      id: json['id'] as String,
      ad: json['ad'] as String,
      soyad: json['soyad'] as String,
      yas: json['yas'] as int,
      boy: (json['boy'] as num).toDouble(),
      mevcutKilo: (json['mevcutKilo'] as num).toDouble(),
      hedefKilo: json['hedefKilo'] != null
          ? (json['hedefKilo'] as num).toDouble()
          : null,
      cinsiyet: Cinsiyet.values.firstWhere((e) => e.name == json['cinsiyet']),
      aktiviteSeviyesi: AktiviteSeviyesi.values.firstWhere((e) => e.name == json['aktiviteSeviyesi']),
      hedef: Hedef.values.firstWhere((e) => e.name == json['hedef']),
      diyetTipi: DiyetTipi.values.firstWhere((e) => e.name == json['diyetTipi']),
      manuelAlerjiler: (json['manuelAlerjiler'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      kayitTarihi: DateTime.parse(json['kayitTarihi'] as String),
    );
  }
}

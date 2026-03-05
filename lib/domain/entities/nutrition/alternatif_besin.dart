// lib/domain/entities/alternatif_besin.dart

import 'package:equatable/equatable.dart';

/// Bir besin iin alternatif öneri
class BesinAlternatifi extends Equatable {
  final String besin;
  final double miktar;
  final double benzerlikSkoru; // 0-1 aras1

  const BesinAlternatifi({
    required this.besin,
    required this.miktar,
    required this.benzerlikSkoru,
  });

  @override
  List<Object?> get props => [besin, miktar, benzerlikSkoru];

  /// JSON'dan oluştur (null-safe)
  factory BesinAlternatifi.fromJson(Map<String, dynamic> json) {
    return BesinAlternatifi(
      besin: json['besin']?.toString() ?? 'Bilinmeyen Besin',
      miktar: _parseDouble(json['miktar']) ?? 0.0,
      benzerlikSkoru: _parseDouble(json['benzerlikSkoru']) ?? 0.0,
    );
  }

  /// Double değer parse helper metodu
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// JSON'a evir
  Map<String, dynamic> toJson() {
    return {
      'besin': besin,
      'miktar': miktar,
      'benzerlikSkoru': benzerlikSkoru,
    };
  }
}

/// Bir malzeme iin alternatif besin önerileri
class AlternatifBesin extends Equatable {
  final String orijinalBesin;
  final double orijinalMiktar;
  final String birim;
  final List<BesinAlternatifi> alternatifler;

  const AlternatifBesin({
    required this.orijinalBesin,
    required this.orijinalMiktar,
    required this.birim,
    required this.alternatifler,
  });

  /// En iyi alternatifi getir
  BesinAlternatifi get enIyiAlternatif {
    if (alternatifler.isEmpty) {
      throw Exception('Alternatif bulunamad1');
    }
    return alternatifler
        .reduce((a, b) => a.benzerlikSkoru > b.benzerlikSkoru ? a : b);
  }

  /// Belirli benzerlik skorunun üzerindeki alternatifleri getir
  List<BesinAlternatifi> yuksekSkorluAlternatifler(double minSkor) {
    return alternatifler.where((a) => a.benzerlikSkoru >= minSkor).toList()
      ..sort((a, b) => b.benzerlikSkoru.compareTo(a.benzerlikSkoru));
  }

  // ─── V1 UI Uyumluluk Getter'lar1 ──────────────────────────────────────
  /// V1 UI 'ad' getter'1 (orijinalBesin alias)
  String get ad => orijinalBesin;

  /// V1 UI 'miktar' getter'1 (orijinalMiktar alias)
  double get miktar => orijinalMiktar;

  /// V1 UI 'neden' getter'1 - en iyi alternatifin aıklamas1
  String get neden => alternatifler.isNotEmpty
      ? '${alternatifler.first.besin} ile değiştirilebilir (benzerlik: ${(alternatifler.first.benzerlikSkoru * 100).toStringAsFixed(0)}%)'
      : 'Alternatif önerisi mevcut değil';

  /// V1 UI kalori getter'1 (stub - gerekte yemek DB'den gelir)
  double get kalori => 0.0;

  /// V1 UI protein getter'1 (stub)
  double get protein => 0.0;

  /// V1 UI karbonhidrat getter'1 (stub)
  double get karbonhidrat => 0.0;

  /// V1 UI yag getter'1 (stub)
  double get yag => 0.0;

  @override
  List<Object?> get props =>
      [orijinalBesin, orijinalMiktar, birim, alternatifler];

  /// JSON'dan oluştur (null-safe)
  factory AlternatifBesin.fromJson(Map<String, dynamic> json) {
    return AlternatifBesin(
      orijinalBesin: json['orijinalBesin']?.toString() ?? 'Bilinmeyen Besin',
      orijinalMiktar: _parseDouble(json['orijinalMiktar']) ?? 0.0,
      birim: json['birim']?.toString() ?? 'adet',
      alternatifler: _parseAlternatifler(json['alternatifler']) ?? [],
    );
  }

  /// Double değer parse helper metodu
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Alternatifler listesi parse helper metodu
  static List<BesinAlternatifi>? _parseAlternatifler(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    try {
      return value
          .where((e) => e != null && e is Map<String, dynamic>)
          .map((e) => BesinAlternatifi.fromJson(e))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// JSON'a evir
  Map<String, dynamic> toJson() {
    return {
      'orijinalBesin': orijinalBesin,
      'orijinalMiktar': orijinalMiktar,
      'birim': birim,
      'alternatifler': alternatifler.map((a) => a.toJson()).toList(),
    };
  }

  /// Copy with
  AlternatifBesin copyWith({
    String? orijinalBesin,
    double? orijinalMiktar,
    String? birim,
    List<BesinAlternatifi>? alternatifler,
  }) {
    return AlternatifBesin(
      orijinalBesin: orijinalBesin ?? this.orijinalBesin,
      orijinalMiktar: orijinalMiktar ?? this.orijinalMiktar,
      birim: birim ?? this.birim,
      alternatifler: alternatifler ?? this.alternatifler,
    );
  }
}

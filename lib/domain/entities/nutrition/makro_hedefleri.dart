// lib/domain/entities/makro_hedefleri.dart

import 'package:equatable/equatable.dart';

/// Günlük makro besin hedefleri
class MakroHedefleri extends Equatable {
  final double gunlukKalori;
  final double gunlukProtein; // gram
  final double gunlukKarbonhidrat; // gram
  final double gunlukYag; // gram

  const MakroHedefleri({
    required this.gunlukKalori,
    required this.gunlukProtein,
    required this.gunlukKarbonhidrat,
    required this.gunlukYag,
  });

  /// Protein kalorisi (ıg protein = 4 kcal)
  double get proteinKalori => gunlukProtein * 4;

  /// Karbonhidrat kalorisi (ıg karb = 4 kcal)
  double get karbonhidratKalori => gunlukKarbonhidrat * 4;

  /// Yağ kalorisi (ıg yağ = 9 kcal)
  double get yagKalori => gunlukYag * 9;

  /// Protein yüzdesi
  double get proteinYuzdesi => (proteinKalori / gunlukKalori) * 100;

  /// Karbonhidrat yüzdesi
  double get karbonhidratYuzdesi => (karbonhidratKalori / gunlukKalori) * 100;

  /// Yağ yüzdesi
  double get yagYuzdesi => (yagKalori / gunlukKalori) * 100;

  /// Makro dağılım1 (P/K/Y yüzdeleri)
  String get makroDagilimi {
    return '${proteinYuzdesi.toStringAsFixed(0)}/${karbonhidratYuzdesi.toStringAsFixed(0)}/${yagYuzdesi.toStringAsFixed(0)}';
  }

  @override
  List<Object?> get props => [
        gunlukKalori,
        gunlukProtein,
        gunlukKarbonhidrat,
        gunlukYag,
      ];

  /// Copy with
  MakroHedefleri copyWith({
    double? gunlukKalori,
    double? gunlukProtein,
    double? gunlukKarbonhidrat,
    double? gunlukYag,
  }) {
    return MakroHedefleri(
      gunlukKalori: gunlukKalori ?? this.gunlukKalori,
      gunlukProtein: gunlukProtein ?? this.gunlukProtein,
      gunlukKarbonhidrat: gunlukKarbonhidrat ?? this.gunlukKarbonhidrat,
      gunlukYag: gunlukYag ?? this.gunlukYag,
    );
  }

  /// Varsayılan makro hedefleri (2000 kalori, dengeli dağılım)
  factory MakroHedefleri.varsayilan() {
    return const MakroHedefleri(
      gunlukKalori: 2000.0,
      gunlukProtein: 150.0,
      gunlukKarbonhidrat: 200.0,
      gunlukYag: 70.0,
    );
  }

  /// JSON'dan oluştur (null-safe)
  factory MakroHedefleri.fromJson(Map<String, dynamic> json) {
    return MakroHedefleri(
      gunlukKalori: _parseDouble(json['gunlukKalori']) ?? 2000.0,
      gunlukProtein: _parseDouble(json['gunlukProtein']) ?? 150.0,
      gunlukKarbonhidrat: _parseDouble(json['gunlukKarbonhidrat']) ?? 200.0,
      gunlukYag: _parseDouble(json['gunlukYag']) ?? 70.0,
    );
  }

  /// Null-safe double parser
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// JSON'a evir
  Map<String, dynamic> toJson() {
    return {
      'gunlukKalori': gunlukKalori,
      'gunlukProtein': gunlukProtein,
      'gunlukKarbonhidrat': gunlukKarbonhidrat,
      'gunlukYag': gunlukYag,
    };
  }

  /// String adına göre makro değerini döndürür.
  double makroDegeri(String makroAdi) {
    switch (makroAdi) {
      case 'kalori':
        return gunlukKalori;
      case 'protein':
        return gunlukProtein;
      case 'karb':
      case 'karbonhidrat':
        return gunlukKarbonhidrat;
      case 'yag':
        return gunlukYag;
      default:
        return 0.0;
    }
  }
}

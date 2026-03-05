// lib/data/repositories/meal_repository_impl.dart
// Yemek havuzu - yerel mega_batch dosyalarından yükler

import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/logger.dart';
import '../datasources/remote/supabase_meal_datasource.dart';
import '../../domain/entities/nutrition/yemek.dart';
import '../../domain/repositories/meal_repository.dart';

/// Yemek repository implementasyonu
/// Yemekler Supabase üzerinden ekilir ve önbelleklenir.
class MealRepositoryImpl implements MealRepository {
  final SupabaseMealDataSource remoteDataSource;
  
  // Önbelleklenmiş yemek listesi
  List<Yemek>? _yemekOnbellegi;

  MealRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Yemek>>> tumYemekleriGetir() async {
    try {
      if (_yemekOnbellegi != null && _yemekOnbellegi!.isNotEmpty) {
        return Right(_yemekOnbellegi!);
      }

      try {
        final List<Map<String, dynamic>> data = await remoteDataSource.tumYemekleriGetir();
        _yemekOnbellegi = data.map((json) => Yemek.fromJson(json)).toList();
        AppLogger.bilgi('✅ Supabase\'den Yüklendi: ${_yemekOnbellegi!.length} Yemek');
      } catch (e) {
        AppLogger.hata('Supabase Yemekleri Yüklenemedi', e);
        _yemekOnbellegi = []; // Fallback empty
        return Left(SunucuHatasi());
      }
      return Right(_yemekOnbellegi!);
    } catch (e) {
      return Left(BilinmeyenHata(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Yemek>>> ogunYemekleriGetir(String ogunTipi) async {
    final tumResult = await tumYemekleriGetir();
    return tumResult.fold(
      (f) => Left(f),
      (yemekler) => Right(
        yemekler.where((y) => y.ogun.name == ogunTipi).toList(),
      ),
    );
  }

  @override
  Future<Either<Failure, List<Yemek>>> uygunYemekleriGetir({
    required String ogunTipi,
    required List<String> kisitlamalar,
  }) async {
    final tumResult = await tumYemekleriGetir();
    return tumResult.fold(
      (f) => Left(f),
      (yemekler) => Right(
        yemekler
            .where((y) =>
                y.ogun.name == ogunTipi &&
                y.kisitlamayaUygunMu(kisitlamalar))
            .toList(),
      ),
    );
  }

  @override
  Future<Either<Failure, List<Yemek>>> favoriYemekleriGetir(String userId) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> favoriyeEkle(String userId, String yemekId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> favoridenCikar(String userId, String yemekId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Yemek>>> alternatifYemekleriGetir({
    required Yemek mevcutYemek,
    required List<String> kisitlamalar,
    int sayi = 5,
  }) async {
    final tumResult = await ogunYemekleriGetir(mevcutYemek.ogun.name);
    return tumResult.fold(
      (f) => Left(f),
      (yemekler) {
        var uygunlar = yemekler
            .where((y) =>
                y.id != mevcutYemek.id &&
                y.kisitlamayaUygunMu(kisitlamalar))
            .toList();

        // Her alternatif iin önce hedef kaloriye göre ölekleme yap
        final olcekliUygunlar = uygunlar.map((a) {
          if (a.kalori > 0 && mevcutYemek.kalori > 0) {
            double multiplier = mevcutYemek.kalori / a.kalori;
            multiplier = multiplier.clamp(a.minMultiplier, a.maxMultiplier);
            return a.scale(multiplier);
          }
          return a;
        }).toList();

        // Multi-makro sapma skoru hesapla (düşük = daha iyi eşleşme)
        double sapmaSkoru(Yemek y) {
          final kaloriSapma = mevcutYemek.kalori > 0 ? ((y.kalori - mevcutYemek.kalori).abs() / mevcutYemek.kalori) * 0.40 : 0.0;
          final proteinSapma = mevcutYemek.protein > 0 ? ((y.protein - mevcutYemek.protein).abs() / mevcutYemek.protein) * 0.30 : 0.0;
          final karbSapma = mevcutYemek.karbonhidrat > 0 ? ((y.karbonhidrat - mevcutYemek.karbonhidrat).abs() / mevcutYemek.karbonhidrat) * 0.20 : 0.0;
          final yagSapma = mevcutYemek.yag > 0 ? ((y.yag - mevcutYemek.yag).abs() / mevcutYemek.yag) * 0.10 : 0.0;
          return kaloriSapma + proteinSapma + karbSapma + yagSapma;
        }

        // Sapma skoruna göre sırala (en yakın makro değerlerine sahip olanlar ilk sırada)
        olcekliUygunlar.sort((a, b) => sapmaSkoru(a).compareTo(sapmaSkoru(b)));

        final alternatifler = olcekliUygunlar.take(sayi).toList();

        return Right(alternatifler);
      },
    );
  }

  /// Yemek havuzunu dışarıdan yükle (main.dart'ta çağrılır)
  void yemekleriYukle(List<Yemek> yemekler) {
    _yemekOnbellegi = yemekler;
    AppLogger.bilgi('✅ ${yemekler.length} yemek yüklendi');
  }
}

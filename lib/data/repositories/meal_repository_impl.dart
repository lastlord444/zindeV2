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
        // ─── 1. Mevcut yemeğin çekirdek besinlerini tespit et ───────────
        final mevcutCekirdek = _cekirdekBesinler(mevcutYemek);
        AppLogger.bilgi('🔍 Çekirdek besinler (${mevcutYemek.ad}): $mevcutCekirdek');

        // ─── 2. Aday filtreleme ─────────────────────────────────────────
        var uygunlar = yemekler.where((y) {
          // Aynı ID'yi ele
          if (y.id == mevcutYemek.id) return false;
          // Kısıtlama kontrolü
          if (!y.kisitlamayaUygunMu(kisitlamalar)) return false;
          // ⭐ KRİTİK: Çekirdek besin çakışma kontrolü
          // Adayın çekirdek besinleri, mevcut yemeğin çekirdek besinleriyle
          // kesişmemeli (barbunya→barbunya engeli)
          final adayCekirdek = _cekirdekBesinler(y);
          final kesisim = mevcutCekirdek.intersection(adayCekirdek);
          if (kesisim.isNotEmpty) return false;
          return true;
        }).toList();

        // Benzersizlik: Her protein kaynağından sadece 1 tane al
        final benzersizMap = <String, Yemek>{};
        for (final y in uygunlar) {
          final besinKey = _cekirdekBesinler(y).join('+');
          if (!benzersizMap.containsKey(besinKey)) {
            benzersizMap[besinKey] = y;
          }
        }
        final benzersizUygunlar = benzersizMap.values.toList();

        // ─── 3. Ölçekleme + Protein Limiti ──────────────────────────────
        final olcekliUygunlar = <Yemek>[];
        for (final a in benzersizUygunlar) {
          if (a.kalori <= 0 || mevcutYemek.kalori <= 0) continue;

          double multiplier = mevcutYemek.kalori / a.kalori;
          multiplier = multiplier.clamp(
            a.minMultiplier > 0 ? a.minMultiplier : 0.3,
            a.maxMultiplier > 0 ? a.maxMultiplier : 4.0,
          );

          // ⭐ Protein limiti: Ölçeklenmiş protein 50g'ı aşmasın
          final olcekliProtein = a.protein * multiplier;
          if (olcekliProtein > 50.0) {
            // Protein limitine göre multiplier'ı düşür
            final proteinCappedMultiplier = 50.0 / a.protein;
            multiplier = multiplier.clamp(
              a.minMultiplier > 0 ? a.minMultiplier : 0.3,
              proteinCappedMultiplier,
            );
            // Multiplier min'in altına düşerse bu yemeği atla
            final minMult = a.minMultiplier > 0 ? a.minMultiplier : 0.3;
            if (multiplier < minMult) continue;
          }

          try {
            olcekliUygunlar.add(a.scale(multiplier));
          } catch (_) {
            // scale min/max aralık dışında, atla
          }
        }

        // ─── 4. Makro sapma skoru (hedef öğün makrosuna göre) ───────────
        double sapmaSkoru(Yemek y) {
          final kaloriSapma = mevcutYemek.kalori > 0
              ? ((y.kalori - mevcutYemek.kalori).abs() / mevcutYemek.kalori) * 0.30
              : 0.0;
          final proteinSapma = mevcutYemek.protein > 0
              ? ((y.protein - mevcutYemek.protein).abs() / mevcutYemek.protein) * 0.35
              : 0.0;
          final karbSapma = mevcutYemek.karbonhidrat > 0
              ? ((y.karbonhidrat - mevcutYemek.karbonhidrat).abs() / mevcutYemek.karbonhidrat) * 0.20
              : 0.0;
          final yagSapma = mevcutYemek.yag > 0
              ? ((y.yag - mevcutYemek.yag).abs() / mevcutYemek.yag) * 0.15
              : 0.0;
          return kaloriSapma + proteinSapma + karbSapma + yagSapma;
        }

        // Skor sıralaması
        olcekliUygunlar.sort((a, b) => sapmaSkoru(a).compareTo(sapmaSkoru(b)));

        final alternatifler = olcekliUygunlar.take(sayi).toList();

        AppLogger.bilgi('✅ ${alternatifler.length} alternatif bulundu (${mevcutYemek.ad} için)');
        for (final alt in alternatifler) {
          AppLogger.bilgi('  → ${alt.ad} | P:${alt.protein.toStringAsFixed(0)}g K:${alt.karbonhidrat.toStringAsFixed(0)}g Y:${alt.yag.toStringAsFixed(0)}g');
        }

        return Right(alternatifler);
      },
    );
  }

  /// Yemek havuzunu dışarıdan yükle (main.dart'ta çağrılır)
  void yemekleriYukle(List<Yemek> yemekler) {
    _yemekOnbellegi = yemekler;
    AppLogger.bilgi('✅ ${yemekler.length} yemek yüklendi');
  }

  // ─── Bilinen Protein Kaynakları (Türk Mutfağı) ─────────────────────────
  static const _proteinKaynaklari = <String>{
    // Kırmızı et
    'dana', 'kuzu', 'kiyma', 'biftek', 'kofte', 'sucuk', 'pastirma',
    // Beyaz et
    'tavuk', 'hindi', 'piliç',
    // Balık & deniz ürünleri
    'somon', 'balik', 'ton', 'levrek', 'hamsi', 'alabalik', 'karides',
    'kalamar', 'sardalya', 'uskumru', 'cipura', 'mezgit',
    // Yumurta & süt
    'yumurta', 'menemen', 'omlet', 'peynir', 'kasar', 'lor', 'sut',
    'yogurt', 'ayran', 'feta', 'labne',
    // Baklagiller
    'barbunya', 'mercimek', 'nohut', 'fasulye', 'borulce', 'bezelye',
    // Kuruyemiş
    'badem', 'ceviz', 'findik', 'fistik',
    // Diğer
    'tofu', 'soya', 'jambon', 'avokado', 'yulaf',
  };

  /// Yemeğin çekirdek (ana) besinlerini tespit et
  /// Öncelik: proteinKaynagi alanı > ad analizi > malzeme analizi
  Set<String> _cekirdekBesinler(Yemek yemek) {
    final besinler = <String>{};

    // 1. proteinKaynagi alanından
    if (yemek.proteinKaynagi != null && yemek.proteinKaynagi!.isNotEmpty) {
      final pk = yemek.proteinKaynagi!.toLowerCase().trim();
      for (final kaynak in _proteinKaynaklari) {
        if (pk.contains(kaynak)) {
          besinler.add(kaynak);
        }
      }
    }

    // 2. Yemek adından
    final adLower = yemek.ad.toLowerCase();
    for (final kaynak in _proteinKaynaklari) {
      if (adLower.contains(kaynak)) {
        besinler.add(kaynak);
      }
    }

    // 3. İlk 3 malzemeden (genelde ana besinler başta)
    for (int i = 0; i < yemek.malzemeler.length && i < 3; i++) {
      final malzLower = yemek.malzemeler[i].toLowerCase();
      for (final kaynak in _proteinKaynaklari) {
        if (malzLower.contains(kaynak)) {
          besinler.add(kaynak);
        }
      }
    }

    return besinler;
  }
}


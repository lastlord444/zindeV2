// lib/data/repositories/analytics_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/nutrition/gunluk_plan.dart';
import '../../domain/entities/analytics/haftalik_rapor.dart';
import '../../domain/entities/analytics/alisveris_listesi.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/repositories/meal_plan_repository.dart';

/// Analitik repository implementasyonu
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final MealPlanRepository _planRepo;

  const AnalyticsRepositoryImpl({required MealPlanRepository planRepo})
      : _planRepo = planRepo;

  @override
  Future<Either<Failure, HaftalikRapor>> haftalikRaporOlustur({
    required String userId,
    required DateTime baslangic,
  }) async {
    try {
      final planlarResult =
          await _planRepo.haftalikPlanlarGetir(userId, baslangic);

      return planlarResult.fold(
        (hata) => Left(hata),
        (planlar) {
          if (planlar.isEmpty) {
            return Right(HaftalikRapor.bos(userId, baslangic));
          }

          // İstatistikleri hesapla
          final ortalamKalori =
              planlar.map((p) => p.toplamKalori).reduce((a, b) => a + b) /
                  planlar.length;
          final ortalamProtein =
              planlar.map((p) => p.toplamProtein).reduce((a, b) => a + b) /
                  planlar.length;
          final ortalamKarb =
              planlar.map((p) => p.toplamKarbonhidrat).reduce((a, b) => a + b) /
                  planlar.length;
          final ortalamYag =
              planlar.map((p) => p.toplamYag).reduce((a, b) => a + b) /
                  planlar.length;

          return Right(HaftalikRapor.v1(
            userId: userId,
            haftaBaslangic: baslangic,
            haftaBitis: baslangic.add(const Duration(days: 6)),
            gunlukPlanlar: planlar,
            ortalamKalori: ortalamKalori,
            ortalamProtein: ortalamProtein,
            ortalamKarb: ortalamKarb,
            ortalamYag: ortalamYag,
            uyumYuzdesi: _uyumHesapla(planlar),
            tavsiyeler: _tavsiyeOlustur(ortalamKalori, ortalamProtein),
          ));
        },
      );
    } catch (e) {
      AppLogger.hata('Haftalık rapor hatası', e);
      return Left(BilinmeyenHata(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GunlukPlan>>> aylikPlanlarGetir(
      String userId, DateTime ay) async {
    final tumPlanlar = <GunlukPlan>[];
    for (int i = 0; i < 4; i++) {
      final hafta = ay.add(Duration(days: i * 7));
      final result = await _planRepo.haftalikPlanlarGetir(userId, hafta);
      result.fold((f) => null, (planlar) => tumPlanlar.addAll(planlar));
    }
    return Right(tumPlanlar);
  }

  @override
  Future<Either<Failure, AlisverisListesi>> alisverisListesiOlustur({
    required String userId,
    required DateTime haftaBasi,
  }) async {
    try {
      final planlarResult =
          await _planRepo.haftalikPlanlarGetir(userId, haftaBasi);

      return planlarResult.fold(
        (hata) => Left(hata),
        (planlar) {
          // Tüm haftalık yemeklerden malzemeleri topla
          final malzemeMap = <String, MalzemeDetayi>{};
          final kategoriMap = <String, List<MalzemeDetayi>>{};
          int toplamYemekSayisi = 0;

          for (final plan in planlar) {
            for (final yemek in plan.tumOgunler) {
              toplamYemekSayisi++;
              for (final malzeme in yemek.malzemeler) {
                final parsed = _parseMalzeme(malzeme);
                final ad = parsed['ad'] as String;
                final miktar = parsed['miktar'] as int;
                final birim = parsed['birim'] as String;
                final kategori = _malzemeKategoriBelirle(ad);

                if (malzemeMap.containsKey(ad.toLowerCase())) {
                  // Aynı malzemeyi birleştir
                  final mevcut = malzemeMap[ad.toLowerCase()]!;
                  malzemeMap[ad.toLowerCase()] = mevcut.copyWith(
                    miktar: mevcut.miktar + miktar,
                  );
                } else {
                  final detay = MalzemeDetayi(
                    ad: ad,
                    miktar: miktar,
                    birim: birim,
                    kategori: kategori,
                    oncelik: 3,
                    tahminiMaliyet: 0,
                  );
                  malzemeMap[ad.toLowerCase()] = detay;
                }
              }
            }
          }

          // Kategorilere ayır
          for (final entry in malzemeMap.entries) {
            final kategori = entry.value.kategori;
            kategoriMap.putIfAbsent(kategori, () => []);
            kategoriMap[kategori]!.add(entry.value);
          }

          final bitis = haftaBasi.add(const Duration(days: 6));
          return Right(AlisverisListesi(
            baslangicTarihi: haftaBasi,
            bitisTarihi: bitis,
            malzemeler: malzemeMap,
            kategoriler: kategoriMap,
            marketBolumleri: kategoriMap, // Aynı kategoriler
            toplamMaliyetTahmini: 0,
            toplamMalzemeSayisi: malzemeMap.length,
            planliGunSayisi: planlar.length,
            toplamYemekSayisi: toplamYemekSayisi,
            oneriler: _alisverisOnerileri(malzemeMap.length),
            olusturulmaTarihi: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      return Left(BilinmeyenHata(e.toString()));
    }
  }

  // ─── V2 Uyum Hesaplama ─────────────────────────────────────────────────
  double _uyumHesapla(List<GunlukPlan> planlar) {
    if (planlar.isEmpty) return 0;
    int tamamlanan = 0;
    int toplam = 0;
    for (final plan in planlar) {
      for (final yemek in plan.tumOgunler) {
        toplam++;
        final durum = plan.ogunDurumlari[yemek.id.toString()] ?? 'bekliyor';
        // V2: yedi veya onaylandi ise yenmiş sayılır
        if (durum == 'yedi' || durum == 'onaylandi') {
          tamamlanan++;
        }
      }
    }
    return toplam > 0 ? tamamlanan / toplam : 0;
  }

  List<String> _tavsiyeOlustur(double kalori, double protein) {
    final tavsiyeler = <String>[];
    if (kalori < 1500) {
      tavsiyeler.add('📊 Günlük kaloriniz hedefin altında. Porsiyon miktarlarını artırmayı deneyin.');
    }
    if (protein < 100) {
      tavsiyeler.add('💪 Protein alımınız düşük. Öğünlere yumurta veya tavuk eklemeyi deneyin.');
    }
    if (tavsiyeler.isEmpty) {
      tavsiyeler.add('✅ Harika gidiyorsunuz! Beslenme planınıza iyi uyum sağladınız.');
    }
    return tavsiyeler;
  }

  // ─── Malzeme Parse Helper ────────────────────────────────────────────
  /// "80g Yulaf", "2 adet Yumurta", "1/2 Avokado" gibi stringleri parse eder
  Map<String, dynamic> _parseMalzeme(String malzeme) {
    final trimmed = malzeme.trim();
    
    // Başındaki sayıyı yakala
    final sayiMatch = RegExp(r'^(\d+(?:[.,/]\d+)?)\s*(.*)$').firstMatch(trimmed);
    if (sayiMatch == null) {
      return {'ad': trimmed, 'miktar': 1, 'birim': 'adet'};
    }

    final sayiStr = sayiMatch.group(1)!;
    var kalan = sayiMatch.group(2)!.trim();

    // Sayıyı parse et
    int miktar;
    if (sayiStr.contains('/')) {
      final parts = sayiStr.split('/');
      final pay = double.tryParse(parts[0]) ?? 0;
      final payda = double.tryParse(parts[1]) ?? 1;
      miktar = payda != 0 ? (pay / payda).ceil() : 1;
    } else {
      miktar = (double.tryParse(sayiStr.replaceAll(',', '.')) ?? 1).ceil();
    }

    // Birim tespit et
    String birim = 'adet';
    final birimler = ['g', 'gr', 'gram', 'ml', 'adet', 'dilim', 'bardak', 
                      'kase', 'porsiyon', 'yemek kaşığı', 'çay kaşığı', 
                      'tatlı kaşığı', 'yk', 'çk', 'demet', 'diş', 'tutam'];
    for (final b in birimler) {
      if (kalan.toLowerCase().startsWith(b)) {
        birim = b;
        kalan = kalan.substring(b.length).trim();
        break;
      }
    }

    final ad = kalan.isNotEmpty ? kalan : trimmed;
    return {'ad': ad, 'miktar': miktar, 'birim': birim};
  }

  /// Malzeme adından kategori belirle
  String _malzemeKategoriBelirle(String ad) {
    final lower = ad.toLowerCase();
    if (_containsAny(lower, ['tavuk', 'et', 'kıyma', 'balık', 'somon', 'ton', 'hindi', 'dana'])) {
      return 'Et & Balık';
    }
    if (_containsAny(lower, ['süt', 'peynir', 'yoğurt', 'lor', 'kaşar', 'tereyağ', 'krema'])) {
      return 'Süt Ürünleri';
    }
    if (_containsAny(lower, ['yumurta'])) {
      return 'Yumurta';
    }
    if (_containsAny(lower, ['domates', 'biber', 'soğan', 'salatalık', 'marul', 'ıspanak', 'brokoli', 'havuç', 'roka', 'mantar', 'kabak', 'patlıcan', 'fasulye', 'bezelye'])) {
      return 'Sebze & Meyve';
    }
    if (_containsAny(lower, ['muz', 'elma', 'portakal', 'çilek', 'üzüm', 'karpuz', 'avokado'])) {
      return 'Sebze & Meyve';
    }
    if (_containsAny(lower, ['ekmek', 'pirinç', 'makarna', 'bulgur', 'yulaf', 'un', 'nohut', 'mercimek'])) {
      return 'Tahıl & Baklagil';
    }
    if (_containsAny(lower, ['zeytinyağı', 'yağ', 'zeytin'])) {
      return 'Yağ & Sos';
    }
    if (_containsAny(lower, ['ceviz', 'badem', 'fındık', 'fıstık', 'chia', 'keten'])) {
      return 'Kuruyemiş & Tohum';
    }
    if (_containsAny(lower, ['bal', 'şeker', 'pekmez', 'reçel'])) {
      return 'Tatlandırıcı';
    }
    return 'Diğer';
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  List<String> _alisverisOnerileri(int malzemeSayisi) {
    final oneriler = <String>[];
    if (malzemeSayisi > 30) {
      oneriler.add('📋 Bu hafta $malzemeSayisi farklı malzeme var. Toplu alım yapın!');
    }
    oneriler.add('🥬 Taze sebze ve meyveleri haftada 2 kez alın');
    oneriler.add('🥩 Et ürünlerini buzlukta saklayın');
    return oneriler;
  }
}

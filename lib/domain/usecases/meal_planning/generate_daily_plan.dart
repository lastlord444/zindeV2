// lib/domain/usecases/meal_planning/generate_daily_plan.dart
// V7 - Tek Yemek + Akıllı Ölçekleme (%0 Tolerans Hedefi)

import 'dart:math';
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/config/nutrition_constraints.dart';
import '../../../core/utils/logger.dart';
import '../../entities/nutrition/gunluk_plan.dart';
import '../../entities/nutrition/makro_hedefleri.dart';
import '../../entities/nutrition/yemek.dart';

class GenerateDailyPlan {
  final Random _random = Random();

  // Sayılabilir birimler - bunlar tam sayıya yuvarlanır
  static const _sayilabilirBirimler = [
    'adet', 'dilim', 'porsiyon', 'bardak', 'kase', 'fincan',
    'demet', 'diş', 'yaprak', 'parça', 'tutam', 'avuç',
  ];

  // Kaşık birimleri - bunlar da tam veya yarım sayıya yuvarlanır
  static const _kasikBirimleri = [
    'yemek kaşığı', 'çay kaşığı', 'tatlı kaşığı',
    'yk', 'çk', 'tk',
    'YK', 'ÇK', 'TK',
  ];

  Future<Either<Failure, GunlukPlan>> call({
    required String planId,
    required String userId,
    required DateTime tarih,
    required MakroHedefleri hedefler,
    required List<Yemek> yemekHavuzu,
    required String hedef,
    required List<String> kisitlamalar,
    Map<String, int> haftalikKullanilanYemekler = const {},
  }) async {
    try {
      final uygunYemekler = yemekHavuzu
          .where((y) => y.kisitlamayaUygunMu(kisitlamalar))
          .toList();

      if (uygunYemekler.isEmpty) {
        return const Left(PlanHatasi('Kısıtlamalarınıza uygun yemek bulunamadı.'));
      }

      // Base ID çıkartma fonksiyonu: Varyasyon takılarını uçurup ana yemeği bulur
      String getBaseId(String idStr) {
        var base = idStr;
        if (base.contains('_v7_')) base = base.split('_v7_').first;
        if (base.startsWith('v2_') && base.split('_').length >= 3) {
          final p = base.split('_');
          if (p.last.length >= 3) return base.substring(0, base.length - 2);
        }
        return base;
      }

      final baseKullanimlari = <String, int>{};
      haftalikKullanilanYemekler.forEach((id, count) {
        final bId = getBaseId(id);
        baseKullanimlari[bId] = (baseKullanimlari[bId] ?? 0) + count;
      });

      final dagilim = NutritionConstraints.ogunDagilimGetir(hedef);
      final gerekenOgunler = dagilim.keys.where((k) => (dagilim[k] ?? 0) > 0).toList();

      final uretilenOgunler = <String, Yemek>{};
      double toplamKalori = 0, toplamProtein = 0, toplamKarb = 0, toplamYag = 0;

      double kalanKalori = hedefler.gunlukKalori;
      double kalanProtein = hedefler.gunlukProtein;
      double kalanKarb = hedefler.gunlukKarbonhidrat;
      double kalanYag = hedefler.gunlukYag;

      for (int idx = 0; idx < gerekenOgunler.length; idx++) {
        final ogunAdi = gerekenOgunler[idx];
        final yuzde = dagilim[ogunAdi]!;
        final sonOgun = idx == gerekenOgunler.length - 1;

        double oKalori = sonOgun ? kalanKalori : (hedefler.gunlukKalori * yuzde);
        double oProtein = sonOgun ? kalanProtein : (hedefler.gunlukProtein * yuzde);
        double oKarb = sonOgun ? kalanKarb : (hedefler.gunlukKarbonhidrat * yuzde);
        double oYag = sonOgun ? kalanYag : (hedefler.gunlukYag * yuzde);

        if (oKalori <= 30) continue;

        // Anlık geçerli liste: haftalıkta 0 kez kullanılanlar (Çeşitliliği garantilemek)
        var adayYemekler = uygunYemekler.where((y) => 
            y.ogun == _mapOgunTipi(ogunAdi) && 
            (baseKullanimlari[getBaseId(y.id)] ?? 0) == 0
        ).toList();

        // Eğer tükendiyse haftalıkta 1 kez veya hepsi (Tolerans esnetme)
        if (adayYemekler.isEmpty) {
          adayYemekler = uygunYemekler.where((y) => y.ogun == _mapOgunTipi(ogunAdi)).toList();
        }
        if (adayYemekler.isEmpty) {
          adayYemekler = uygunYemekler;
        }

        Yemek? enIyiYemek;
        double enIyiSkor = double.infinity;

        // Çeşitlilik için çok daha fazla random aday dene (100)
        final denemeSayisi = min(100, adayYemekler.length);
        final karisik = List<Yemek>.from(adayYemekler)..shuffle(_random);

        for (int i = 0; i < denemeSayisi; i++) {
          final aday = karisik[i];
          if (aday.kalori <= 0) continue;

          final ratio = oKalori / aday.kalori;
          if (ratio < 0.3 || ratio > 4.0) continue;

          final tahminiP = aday.protein * ratio;
          final tahminiK = aday.karbonhidrat * ratio;
          final tahminiY = aday.yag * ratio;

          final pFark = (tahminiP - oProtein).abs();
          final kFark = (tahminiK - oKarb).abs();
          final yFark = (tahminiY - oYag).abs();

          final skor = pFark * 2.0 + kFark * 1.0 + yFark * 1.5;

          if (skor < enIyiSkor) {
            enIyiSkor = skor;
            enIyiYemek = aday;
          }
        }

        enIyiYemek ??= adayYemekler[_random.nextInt(adayYemekler.length)];

        // Seçilen yemeği gün içinde tekrar kullanmamak için listeye kaydet
        baseKullanimlari[getBaseId(enIyiYemek.id)] = (baseKullanimlari[getBaseId(enIyiYemek.id)] ?? 0) + 1;

        // Ölçekleme oranı
        final ratio = enIyiYemek.kalori > 0 ? oKalori / enIyiYemek.kalori : 1.0;
        final clampedRatio = ratio.clamp(0.3, 4.0);

        // Malzemeleri ölçekle
        final olceklenenMalzemeler = _scaleMalzemeler(enIyiYemek.malzemeler, clampedRatio);

        // Gerçek makroları hesapla
        final gercekKalori = enIyiYemek.kalori * clampedRatio;
        final gercekProtein = enIyiYemek.protein * clampedRatio;
        final gercekKarb = enIyiYemek.karbonhidrat * clampedRatio;
        final gercekYag = enIyiYemek.yag * clampedRatio;

        final olceklenmisYemek = Yemek(
          id: '${enIyiYemek.id}_v7_${DateTime.now().millisecondsSinceEpoch}',
          ad: enIyiYemek.ad,
          ogun: _mapOgunTipi(ogunAdi),
          kalori: gercekKalori,
          protein: gercekProtein,
          karbonhidrat: gercekKarb,
          yag: gercekYag,
          malzemeler: olceklenenMalzemeler,
          hazirlamaSuresi: enIyiYemek.hazirlamaSuresi,
          zorluk: enIyiYemek.zorluk,
          etiketler: enIyiYemek.etiketler,
          baseWeightG: enIyiYemek.baseWeightG * clampedRatio,
          minMultiplier: 1.0,
          maxMultiplier: 1.0,
          unitName: 'porsiyon',
          gorselUrl: enIyiYemek.gorselUrl,
        );

        uretilenOgunler[ogunAdi] = olceklenmisYemek;
        toplamKalori += gercekKalori;
        toplamProtein += gercekProtein;
        toplamKarb += gercekKarb;
        toplamYag += gercekYag;

        // Kalan bütçeyi güncelle (telafi mekanizması)
        kalanKalori -= gercekKalori;
        kalanProtein -= gercekProtein;
        kalanKarb -= gercekKarb;
        kalanYag -= gercekYag;
      }

      final finalPlan = GunlukPlan(
        id: planId,
        userId: userId,
        tarih: tarih,
        hedefler: hedefler,
        kahvalti: uretilenOgunler['kahvalti'],
        araOgun1: uretilenOgunler['araOgun1'],
        ogleYemegi: uretilenOgunler['ogle'],
        araOgun2: uretilenOgunler['araOgun2'],
        aksamYemegi: uretilenOgunler['aksam'],
        geceAtistirma: uretilenOgunler['geceAtistirma'],
        tamamlananOgunler: const {},
      );

      AppLogger.bilgi('✅ V7 Plan Tamamlandı! P:${toplamProtein.toStringAsFixed(1)} K:${toplamKarb.toStringAsFixed(1)} Y:${toplamYag.toStringAsFixed(1)} Kal:${toplamKalori.toStringAsFixed(0)}');
      AppLogger.bilgi('Hedef: P:${hedefler.gunlukProtein} K:${hedefler.gunlukKarbonhidrat} Y:${hedefler.gunlukYag} Kal:${hedefler.gunlukKalori}');
      return Right(finalPlan);

    } catch (e) {
      AppLogger.hata('Plan oluşturma hatası', e);
      return Left(PlanHatasi('Plan oluşturulurken hata: ${e.toString()}'));
    }
  }

  OgunTipi _mapOgunTipi(String ad) {
    if (ad == 'kahvalti') return OgunTipi.kahvalti;
    if (ad == 'araOgun1') return OgunTipi.araOgun1;
    if (ad == 'ogle') return OgunTipi.ogle;
    if (ad == 'araOgun2') return OgunTipi.araOgun2;
    if (ad == 'aksam') return OgunTipi.aksam;
    if (ad == 'geceAtistirma') return OgunTipi.geceAtistirma;
    return OgunTipi.ogle;
  }

  /// Malzemeleri akıllıca ölçekler:
  /// - "g" ve "ml" birimlerini ondalıklı ölçekler
  /// - "adet", "dilim" gibi sayılabilir birimleri tam sayıya yuvarlar
  /// - "yemek kaşığı" gibi birimleri yarım/tam sayıya yuvarlar
  List<String> _scaleMalzemeler(List<String> malzemeler, double ratio) {
    return malzemeler.map((m) {
      final trimmed = m.trim();

      // Başındaki sayıyı yakala
      final sayiMatch = RegExp(r'^(\d+(?:[.,/]\d+)?)(.*)$').firstMatch(trimmed);
      if (sayiMatch == null) return m; // Sayı yoksa dokunma

      final String sayiStr = sayiMatch.group(1)!;
      final String kalan = sayiMatch.group(2)!;

      double deger;
      // "1/2" gibi kesirli ifadeleri de yakala
      if (sayiStr.contains('/')) {
        final parts = sayiStr.split('/');
        final pay = double.tryParse(parts[0]) ?? 0;
        final payda = double.tryParse(parts[1]) ?? 1;
        deger = payda != 0 ? pay / payda : 0;
      } else {
        deger = double.tryParse(sayiStr.replaceAll(',', '.')) ?? 0;
      }

      if (deger == 0) return m;

      final yeniDeger = deger * ratio;
      final kalanLower = kalan.toLowerCase().trim();

      // Birim tipine göre yuvarlama
      String formatlanmis;

      if (_isSayilabilir(kalanLower)) {
        // Tam sayıya yuvarla (en az 1)
        final yuvarlanmis = max(1, yeniDeger.round());
        formatlanmis = yuvarlanmis.toString();
      } else if (_isKasik(kalanLower)) {
        // Yarım sayıya yuvarla (0.5 adımlarla)
        final yuvarlanmis = max(0.5, (yeniDeger * 2).round() / 2);
        formatlanmis = yuvarlanmis == yuvarlanmis.toInt().toDouble()
            ? yuvarlanmis.toInt().toString()
            : yuvarlanmis.toStringAsFixed(1);
      } else if (_isGramVeyaMl(kalanLower)) {
        // Gram/ml: 5'in katlarına yuvarla
        final yuvarlanmis = max(5, (yeniDeger / 5).round() * 5);
        formatlanmis = yuvarlanmis.toString();
      } else {
        // Diğer: mantıklı bir şekilde yuvarla
        if (yeniDeger < 1) {
          formatlanmis = '1';
        } else {
          final yuvarlanmis = yeniDeger.round();
          formatlanmis = yuvarlanmis.toString();
        }
      }

      return '$formatlanmis$kalan';
    }).toList();
  }

  bool _isSayilabilir(String kalanLower) {
    for (final birim in _sayilabilirBirimler) {
      if (kalanLower.startsWith(birim) || kalanLower.contains(' $birim')) return true;
    }
    return false;
  }

  bool _isKasik(String kalanLower) {
    for (final birim in _kasikBirimleri) {
      if (kalanLower.contains(birim.toLowerCase())) return true;
    }
    return false;
  }

  bool _isGramVeyaMl(String kalanLower) {
    return kalanLower.startsWith('g ') || kalanLower == 'g' ||
           kalanLower.startsWith('ml ') || kalanLower == 'ml';
  }
}

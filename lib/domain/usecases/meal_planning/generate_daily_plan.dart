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
  // Random seed'i tarih bazlı yap - her gün farklı plan için
  Random _randomForSeed(int seed) => Random(seed);

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
    // Her gün için farklı random seed - tarih bazlı
    final random = Random(tarih.millisecondsSinceEpoch ~/ 1000); // Tarihin gününü seed kullan
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
    if (base.contains('_alt_')) base = base.split('_alt_').first; // Alternatif ID'si
    if (base.startsWith('v2_') && base.split('_').length >= 3) {
      final p = base.split('_');
      if (p.last.length >= 3) return base.substring(0, base.length - 2);
    }
    return base;
  }

  // Haftalık kullanım takibini, gelen veriden doldurarak başlat
  final baseKullanimlari = <String, int>{};
  haftalikKullanilanYemekler.forEach((key, value) {
    baseKullanimlari[getBaseId(key)] = (baseKullanimlari[getBaseId(key)] ?? 0) + value;
  });
  
  // Sadece aynı gün içinde tekrar kullanımı önlemek için minik bir takip
  final buPlanKullanimi = <String, int>{};

      final dagilim = NutritionConstraints.ogunDagilimGetir(hedef);
      AppLogger.bilgi('📊 Hedef: $hedef, Öğün Dağılımı: $dagilim');
      final gerekenOgunler = dagilim.keys.where((k) => (dagilim[k] ?? 0) > 0).toList();
      AppLogger.bilgi('📊 Gereken Öğünler: $gerekenOgunler (${gerekenOgunler.length} adet)');

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

        // Çeşitlilik için 3 seviyeli strateji:
        // 1. Önce bu hafta hiç kullanılmayanlar VE bugün kullanılmayanlar
        var adayYemekler = uygunYemekler.where((y) =>
            y.ogun == _mapOgunTipi(ogunAdi) &&
            (baseKullanimlari[getBaseId(y.id)] ?? 0) == 0 &&
            (buPlanKullanimi[getBaseId(y.id)] ?? 0) == 0
        ).toList();

        // 2. Eğer azsa, 1 kez kullanılanları da dahil et
        if (adayYemekler.length < 10) {
          final onceKullanilan = uygunYemekler.where((y) =>
              y.ogun == _mapOgunTipi(ogunAdi) &&
              (baseKullanimlari[getBaseId(y.id)] ?? 0) <= 1 &&
              (buPlanKullanimi[getBaseId(y.id)] ?? 0) == 0
          ).toList();
          adayYemekler = [...adayYemekler, ...onceKullanilan];
        }

        // 3. Hala azsa, tüm uygun yemekleri al ama aynı gün tekrarını engelle
        if (adayYemekler.length < 5) {
          adayYemekler = uygunYemekler.where((y) => 
            y.ogun == _mapOgunTipi(ogunAdi) && 
            (buPlanKullanimi[getBaseId(y.id)] ?? 0) == 0
          ).toList();
        }
        
        // Acil durum: Aday hiç kalmadıysa aynı gün şartını esnet
        if (adayYemekler.isEmpty) {
          adayYemekler = uygunYemekler.where((y) => y.ogun == _mapOgunTipi(ogunAdi)).toList();
        }
        
        // Her seferinde daha agresif shuffle (3 kez)
        final karisik = List<Yemek>.from(adayYemekler);
        karisik.shuffle(random);
        karisik.shuffle(random);
        karisik.shuffle(random);

        // Kahvaltı öğününde yumurtalı yemekleri listenin BAŞINA taşı (stable sort).
        // Skor rekabeti hâlâ geçerli — sadece önce deneniyor, tolerans korunuyor.
        if (ogunAdi == 'kahvalti') {
          karisik.sort((a, b) {
            final aP = _isYumurtaBazli(a) ? 0 : 1;
            final bP = _isYumurtaBazli(b) ? 0 : 1;
            return aP.compareTo(bP);
          });
        }

        Yemek? enIyiYemek;
        double enIyiSkor = double.infinity;

        // Çeşitlilik için çok daha fazla random aday dene
        final denemeSayisi = min(100, karisik.length);

        for (int i = 0; i < denemeSayisi; i++) {
          final aday = karisik[i];
          if (aday.kalori <= 0) continue;

          final ratio = oKalori / aday.kalori;
          // Yemeğin kendi sınırı varsa ona uy, yoksa 0.3 - 4.0 arası esneklik sağla
          final strictMin = aday.minMultiplier > 0 ? aday.minMultiplier : 0.3;
          final strictMax = aday.maxMultiplier > 0 ? aday.maxMultiplier : 4.0;
          if (ratio < strictMin || ratio > strictMax) continue;

          final tahminiP = aday.protein * ratio;
          final tahminiK = aday.karbonhidrat * ratio;
          final tahminiY = aday.yag * ratio;

          final pFark = (tahminiP - oProtein).abs();
          final kFark = (tahminiK - oKarb).abs();
          final yFark = (tahminiY - oYag).abs();

          double skor = pFark * 2.0 + kFark * 1.0 + yFark * 1.5;

          // Kahvaltı için yumurtalı yemeklere ÇOK GÜÇLÜ skor bonusu ver
          // Yumurtalı yemek her zaman kazanır (diyetisyen standardı)
          if (ogunAdi == 'kahvalti' && _isYumurtaBazli(aday)) {
            skor -= 200.0;
          }

          if (skor < enIyiSkor) {
            enIyiSkor = skor;
            enIyiYemek = aday;
          }
        }

        enIyiYemek ??= adayYemekler[random.nextInt(adayYemekler.length)];

        // Seçilen yemeği BU PLAN içinde ve HAFTALIK listede tekrar kullanmamak için kaydet
        buPlanKullanimi[getBaseId(enIyiYemek.id)] = (buPlanKullanimi[getBaseId(enIyiYemek.id)] ?? 0) + 1;
        baseKullanimlari[getBaseId(enIyiYemek.id)] = (baseKullanimlari[getBaseId(enIyiYemek.id)] ?? 0) + 1;

        // Ölçekleme oranı - Sabit tolerans yerine veritabanından gelen çarpanlara itaat et
        final ratio = enIyiYemek.kalori > 0 ? oKalori / enIyiYemek.kalori : 1.0;
        var clampedRatio = ratio.clamp(
          enIyiYemek.minMultiplier > 0 ? enIyiYemek.minMultiplier : 0.3, 
          enIyiYemek.maxMultiplier > 0 ? enIyiYemek.maxMultiplier : 4.0
        );

        // ⭐ Diyetisyen Kuralı: Öğün başı protein 50g'ı aşmasın
        final maxProtein = NutritionConstraints.maxProteinPerMealG;
        if (enIyiYemek.protein > 0 && enIyiYemek.protein * clampedRatio > maxProtein) {
          final proteinCapRatio = maxProtein / enIyiYemek.protein;
          final minR = enIyiYemek.minMultiplier > 0 ? enIyiYemek.minMultiplier : 0.3;
          clampedRatio = clampedRatio.clamp(minR, proteinCapRatio);
          AppLogger.bilgi('⚠️ Protein cap: ${enIyiYemek.ad} ratio $ratio → $clampedRatio (max ${maxProtein}g)');
        }

        // 📊 Öğün Logları
        print('🍽️ Öğün: $ogunAdi | Hedef: ${oKalori.toStringAsFixed(0)}kcal, P:${oProtein.toStringAsFixed(1)}g, K:${oKarb.toStringAsFixed(1)}g, Y:${oYag.toStringAsFixed(1)}g');
        print('   Seçilen: ${enIyiYemek.ad} | Orijinal: ${enIyiYemek.kalori.toStringAsFixed(0)}kcal, P:${enIyiYemek.protein.toStringAsFixed(1)}g, K:${enIyiYemek.karbonhidrat.toStringAsFixed(1)}g, Y:${enIyiYemek.yag.toStringAsFixed(1)}g');
        print('   Ratio: $ratio (clamped: $clampedRatio limit: ${enIyiYemek.maxMultiplier})');

        // Malzemeleri ölçekle
        final olceklenenMalzemeler = _scaleMalzemeler(enIyiYemek.malzemeler, clampedRatio);

        // Gerçek makroları hesapla
        final gercekKalori = enIyiYemek.kalori * clampedRatio;
        final gercekProtein = enIyiYemek.protein * clampedRatio;
        final gercekKarb = enIyiYemek.karbonhidrat * clampedRatio;
        final gercekYag = enIyiYemek.yag * clampedRatio;

        print('   ✅ Ölçeklenmiş: ${gercekKalori.toStringAsFixed(0)}kcal, P:${gercekProtein.toStringAsFixed(1)}g, K:${gercekKarb.toStringAsFixed(1)}g, Y:${gercekYag.toStringAsFixed(1)}g');

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

        // Alternatifleri bul (2 benzer makro değerli yemek)
        final alternatifler = _bulAlternatifler(
          adayYemekler: adayYemekler,
          secilenYemek: enIyiYemek,
          hedefKalori: oKalori,
          hedefProtein: oProtein,
          hedefKarb: oKarb,
          hedefYag: oYag,
        );

        // Alternatif yemekleri oluştur
        final alternatifYemekler = alternatifler.map((alt) {
          final altRatio = oKalori / alt.kalori;
          final altClamped = altRatio.clamp(0.3, 4.0);
          return Yemek(
            id: '${alt.id}_alt_${DateTime.now().millisecondsSinceEpoch}_${alternatifler.indexOf(alt)}',
            ad: alt.ad,
            ogun: _mapOgunTipi(ogunAdi),
            kalori: alt.kalori * altClamped,
            protein: alt.protein * altClamped,
            karbonhidrat: alt.karbonhidrat * altClamped,
            yag: alt.yag * altClamped,
            malzemeler: _scaleMalzemeler(alt.malzemeler, altClamped),
            alternatifler: const [],
            hazirlamaSuresi: alt.hazirlamaSuresi,
            zorluk: alt.zorluk,
            etiketler: alt.etiketler,
            baseWeightG: alt.baseWeightG * altClamped,
            dominantMacro: alt.dominantMacro,
            minMultiplier: 1.0,
            maxMultiplier: 1.0,
            unitName: 'porsiyon',
            gorselUrl: alt.gorselUrl,
          );
        }).toList();

        // Ana yemeği alternatiflerle birlikte güncelle
        final sonYemek = olceklenmisYemek.copyWith(alternatifYemekler: alternatifYemekler);
        uretilenOgunler[ogunAdi] = sonYemek;
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

      // ─── Tolerans Retry Mekanizması (Geliştirilmiş) ─────────────────────────
      // Plan oluşturulduktan sonra toplam makro toleransını kontrol et.
      // Aşılıyorsa EN ÇOK sapma yapan öğünü yeniden seç (max 5 retry).
      const maxRetry = 5;
      for (int retry = 0; retry < maxRetry; retry++) {
        // Toplamları yeniden hesapla
        toplamKalori = 0; toplamProtein = 0; toplamKarb = 0; toplamYag = 0;
        for (final y in uretilenOgunler.values) {
          toplamKalori += y.kalori;
          toplamProtein += y.protein;
          toplamKarb += y.karbonhidrat;
          toplamYag += y.yag;
        }

        // Hangi makro en çok sapıyor?
        final sapmalar = <String, double>{
          'kalori': hedefler.gunlukKalori > 0 ? (toplamKalori - hedefler.gunlukKalori).abs() / hedefler.gunlukKalori : 0,
          'protein': hedefler.gunlukProtein > 0 ? (toplamProtein - hedefler.gunlukProtein).abs() / hedefler.gunlukProtein : 0,
          'karb': hedefler.gunlukKarbonhidrat > 0 ? (toplamKarb - hedefler.gunlukKarbonhidrat).abs() / hedefler.gunlukKarbonhidrat : 0,
          'yag': hedefler.gunlukYag > 0 ? (toplamYag - hedefler.gunlukYag).abs() / hedefler.gunlukYag : 0,
        };

        final maxSapma = sapmalar.values.reduce((a, b) => a > b ? a : b);
        if (maxSapma <= 0.10) break; // Tolerans içinde, retry gerekmez

        if (retry < maxRetry - 1) {
          AppLogger.uyari('⚠️ Tolerans aşıldı (retry ${retry + 1}/$maxRetry): sapmalar=$sapmalar');
          
          // En çok sapma yapan makroyu bul
          String enSapanMakro = 'kalori';
          double enSapanDeger = 0;
          sapmalar.forEach((makro, deger) {
            if (deger > enSapanDeger) {
              enSapanDeger = deger;
              enSapanMakro = makro;
            }
          });

          // Her öğünün bu makrodaki katkısını hesapla
          String enSapanOgun = gerekenOgunler.first;
          double enSapanOgunSapma = 0;
          
          for (final ogunAdi in gerekenOgunler) {
            final ogun = uretilenOgunler[ogunAdi];
            if (ogun == null) continue;
            
            double ogunMiktar = 0;
            double hedefMiktar = 0;
            
            switch (enSapanMakro) {
              case 'kalori':
                ogunMiktar = ogun.kalori;
                hedefMiktar = hedefler.gunlukKalori * dagilim[ogunAdi]!;
                break;
              case 'protein':
                ogunMiktar = ogun.protein;
                hedefMiktar = hedefler.gunlukProtein * dagilim[ogunAdi]!;
                break;
              case 'karb':
                ogunMiktar = ogun.karbonhidrat;
                hedefMiktar = hedefler.gunlukKarbonhidrat * dagilim[ogunAdi]!;
                break;
              case 'yag':
                ogunMiktar = ogun.yag;
                hedefMiktar = hedefler.gunlukYag * dagilim[ogunAdi]!;
                break;
            }
            
            final sapma = (ogunMiktar - hedefMiktar).abs() / (hedefMiktar > 0 ? hedefMiktar : 1);
            if (sapma > enSapanOgunSapma) {
              enSapanOgunSapma = sapma;
              enSapanOgun = ogunAdi;
            }
          }

          final sapanOgun = uretilenOgunler[enSapanOgun];
          if (sapanOgun == null) break;

          // Kalan bütçeyi yeniden hesapla
          double yeniKalanKal = hedefler.gunlukKalori;
          double yeniKalanP = hedefler.gunlukProtein;
          double yeniKalanK = hedefler.gunlukKarbonhidrat;
          double yeniKalanY = hedefler.gunlukYag;
          for (final entry in uretilenOgunler.entries) {
            if (entry.key != enSapanOgun) {
              yeniKalanKal -= entry.value.kalori;
              yeniKalanP -= entry.value.protein;
              yeniKalanK -= entry.value.karbonhidrat;
              yeniKalanY -= entry.value.yag;
            }
          }

          // Sapan öğün için en uygun yemeği yeniden ara
          final retryAdaylar = uygunYemekler.where((y) => 
            y.ogun == _mapOgunTipi(enSapanOgun) && y.id != sapanOgun.id
          ).toList();
          retryAdaylar.shuffle(random);

          Yemek? yeniEnIyi;
          double yeniEnIyiSkor = double.infinity;
          for (int i = 0; i < min(100, retryAdaylar.length); i++) {
            final aday = retryAdaylar[i];
            if (aday.kalori <= 0) continue;
            final ratio = yeniKalanKal / aday.kalori;
            final sMin = aday.minMultiplier > 0 ? aday.minMultiplier : 0.3;
            final sMax = aday.maxMultiplier > 0 ? aday.maxMultiplier : 4.0;
            if (ratio < sMin || ratio > sMax) continue;
            final pF = (aday.protein * ratio - yeniKalanP).abs();
            final kF = (aday.karbonhidrat * ratio - yeniKalanK).abs();
            final yF = (aday.yag * ratio - yeniKalanY).abs();
            final s = pF * 2.0 + kF * 1.0 + yF * 1.5;
            if (s < yeniEnIyiSkor) { yeniEnIyiSkor = s; yeniEnIyi = aday; }
          }
          if (yeniEnIyi != null) {
            final r = (yeniKalanKal / yeniEnIyi.kalori).clamp(
              yeniEnIyi.minMultiplier > 0 ? yeniEnIyi.minMultiplier : 0.3,
              yeniEnIyi.maxMultiplier > 0 ? yeniEnIyi.maxMultiplier : 4.0,
            );
            uretilenOgunler[enSapanOgun] = Yemek(
              id: '${yeniEnIyi.id}_v7_${DateTime.now().millisecondsSinceEpoch}',
              ad: yeniEnIyi.ad,
              ogun: _mapOgunTipi(enSapanOgun),
              kalori: yeniEnIyi.kalori * r,
              protein: yeniEnIyi.protein * r,
              karbonhidrat: yeniEnIyi.karbonhidrat * r,
              yag: yeniEnIyi.yag * r,
              malzemeler: _scaleMalzemeler(yeniEnIyi.malzemeler, r),
              hazirlamaSuresi: yeniEnIyi.hazirlamaSuresi,
              zorluk: yeniEnIyi.zorluk,
              etiketler: yeniEnIyi.etiketler,
              baseWeightG: yeniEnIyi.baseWeightG * r,
              minMultiplier: 1.0,
              maxMultiplier: 1.0,
              unitName: 'porsiyon',
              gorselUrl: yeniEnIyi.gorselUrl,
            );
            AppLogger.bilgi('🔄 Öğün "$enSapanOgun" yeniden seçildi (en sapan makro: $enSapanMakro)');
          } else {
            break; // Daha iyi aday bulunamadı
          }
        }
      }

      // Toplamları son kez hesapla
      toplamKalori = 0; toplamProtein = 0; toplamKarb = 0; toplamYag = 0;
      for (final y in uretilenOgunler.values) {
        toplamKalori += y.kalori;
        toplamProtein += y.protein;
        toplamKarb += y.karbonhidrat;
        toplamYag += y.yag;
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
        ogunDurumlari: const {}, // Tüm öğünler başlangıçta 'bekliyor' durumunda
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

  /// Yumurta bazlı yemek mi? (malzeme veya etiketlerde yumurta aranır)
  bool _isYumurtaBazli(Yemek yemek) {
    final lower = yemek.ad.toLowerCase();
    if (lower.contains('yumurta') || lower.contains('omlet') || 
        lower.contains('menemen') || lower.contains('egg')) return true;
    for (final m in yemek.malzemeler) {
      if (m.toLowerCase().contains('yumurta')) return true;
    }
    for (final e in yemek.etiketler) {
      if (e.toLowerCase().contains('yumurta')) return true;
    }
    return false;
  }

  // ─── Bilinen Protein Kaynakları (Türk Mutfağı) ─────────────────────────
  static const _proteinKaynaklari = <String>{
    'dana', 'kuzu', 'kiyma', 'biftek', 'kofte', 'sucuk', 'pastirma',
    'tavuk', 'hindi', 'piliç',
    'somon', 'balik', 'ton', 'levrek', 'hamsi', 'alabalik', 'karides',
    'kalamar', 'sardalya', 'uskumru', 'cipura', 'mezgit',
    'yumurta', 'menemen', 'omlet', 'peynir', 'kasar', 'lor', 'sut',
    'yogurt', 'ayran', 'feta', 'labne',
    'barbunya', 'mercimek', 'nohut', 'fasulye', 'borulce', 'bezelye',
    'badem', 'ceviz', 'findik', 'fistik',
    'tofu', 'soya', 'jambon', 'avokado', 'yulaf',
  };

  /// Yemeğin çekirdek besinlerini tespit et
  Set<String> _cekirdekBesinler(Yemek yemek) {
    final besinler = <String>{};
    // proteinKaynagi alanından
    if (yemek.proteinKaynagi != null && yemek.proteinKaynagi!.isNotEmpty) {
      final pk = yemek.proteinKaynagi!.toLowerCase().trim();
      for (final k in _proteinKaynaklari) {
        if (pk.contains(k)) besinler.add(k);
      }
    }
    // Yemek adından
    final adLower = yemek.ad.toLowerCase();
    for (final k in _proteinKaynaklari) {
      if (adLower.contains(k)) besinler.add(k);
    }
    // İlk 3 malzemeden
    for (int i = 0; i < yemek.malzemeler.length && i < 3; i++) {
      final mLower = yemek.malzemeler[i].toLowerCase();
      for (final k in _proteinKaynaklari) {
        if (mLower.contains(k)) besinler.add(k);
      }
    }
    return besinler;
  }

  /// 2 alternatif yemek bul - FARKLI protein kaynağı + protein limiti
  List<Yemek> _bulAlternatifler({
    required List<Yemek> adayYemekler,
    required Yemek secilenYemek,
    required double hedefKalori,
    required double hedefProtein,
    required double hedefKarb,
    required double hedefYag,
  }) {
    final secilenCekirdek = _cekirdekBesinler(secilenYemek);
    final maxProtein = NutritionConstraints.maxProteinPerMealG;

    // 1. Seçilen yemeği ve aynı çekirdek besine sahip yemekleri ele
    final filtrelenmis = adayYemekler.where((y) {
      if (y.id == secilenYemek.id) return false;
      final adayCekirdek = _cekirdekBesinler(y);
      final kesisim = secilenCekirdek.intersection(adayCekirdek);
      return kesisim.isEmpty; // Çekirdek besin çakışması olmamalı
    }).toList();

    if (filtrelenmis.length < 2) return [];

    // 2. Benzersiz protein kaynağı: her kaynaktan max 1 tane
    final benzersizMap = <String, MapEntry<Yemek, double>>{};

    for (final aday in filtrelenmis) {
      if (aday.kalori <= 0) continue;
      final ratio = hedefKalori / aday.kalori;
      if (ratio < 0.3 || ratio > 4.0) continue;

      // Protein limiti kontrolü
      final tahminiP = aday.protein * ratio;
      var effectiveRatio = ratio;
      if (tahminiP > maxProtein && aday.protein > 0) {
        effectiveRatio = maxProtein / aday.protein;
        if (effectiveRatio < 0.3) continue;
      }

      final tP = aday.protein * effectiveRatio;
      final tK = aday.karbonhidrat * effectiveRatio;
      final tY = aday.yag * effectiveRatio;

      final pFark = (tP - hedefProtein).abs();
      final kFark = (tK - hedefKarb).abs();
      final yFark = (tY - hedefYag).abs();
      final skor = pFark * 2.0 + kFark * 1.0 + yFark * 1.5;

      final besinKey = _cekirdekBesinler(aday).join('+');
      if (!benzersizMap.containsKey(besinKey) || benzersizMap[besinKey]!.value > skor) {
        benzersizMap[besinKey] = MapEntry(aday, skor);
      }
    }

    // 3. Skor en düşük 2 FARKLI protein kaynaklı yemeği al
    final sirali = benzersizMap.values.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sirali.take(2).map((e) => e.key).toList();
  }
}

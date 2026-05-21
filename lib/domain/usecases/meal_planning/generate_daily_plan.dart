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

  // Base ID çıkartma fonksiyonu: Varyasyon takılarını uçurup ana yemeği bulur
  static String getBaseId(String idStr) {
    var base = idStr;
    if (base.contains('_v7_')) base = base.split('_v7_').first;
    if (base.contains('_alt_')) base = base.split('_alt_').first; // Alternatif ID'si
    if (base.startsWith('v2_') && base.split('_').length >= 3) {
      final p = base.split('_');
      if (p.last.length >= 3) return base.substring(0, base.length - 2);
    }
    return base;
  }

  // Yemek objesi üzerinden deterministic base key üreten fonksiyon
  static String getMealBaseKey(Yemek yemek) {
    return '${yemek.ogun.canonicalName}:${yemek.normalizedBaseName}';
  }

  // Haftalık kullanımı base key'lere dönüştüren yardımcı fonksiyon (test edilebilirlik için)
  static Map<String, int> buildBaseUsageMap(Map<String, int> haftalikKullanilanYemekler, List<Yemek> yemekHavuzu) {
    final baseKullanimlari = <String, int>{};
    haftalikKullanilanYemekler.forEach((key, value) {
      try {
        final y = yemekHavuzu.firstWhere(
          (y) => y.id == key || getBaseId(y.id) == getBaseId(key)
        );
        final baseKey = getMealBaseKey(y);
        baseKullanimlari[baseKey] = (baseKullanimlari[baseKey] ?? 0) + value;
      } catch (_) {
        // Bulunamazsa fallback olarak eski id formatını kullan
        baseKullanimlari[getBaseId(key)] = (baseKullanimlari[getBaseId(key)] ?? 0) + value;
      }
    });
    return baseKullanimlari;
  }

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

  // Haftalık kullanım takibini, gelen veriden doldurarak başlat
  final baseKullanimlari = buildBaseUsageMap(haftalikKullanilanYemekler, yemekHavuzu);
  
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

        // ⭐ ARA ÖĞÜN ÇEŞİTLİLİK BOOST: Local yemek havuzunu Supabase'e ekle
        // araOgun1 veya araOgun2 seçiliyorsa local 53-snack havuzunu enjekte et
        List<Yemek> genisHavuz = uygunYemekler;
        if (ogunAdi == 'araOgun1' || ogunAdi == 'araOgun2') {
          final ogunTipiLocal = _mapOgunTipi(ogunAdi);
          final localSnacklar = _localAraOgunHavuzu(ogunTipiLocal)
              .where((y) => y.kisitlamayaUygunMu(kisitlamalar))
              .toList();
          // Local yemekler zaten araOgunX tipinde, Supabase ile birleştir (duplicate ID'si olmasın)
          final mevcutIds = uygunYemekler.map((y) => y.id).toSet();
          final yeniLocallar = localSnacklar.where((y) => !mevcutIds.contains(y.id)).toList();
          genisHavuz = [...uygunYemekler, ...yeniLocallar];
          AppLogger.bilgi('🍎 Ara öğün havuzu: ${uygunYemekler.length} Supabase + ${yeniLocallar.length} local = ${genisHavuz.length} toplam');
        }

        // Çeşitlilik için 3 seviyeli strateji:
        // 1. Önce bu hafta hiç kullanılmayanlar VE bugün kullanılmayanlar
        var adayYemekler = genisHavuz.where((y) =>
            y.ogun == _mapOgunTipi(ogunAdi) &&
            (baseKullanimlari[getMealBaseKey(y)] ?? 0) == 0 &&
            (buPlanKullanimi[getMealBaseKey(y)] ?? 0) == 0
        ).toList();

        // 2. Eğer azsa, 1 kez kullanılanları da dahil et
        if (adayYemekler.length < 10) {
          final onceKullanilan = genisHavuz.where((y) =>
              y.ogun == _mapOgunTipi(ogunAdi) &&
              (baseKullanimlari[getMealBaseKey(y)] ?? 0) <= 1 &&
              (buPlanKullanimi[getMealBaseKey(y)] ?? 0) == 0
          ).toList();
          adayYemekler = [...adayYemekler, ...onceKullanilan];
        }

        // 3. Hala azsa, tüm uygun yemekleri al ama aynı gün tekrarını engelle
        if (adayYemekler.length < 5) {
          adayYemekler = genisHavuz.where((y) => 
            y.ogun == _mapOgunTipi(ogunAdi) && 
            (buPlanKullanimi[getMealBaseKey(y)] ?? 0) == 0
          ).toList();
        }
        
        // Acil durum: Aday hiç kalmadıysa aynı gün şartını esnet
        if (adayYemekler.isEmpty) {
          adayYemekler = genisHavuz.where((y) => y.ogun == _mapOgunTipi(ogunAdi)).toList();
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
          final strictMaxVal = aday.maxMultiplier > 0 ? aday.maxMultiplier : 4.0;
          if (ratio < strictMin || ratio > 4.0) continue;

          final maxRatioByWeight = (aday.baseWeightG > 0) ? (600.0 / aday.baseWeightG) : strictMaxVal;
          final strictMax = min(strictMaxVal, maxRatioByWeight);
          final clampedRatio = ratio.clamp(strictMin, strictMax);

          final tahminiP = aday.protein * clampedRatio;
          final tahminiK = aday.karbonhidrat * clampedRatio;
          final tahminiY = aday.yag * clampedRatio;

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
        final secilenBaseKey = getMealBaseKey(enIyiYemek);
        buPlanKullanimi[secilenBaseKey] = (buPlanKullanimi[secilenBaseKey] ?? 0) + 1;
        baseKullanimlari[secilenBaseKey] = (baseKullanimlari[secilenBaseKey] ?? 0) + 1;

        // Ölçekleme oranı - Sabit tolerans yerine veritabanından gelen çarpanlara itaat et
        final ratio = enIyiYemek.kalori > 0 ? oKalori / enIyiYemek.kalori : 1.0;
        final minR = enIyiYemek.minMultiplier > 0 ? enIyiYemek.minMultiplier : 0.3;
        final maxRVal = enIyiYemek.maxMultiplier > 0 ? enIyiYemek.maxMultiplier : 4.0;
        final maxRatioByWeight = (enIyiYemek.baseWeightG > 0) ? (600.0 / enIyiYemek.baseWeightG) : maxRVal;
        final maxR = min(maxRVal, maxRatioByWeight);
        var clampedRatio = ratio.clamp(minR, maxR);

        // ⭐ Diyetisyen Kuralı: Öğün başı protein yumuşak cap
        // KRİTİK: Protein cap kalori hedefini ASLA ezmemeli.
        // Eğer cap uygulamak ratio'yu min'in altına düşürürse → cap UYGULANMAZ.
        const maxProtein = NutritionConstraints.maxProteinPerMealG;
        if (enIyiYemek.protein > 0 && enIyiYemek.protein * clampedRatio > maxProtein) {
          final proteinCapRatio = maxProtein / enIyiYemek.protein;
          final minR = enIyiYemek.minMultiplier > 0 ? enIyiYemek.minMultiplier : 0.3;
          // Sadece cap uygulandığında ratio hâlâ geçerliyse uygula
          if (proteinCapRatio >= minR) {
            clampedRatio = clampedRatio.clamp(minR, proteinCapRatio);
            AppLogger.bilgi('⚠️ Protein cap: ${enIyiYemek.ad} ratio $ratio → $clampedRatio (max ${maxProtein}g)');
          } else {
            AppLogger.bilgi('ℹ️ Protein cap atlandı (kalori öncelikli): ${enIyiYemek.ad} → ${(enIyiYemek.protein * clampedRatio).toStringAsFixed(1)}g protein');
          }
        }

        // 📊 Öğün Logları
        AppLogger.bilgi('🍽️ Öğün: $ogunAdi | Hedef: ${oKalori.toStringAsFixed(0)}kcal, P:${oProtein.toStringAsFixed(1)}g, K:${oKarb.toStringAsFixed(1)}g, Y:${oYag.toStringAsFixed(1)}g');
        AppLogger.bilgi('   Seçilen: ${enIyiYemek.ad} | Orijinal: ${enIyiYemek.kalori.toStringAsFixed(0)}kcal, P:${enIyiYemek.protein.toStringAsFixed(1)}g, K:${enIyiYemek.karbonhidrat.toStringAsFixed(1)}g, Y:${enIyiYemek.yag.toStringAsFixed(1)}g');
        AppLogger.bilgi('   Ratio: $ratio (clamped: $clampedRatio limit: ${enIyiYemek.maxMultiplier})');

        // Malzemeleri ölçekle
        final olceklenenMalzemeler = _scaleMalzemeler(enIyiYemek.malzemeler, clampedRatio);

        // 🔥 KRİTİK FIX: Malzeme yuvarlaması sonrası gerçek effective ratio hesapla
        // Malzeme miktarları yuvarlandığı için makrolar da buna uymalı (besin ↔ makro tutarlılığı)
        var effectiveRatio = _computeEffectiveRatio(
            enIyiYemek.malzemeler, olceklenenMalzemeler, clampedRatio);
        if (enIyiYemek.baseWeightG > 0 && enIyiYemek.baseWeightG * effectiveRatio > 600.0) {
          effectiveRatio = 600.0 / enIyiYemek.baseWeightG;
        }

        // Gerçek makroları EFFECTIVE RATIO ile hesapla (malzemelerle birebir uyumlu)
        final gercekKalori = enIyiYemek.kalori * effectiveRatio;
        final gercekProtein = enIyiYemek.protein * effectiveRatio;
        final gercekKarb = enIyiYemek.karbonhidrat * effectiveRatio;
        final gercekYag = enIyiYemek.yag * effectiveRatio;

        AppLogger.bilgi('   ✅ Ölçeklenmiş (effective=${effectiveRatio.toStringAsFixed(3)}): ${gercekKalori.toStringAsFixed(0)}kcal, P:${gercekProtein.toStringAsFixed(1)}g, K:${gercekKarb.toStringAsFixed(1)}g, Y:${gercekYag.toStringAsFixed(1)}g');

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
          baseWeightG: enIyiYemek.baseWeightG * effectiveRatio,
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

        // HARD GATE: Alternatif sayısı kontrolü
        if (alternatifler.length < 2) {
          final msg = 'Yeterli alternatif bulunamadı ($ogunAdi). Bulunan: ${alternatifler.length}, İstenen: 2. Plan iptal edildi.';
          AppLogger.hata('Alternatif Hatası', Exception(msg));
          return Left(PlanHatasi(msg));
        }

        // Alternatif yemekleri oluştur
        final alternatifYemekler = alternatifler.map((alt) {
          final altRatio = oKalori / alt.kalori;
          final altMin = alt.minMultiplier > 0 ? alt.minMultiplier : 0.3;
          final altMaxVal = alt.maxMultiplier > 0 ? alt.maxMultiplier : 4.0;
          final maxRatioByWeight = (alt.baseWeightG > 0) ? (600.0 / alt.baseWeightG) : altMaxVal;
          final altMax = min(altMaxVal, maxRatioByWeight);

          final altClamped = altRatio.clamp(altMin, altMax);
          final altMalzemeler = _scaleMalzemeler(alt.malzemeler, altClamped);
          var altEffective = _computeEffectiveRatio(
              alt.malzemeler, altMalzemeler, altClamped);
          if (alt.baseWeightG > 0 && alt.baseWeightG * altEffective > 600.0) {
            altEffective = 600.0 / alt.baseWeightG;
          }
          return Yemek(
            id: '${alt.id}_alt_${DateTime.now().millisecondsSinceEpoch}_${alternatifler.indexOf(alt)}',
            ad: alt.ad,
            ogun: _mapOgunTipi(ogunAdi),
            kalori: alt.kalori * altEffective,
            protein: alt.protein * altEffective,
            karbonhidrat: alt.karbonhidrat * altEffective,
            yag: alt.yag * altEffective,
            malzemeler: altMalzemeler,
            alternatifler: const [],
            hazirlamaSuresi: alt.hazirlamaSuresi,
            zorluk: alt.zorluk,
            etiketler: alt.etiketler,
            baseWeightG: alt.baseWeightG * altEffective,
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
          // ⭐ Ara öğünlerde genişletilmiş havuzu kullan (local snacklar dahil)
          List<Yemek> retryHavuz = uygunYemekler;
          if (enSapanOgun == 'araOgun1' || enSapanOgun == 'araOgun2') {
            final ogunTipiRetry = _mapOgunTipi(enSapanOgun);
            final localRetry = _localAraOgunHavuzu(ogunTipiRetry)
                .where((y) => y.kisitlamayaUygunMu(kisitlamalar)).toList();
            final mevcutRetryIds = uygunYemekler.map((y) => y.id).toSet();
            retryHavuz = [...uygunYemekler, ...localRetry.where((y) => !mevcutRetryIds.contains(y.id))];
          }
          final retryAdaylar = retryHavuz.where((y) => 
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
            final sMaxVal = aday.maxMultiplier > 0 ? aday.maxMultiplier : 4.0;
            if (ratio < sMin || ratio > 4.0) continue;
            final maxRatioByWeight = (aday.baseWeightG > 0) ? (600.0 / aday.baseWeightG) : sMaxVal;
            final sMax = min(sMaxVal, maxRatioByWeight);
            final clampedRatio = ratio.clamp(sMin, sMax);
            final pF = (aday.protein * clampedRatio - yeniKalanP).abs();
            final kF = (aday.karbonhidrat * clampedRatio - yeniKalanK).abs();
            final yF = (aday.yag * clampedRatio - yeniKalanY).abs();
            final s = pF * 2.0 + kF * 1.0 + yF * 1.5;
            if (s < yeniEnIyiSkor) { yeniEnIyiSkor = s; yeniEnIyi = aday; }
          }
          if (yeniEnIyi != null) {
            final rMin = yeniEnIyi.minMultiplier > 0 ? yeniEnIyi.minMultiplier : 0.3;
            final rMaxVal = yeniEnIyi.maxMultiplier > 0 ? yeniEnIyi.maxMultiplier : 4.0;
            final maxRatioByWeight = (yeniEnIyi.baseWeightG > 0) ? (600.0 / yeniEnIyi.baseWeightG) : rMaxVal;
            final rMax = min(rMaxVal, maxRatioByWeight);
            final r = (yeniKalanKal / yeniEnIyi.kalori).clamp(rMin, rMax);
            final retryMalzemeler = _scaleMalzemeler(yeniEnIyi.malzemeler, r);
            var retryEffective = _computeEffectiveRatio(
                yeniEnIyi.malzemeler, retryMalzemeler, r);
            if (yeniEnIyi.baseWeightG > 0 && yeniEnIyi.baseWeightG * retryEffective > 600.0) {
              retryEffective = 600.0 / yeniEnIyi.baseWeightG;
            }

            final yeniAlternatifler = _bulAlternatifler(
              adayYemekler: retryAdaylar,
              secilenYemek: yeniEnIyi,
              hedefKalori: yeniKalanKal,
              hedefProtein: yeniKalanP,
              hedefKarb: yeniKalanK,
              hedefYag: yeniKalanY,
            );

            if (yeniAlternatifler.length < 2) {
              final msg = 'Retry: Yeterli alternatif bulunamadı ($enSapanOgun). Bulunan: ${yeniAlternatifler.length}, İstenen: 2. Plan iptal edildi.';
              AppLogger.hata('Alternatif Hatası', Exception(msg));
              return Left(PlanHatasi(msg));
            }

            final alternatifYemekler = yeniAlternatifler.map((alt) {
              final altRatio = yeniKalanKal / alt.kalori;
              final altMin = alt.minMultiplier > 0 ? alt.minMultiplier : 0.3;
              final altMaxVal = alt.maxMultiplier > 0 ? alt.maxMultiplier : 4.0;
              final maxRatioByWeight = (alt.baseWeightG > 0) ? (600.0 / alt.baseWeightG) : altMaxVal;
              final altMax = min(altMaxVal, maxRatioByWeight);

              final altClamped = altRatio.clamp(altMin, altMax);
              final altMalzemeler = _scaleMalzemeler(alt.malzemeler, altClamped);
              var altEffective = _computeEffectiveRatio(
                  alt.malzemeler, altMalzemeler, altClamped);
              if (alt.baseWeightG > 0 && alt.baseWeightG * altEffective > 600.0) {
                altEffective = 600.0 / alt.baseWeightG;
              }
              return Yemek(
                id: '${alt.id}_alt_${DateTime.now().millisecondsSinceEpoch}_${yeniAlternatifler.indexOf(alt)}',
                ad: alt.ad,
                ogun: _mapOgunTipi(enSapanOgun),
                kalori: alt.kalori * altEffective,
                protein: alt.protein * altEffective,
                karbonhidrat: alt.karbonhidrat * altEffective,
                yag: alt.yag * altEffective,
                malzemeler: altMalzemeler,
                alternatifler: const [],
                hazirlamaSuresi: alt.hazirlamaSuresi,
                zorluk: alt.zorluk,
                etiketler: alt.etiketler,
                baseWeightG: alt.baseWeightG * altEffective,
                dominantMacro: alt.dominantMacro,
                minMultiplier: 1.0,
                maxMultiplier: 1.0,
                unitName: 'porsiyon',
                gorselUrl: alt.gorselUrl,
              );
            }).toList();

            uretilenOgunler[enSapanOgun] = Yemek(
              id: '${yeniEnIyi.id}_v7_${DateTime.now().millisecondsSinceEpoch}',
              ad: yeniEnIyi.ad,
              ogun: _mapOgunTipi(enSapanOgun),
              kalori: yeniEnIyi.kalori * retryEffective,
              protein: yeniEnIyi.protein * retryEffective,
              karbonhidrat: yeniEnIyi.karbonhidrat * retryEffective,
              yag: yeniEnIyi.yag * retryEffective,
              malzemeler: retryMalzemeler,
              alternatifYemekler: alternatifYemekler,
              hazirlamaSuresi: yeniEnIyi.hazirlamaSuresi,
              zorluk: yeniEnIyi.zorluk,
              etiketler: yeniEnIyi.etiketler,
              baseWeightG: yeniEnIyi.baseWeightG * retryEffective,
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

      final sapmalarSon = <String, double>{
        'kalori': hedefler.gunlukKalori > 0 ? (toplamKalori - hedefler.gunlukKalori).abs() / hedefler.gunlukKalori : 0,
        'protein': hedefler.gunlukProtein > 0 ? (toplamProtein - hedefler.gunlukProtein).abs() / hedefler.gunlukProtein : 0,
        'karb': hedefler.gunlukKarbonhidrat > 0 ? (toplamKarb - hedefler.gunlukKarbonhidrat).abs() / hedefler.gunlukKarbonhidrat : 0,
        'yag': hedefler.gunlukYag > 0 ? (toplamYag - hedefler.gunlukYag).abs() / hedefler.gunlukYag : 0,
      };

      final maxSapmaSon = sapmalarSon.values.reduce((a, b) => a > b ? a : b);
      if (maxSapmaSon > 0.15) {
        String logMsg = 'Final Validasyon Hatası: ';
        sapmalarSon.forEach((k, v) {
          if (v > 0.15) logMsg += '$k makrosu %${(v * 100).toStringAsFixed(1)} saptı. ';
        });
        AppLogger.hata('Hard Gate', Exception(logMsg));
        return Left(PlanHatasi(logMsg.trim()));
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

  /// Tüm hedefler için zengin LOCAL ara öğün yemek havuzu
  /// Supabase'deki yemeklere EK OLARAK kullanılır
  /// 50+ benzersiz sağlıklı seçenek: protein bar, fıstık ezmesi, whey, curuyemiş vb.
  List<Yemek> _localAraOgunHavuzu(OgunTipi ogunTipi) {
    // Her yemeğin baz değerleri 100g/1 porsiyon için
    // minMultiplier/maxMultiplier ile ölçekleme sınırları belirlendi
    final havuz = <Yemek>[
      // ──────────────── PROTEIN BAR & SUPPLEMENT ────────────────
      Yemek(id: 'local_snack_001', ad: 'Protein Bar (Yüksek Protein)', ogun: ogunTipi,
        kalori: 220, protein: 25, karbonhidrat: 20, yag: 6,
        malzemeler: const ['1 adet Protein Bar (60g)', 'Whey İzolatı baz'], hazirlamaSuresi: 0,
        zorluk: Zorluk.kolay, minMultiplier: 0.8, maxMultiplier: 2.0,
        proteinKaynagi: 'whey', etiketler: const ['yüksek-protein', 'pratik']),
      Yemek(id: 'local_snack_002', ad: 'Whey Protein Shake', ogun: ogunTipi,
        kalori: 160, protein: 30, karbonhidrat: 8, yag: 2,
        malzemeler: const ['30g Whey Protein Tozu', '250ml Süt (yarım yağlı)', '1 çay kaşığı Kakao'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.7, maxMultiplier: 2.5,
        proteinKaynagi: 'whey', etiketler: const ['yüksek-protein', 'shake']),
      Yemek(id: 'local_snack_003', ad: 'Whey + Muz Shake', ogun: ogunTipi,
        kalori: 250, protein: 28, karbonhidrat: 28, yag: 3,
        malzemeler: const ['30g Whey Protein Tozu', '1 adet Muz', '200ml Süt'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.7, maxMultiplier: 2.0,
        proteinKaynagi: 'whey', etiketler: const ['yüksek-protein', 'shake']),
      Yemek(id: 'local_snack_004', ad: 'Gainomax Recovery Shake', ogun: ogunTipi,
        kalori: 195, protein: 22, karbonhidrat: 22, yag: 2,
        malzemeler: const ['1 kutu Gainomax (250ml)', 'Çikolatalı veya Vanilyalı'],
        hazirlamaSuresi: 0, zorluk: Zorluk.kolay, minMultiplier: 0.8, maxMultiplier: 1.5,
        proteinKaynagi: 'whey', etiketler: const ['pratik', 'yüksek-protein']),

      // ──────────────── FISTIK EZMESİ BAZLI ────────────────
      Yemek(id: 'local_snack_005', ad: 'Fıstık Ezmesi & Elma', ogun: ogunTipi,
        kalori: 280, protein: 9, karbonhidrat: 30, yag: 16,
        malzemeler: const ['2 yemek kaşığı Fıstık Ezmesi (32g)', '1 adet Elma (orta boy)'],
        hazirlamaSuresi: 2, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'fıstık', etiketler: const ['doğal', 'sağlıklı-yağ']),
      Yemek(id: 'local_snack_006', ad: 'Fıstık Ezmesi & Pirinç Keki', ogun: ogunTipi,
        kalori: 310, protein: 11, karbonhidrat: 36, yag: 16,
        malzemeler: const ['2 yemek kaşığı Fıstık Ezmesi', '3 adet Pirinç Keki',
                     '1 çay kaşığı Bal'],
        hazirlamaSuresi: 2, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.0,
        proteinKaynagi: 'fıstık', etiketler: const ['pratik']),
      Yemek(id: 'local_snack_007', ad: 'Fıstık Ezmesi & Yulaf Topları', ogun: ogunTipi,
        kalori: 340, protein: 13, karbonhidrat: 38, yag: 16,
        malzemeler: const ['2 yemek kaşığı Fıstık Ezmesi', '40g Yulaf (pişmiş)',
                     '1 çay kaşığı Bal', '1 yemek kaşığı Fındık'],
        hazirlamaSuresi: 5, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 1.8,
        proteinKaynagi: 'fıstık, yulaf', etiketler: const ['yüksek-lif']),
      Yemek(id: 'local_snack_008', ad: 'Badem Ezmesi & Havuç', ogun: ogunTipi,
        kalori: 230, protein: 7, karbonhidrat: 18, yag: 14,
        malzemeler: const ['2 yemek kaşığı Badem Ezmesi', '2 adet Havuç (orta boy)'],
        hazirlamaSuresi: 2, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'badem', etiketler: const ['doğal', 'düşük-karb']),

      // ──────────────── YOĞURT BAZLI ────────────────
      Yemek(id: 'local_snack_009', ad: 'Yoğurt & Granola Kasesi', ogun: ogunTipi,
        kalori: 320, protein: 16, karbonhidrat: 42, yag: 8,
        malzemeler: const ['200g Yoğurt (%2)', '40g Granola', '1 yemek kaşığı Bal',
                     '50g Karışık Meyve'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'yoğurt', etiketler: const ['probiyotik']),
      Yemek(id: 'local_snack_010', ad: 'Yunan Yoğurt & Meyve Kasesi', ogun: ogunTipi,
        kalori: 220, protein: 18, karbonhidrat: 24, yag: 4,
        malzemeler: const ['200g Yunan Yoğurdu (%0 yağ)', '100g Çilek veya Yaban Mersini',
                     '1 çay kaşığı Bal', '1 yemek kaşığı Chia Tohumu'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'yoğurt', etiketler: const ['yüksek-protein', 'düşük-kalori']),
      Yemek(id: 'local_snack_011', ad: 'Yoğurt & Ceviz & Bal', ogun: ogunTipi,
        kalori: 270, protein: 13, karbonhidrat: 20, yag: 14,
        malzemeler: const ['180g Yoğurt', '20g Ceviz (yarım avuç)', '1 çay kaşığı Bal'],
        hazirlamaSuresi: 2, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'yoğurt, ceviz'),
      Yemek(id: 'local_snack_012', ad: 'Yoğurt Parfait (Muz & Yulaf)', ogun: ogunTipi,
        kalori: 350, protein: 15, karbonhidrat: 55, yag: 7,
        malzemeler: const ['150g Yoğurt', '1 adet Muz', '30g Yulaf Ezmesi', '1 çay kaşığı Tarçın'],
        hazirlamaSuresi: 5, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 1.8,
        proteinKaynagi: 'yoğurt'),

      // ──────────────── LOR / COTTAGE CHEESE  ────────────────
      Yemek(id: 'local_snack_013', ad: 'Lor Peyniri & Meyve', ogun: ogunTipi,
        kalori: 200, protein: 20, karbonhidrat: 14, yag: 6,
        malzemeler: const ['150g Lor Peyniri', '100g Çilek', '1 çay kaşığı Bal'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'lor', etiketler: const ['yüksek-protein', 'düşük-kalori']),
      Yemek(id: 'local_snack_014', ad: 'Lor & Salatalık & Zeytin', ogun: ogunTipi,
        kalori: 180, protein: 18, karbonhidrat: 6, yag: 9,
        malzemeler: const ['150g Lor Peyniri', '1 adet Salatalık', '5 adet Zeytin',
                     '1 çay kaşığı Zeytinyağı'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'lor', etiketler: const ['düşük-karb']),
      Yemek(id: 'local_snack_015', ad: 'Süzme Yoğurt Kasesi', ogun: ogunTipi,
        kalori: 190, protein: 22, karbonhidrat: 10, yag: 5,
        malzemeler: const ['180g Süzme Yoğurt', '1 çay kaşığı Bal', '5g Chia Tohumu',
                     '30g Yaban Mersini'],
        hazirlamaSuresi: 2, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'yoğurt', etiketler: const ['yüksek-protein']),

      // ──────────────── KURUYEMIŞ BAZLI ────────────────
      Yemek(id: 'local_snack_016', ad: 'Karışık Kuruyemiş & Kuru Meyve', ogun: ogunTipi,
        kalori: 280, protein: 8, karbonhidrat: 28, yag: 16,
        malzemeler: const ['20g Badem', '10g Ceviz', '10g Kaju', '15g Kuru Kayısı'],
        hazirlamaSuresi: 0, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.5,
        proteinKaynagi: 'badem, ceviz, kaju', etiketler: const ['pratik', 'vegan']),
      Yemek(id: 'local_snack_017', ad: 'Badem & Bitter Çikolata', ogun: ogunTipi,
        kalori: 260, protein: 8, karbonhidrat: 18, yag: 18,
        malzemeler: const ['25g Çiğ Badem', '20g Bitter Çikolata (%70+)'],
        hazirlamaSuresi: 0, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.5,
        proteinKaynagi: 'badem', etiketler: const ['antioksidan']),
      Yemek(id: 'local_snack_018', ad: 'Antep Fıstığı & Yaban Mersini', ogun: ogunTipi,
        kalori: 230, protein: 8, karbonhidrat: 20, yag: 14,
        malzemeler: const ['25g Antep Fıstığı', '100g Yaban Mersini'],
        hazirlamaSuresi: 0, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.5,
        proteinKaynagi: 'fıstık', etiketler: const ['antioksidan', 'vegan']),
      Yemek(id: 'local_snack_019', ad: 'Karışık Kuruyemiş (Sade)', ogun: ogunTipi,
        kalori: 300, protein: 9, karbonhidrat: 12, yag: 24,
        malzemeler: const ['15g Ceviz', '15g Badem', '10g Fındık', '5g Kaju'],
        hazirlamaSuresi: 0, zorluk: Zorluk.kolay, minMultiplier: 0.4, maxMultiplier: 2.5,
        proteinKaynagi: 'ceviz, badem', etiketler: const ['vegan', 'pratik']),

      // ──────────────── PİRİNÇ KEKİ / TAM TAHIL ────────────────
      Yemek(id: 'local_snack_020', ad: 'Pirinç Keki & Avokado', ogun: ogunTipi,
        kalori: 260, protein: 5, karbonhidrat: 28, yag: 14,
        malzemeler: const ['3 adet Pirinç Keki', '1/2 adet Avokado', 'Tuz & Limon suyu'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.0,
        proteinKaynagi: 'avokado', etiketler: const ['glutensiz', 'vegan']),
      Yemek(id: 'local_snack_021', ad: 'Pirinç Keki & Ton Balığı', ogun: ogunTipi,
        kalori: 200, protein: 22, karbonhidrat: 18, yag: 4,
        malzemeler: const ['3 adet Pirinç Keki', '80g Ton Balığı (konserve, suda)',
                     '1 çay kaşığı Limon Suyu'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.0,
        proteinKaynagi: 'ton', etiketler: const ['yüksek-protein', 'glutensiz']),
      Yemek(id: 'local_snack_022', ad: 'Tam Tahıllı Kraker & Humus', ogun: ogunTipi,
        kalori: 240, protein: 9, karbonhidrat: 32, yag: 8,
        malzemeler: const ['5 adet Tam Tahıllı Kraker', '60g Humus'],
        hazirlamaSuresi: 2, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.0,
        proteinKaynagi: 'nohut'),
      Yemek(id: 'local_snack_023', ad: 'Yulaf Ezmesi Tahıl Barı', ogun: ogunTipi,
        kalori: 210, protein: 7, karbonhidrat: 35, yag: 5,
        malzemeler: const ['1 adet Yulaf Ezmesi Barı (50g)', 'Bal ve Yulaf baz'],
        hazirlamaSuresi: 0, zorluk: Zorluk.kolay, minMultiplier: 0.8, maxMultiplier: 2.0,
        proteinKaynagi: 'yulaf', etiketler: const ['pratik', 'lif-kaynaği']),

      // ──────────────── MEYVE BAZLI ────────────────
      Yemek(id: 'local_snack_024', ad: 'Muz & Badem Kasesi', ogun: ogunTipi,
        kalori: 250, protein: 7, karbonhidrat: 38, yag: 9,
        malzemeler: const ['1 adet Büyük Muz', '20g Badem', '1 çay kaşığı Tarçın'],
        hazirlamaSuresi: 1, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'badem', etiketler: const ['vegan', 'pratik']),
      Yemek(id: 'local_snack_025', ad: 'Elma & Peynir Dilimleri', ogun: ogunTipi,
        kalori: 220, protein: 10, karbonhidrat: 24, yag: 10,
        malzemeler: const ['1 adet Elma', '40g Kaşar Peyniri (dilimlenmiş)'],
        hazirlamaSuresi: 2, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'peynir'),
      Yemek(id: 'local_snack_026', ad: 'Meyve Kasesi & Ceviz', ogun: ogunTipi,
        kalori: 200, protein: 4, karbonhidrat: 30, yag: 8,
        malzemeler: const ['50g Çilek', '50g Üzüm', '1/2 adet Muz', '15g Ceviz'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'ceviz', etiketler: const ['antioksidan', 'vegan']),
      Yemek(id: 'local_snack_027', ad: 'Portakal & Badem', ogun: ogunTipi,
        kalori: 190, protein: 6, karbonhidrat: 26, yag: 8,
        malzemeler: const ['1 adet Büyük Portakal', '20g Badem'],
        hazirlamaSuresi: 1, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.5,
        proteinKaynagi: 'badem', etiketler: const ['C-vitamini', 'vegan']),

      // ──────────────── YUMURTA BAZLI ────────────────
      Yemek(id: 'local_snack_028', ad: 'Haşlanmış Yumurta & Peynir', ogun: ogunTipi,
        kalori: 210, protein: 16, karbonhidrat: 2, yag: 15,
        malzemeler: const ['2 adet Haşlanmış Yumurta', '20g Beyaz Peynir',
                     '5 adet Zeytin', 'Tuz & Karabiber'],
        hazirlamaSuresi: 10, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'yumurta, peynir', etiketler: const ['düşük-karb']),
      Yemek(id: 'local_snack_029', ad: 'Mini Yumurta Muffin', ogun: ogunTipi,
        kalori: 240, protein: 18, karbonhidrat: 4, yag: 16,
        malzemeler: const ['2 adet Yumurta', '30g Kıyılmış Tavuk', '1 yemek kaşığı Kırmızı Biber'],
        hazirlamaSuresi: 15, zorluk: Zorluk.orta, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'yumurta, tavuk', etiketler: const ['düşük-karb', 'yüksek-protein']),

      // ──────────────── TAVUK / ET BAZLI ────────────────
      Yemek(id: 'local_snack_030', ad: 'Tavuk Göğüs Strips (Pratik)', ogun: ogunTipi,
        kalori: 190, protein: 30, karbonhidrat: 2, yag: 6,
        malzemeler: const ['100g Haşlanmış Tavuk Göğüs', 'Tuz & Sarımsak Tozu'],
        hazirlamaSuresi: 20, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.5,
        proteinKaynagi: 'tavuk', etiketler: const ['yüksek-protein', 'düşük-karb']),
      Yemek(id: 'local_snack_031', ad: 'Hindi Jambon & Peynir Rulo', ogun: ogunTipi,
        kalori: 180, protein: 20, karbonhidrat: 3, yag: 10,
        malzemeler: const ['60g Hindi Jambon', '30g Beyaz Peynir', 'Roka yaprakları'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.5,
        proteinKaynagi: 'jambon', etiketler: const ['düşük-karb']),

      // ──────────────── ÖZEL SAĞLIKLI FORMULLER ────────────────
      Yemek(id: 'local_snack_032', ad: 'Enerji Topu (Yulaf & Fıstık Ezmesi)', ogun: ogunTipi,
        kalori: 320, protein: 12, karbonhidrat: 38, yag: 14,
        malzemeler: const ['40g Yulaf Ezmesi', '2 yemek kaşığı Fıstık Ezmesi',
                     '1 yemek kaşığı Bal', '10g Çikolata Cipsi'],
        hazirlamaSuresi: 10, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.0,
        proteinKaynagi: 'yulaf, fıstık'),
      Yemek(id: 'local_snack_033', ad: 'Protein Puding (Süt & Whey)', ogun: ogunTipi,
        kalori: 200, protein: 26, karbonhidrat: 14, yag: 4,
        malzemeler: const ['250ml Süt', '25g Whey Protein Tozu', '1 paket Sugar-Free Puding Tozu'],
        hazirlamaSuresi: 5, zorluk: Zorluk.kolay, minMultiplier: 0.7, maxMultiplier: 2.0,
        proteinKaynagi: 'whey', etiketler: const ['yüksek-protein']),
      Yemek(id: 'local_snack_034', ad: 'Çiğ Sebze & Hummus', ogun: ogunTipi,
        kalori: 170, protein: 7, karbonhidrat: 20, yag: 7,
        malzemeler: const ['80g Hummus', '50g Havuç', '50g Salatalık', '30g Kırmızı Biber'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.5,
        proteinKaynagi: 'nohut', etiketler: const ['vegan', 'düşük-kalori']),
      Yemek(id: 'local_snack_035', ad: 'Edamame (Tuzlanmış)', ogun: ogunTipi,
        kalori: 190, protein: 16, karbonhidrat: 14, yag: 8,
        malzemeler: const ['150g Edamame (haşlanmış)', 'Deniz tuzu & Limon'],
        hazirlamaSuresi: 5, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.5,
        proteinKaynagi: 'soya', etiketler: const ['vegan', 'yüksek-protein']),
      Yemek(id: 'local_snack_036', ad: 'Ton Balığı & Salatalık', ogun: ogunTipi,
        kalori: 180, protein: 26, karbonhidrat: 4, yag: 6,
        malzemeler: const ['100g Ton Balığı (suda, konserve)', '1 adet Salatalık',
                     '1 çay kaşığı Zeytinyağı', 'Limon suyu'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.5,
        proteinKaynagi: 'ton', etiketler: const ['yüksek-protein', 'düşük-kalori']),
      Yemek(id: 'local_snack_037', ad: 'Avokado Toast Mini', ogun: ogunTipi,
        kalori: 280, protein: 7, karbonhidrat: 28, yag: 16,
        malzemeler: const ['1 dilim Tam Buğday Ekmek', '1/2 adet Avokado',
                     'Kırmızı Biber Pulu', 'Limon Suyu'],
        hazirlamaSuresi: 5, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'avokado'),
      Yemek(id: 'local_snack_038', ad: 'Muzlu Yulaf Shake', ogun: ogunTipi,
        kalori: 290, protein: 10, karbonhidrat: 52, yag: 5,
        malzemeler: const ['1 adet Muz', '40g Yulaf Ezmesi', '200ml Süt', '1 çay kaşığı Bal'],
        hazirlamaSuresi: 5, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'yulaf'),
      Yemek(id: 'local_snack_039', ad: 'Süt & Yulaf Barı', ogun: ogunTipi,
        kalori: 230, protein: 9, karbonhidrat: 36, yag: 6,
        malzemeler: const ['200ml Süt (tam yağlı)', '1 adet Yulaf Barı'],
        hazirlamaSuresi: 1, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.0,
        proteinKaynagi: 'yulaf'),
      Yemek(id: 'local_snack_040', ad: 'Somon Dilimleri & Krakker', ogun: ogunTipi,
        kalori: 250, protein: 20, karbonhidrat: 16, yag: 12,
        malzemeler: const ['60g Füme Somon', '3 adet Tam Buğday Kraker',
                     '1 yemek kaşığı Labne Peyniri'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.0,
        proteinKaynagi: 'somon', etiketler: const ['omega-3']),

      // ──────────────── BULK ÖZEL (Yüksek Kalori) ────────────────
      Yemek(id: 'local_snack_041', ad: 'Mass Gainer Shake (Muz & Fıstık)', ogun: ogunTipi,
        kalori: 520, protein: 28, karbonhidrat: 70, yag: 14,
        malzemeler: const ['30g Whey Protein', '1 büyük Muz', '2 yemek kaşığı Fıstık Ezmesi',
                     '300ml Süt', '30g Yulaf Ezmesi'],
        hazirlamaSuresi: 5, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 1.5,
        proteinKaynagi: 'whey, fıstık', etiketler: const ['bulk', 'yüksek-kalori']),
      Yemek(id: 'local_snack_042', ad: 'Tam Fıstık Ezmesi Sandviç', ogun: ogunTipi,
        kalori: 430, protein: 15, karbonhidrat: 48, yag: 20,
        malzemeler: const ['2 dilim Tam Buğday Ekmek', '3 yemek kaşığı Fıstık Ezmesi',
                     '1 yemek kaşığı Bal'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 1.8,
        proteinKaynagi: 'fıstık', etiketler: const ['bulk']),
      Yemek(id: 'local_snack_043', ad: 'Yoğurt & Granola & Fıstık Ezmesi', ogun: ogunTipi,
        kalori: 480, protein: 20, karbonhidrat: 54, yag: 18,
        malzemeler: const ['200g Yoğurt', '50g Granola', '2 yemek kaşığı Fıstık Ezmesi',
                     '1 yemek kaşığı Bal'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 1.5,
        proteinKaynagi: 'yoğurt, fıstık', etiketler: const ['bulk']),

      // ──────────────── CUT ÖZEL (Düşük Kalori) ────────────────
      Yemek(id: 'local_snack_044', ad: 'Salatalık & Labne Dip', ogun: ogunTipi,
        kalori: 130, protein: 9, karbonhidrat: 8, yag: 7,
        malzemeler: const ['2 adet Salatalık', '80g Labne Peyniri', 'Dereotu & Sarımsak'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 3.0,
        proteinKaynagi: 'labne', etiketler: const ['düşük-kalori', 'cut']),
      Yemek(id: 'local_snack_045', ad: 'Proteinli Smoothie (Düşük Kalori)', ogun: ogunTipi,
        kalori: 150, protein: 24, karbonhidrat: 10, yag: 2,
        malzemeler: const ['25g Whey Protein (izolat)', '200ml Su', '50g Dondurulmuş Çilek',
                     'Yapay Tatlandırıcı'],
        hazirlamaSuresi: 3, zorluk: Zorluk.kolay, minMultiplier: 0.7, maxMultiplier: 2.0,
        proteinKaynagi: 'whey', etiketler: const ['düşük-kalori', 'cut']),
      Yemek(id: 'local_snack_046', ad: '0% Yoğurt & Çilek', ogun: ogunTipi,
        kalori: 140, protein: 14, karbonhidrat: 18, yag: 1,
        malzemeler: const ['200g Sıfır Yağlı Yoğurt', '100g Çilek', '1 çay kaşığı Stevia'],
        hazirlamaSuresi: 2, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.5,
        proteinKaynagi: 'yoğurt', etiketler: const ['düşük-kalori', 'cut']),
      Yemek(id: 'local_snack_047', ad: 'Haşlanmış Yumurta (Beyaz)', ogun: ogunTipi,
        kalori: 100, protein: 12, karbonhidrat: 1, yag: 5,
        malzemeler: const ['2 adet Haşlanmış Yumurta', 'Sarımsak Tozu & Kırmızı Biber'],
        hazirlamaSuresi: 10, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 3.0,
        proteinKaynagi: 'yumurta', etiketler: const ['düşük-kalori', 'cut']),

      // ──────────────── ÖZEL ATISTIRMALIK  ────────────────
      Yemek(id: 'local_snack_048', ad: 'Bitter Çikolata & Badem', ogun: ogunTipi,
        kalori: 200, protein: 5, karbonhidrat: 14, yag: 15,
        malzemeler: const ['25g Bitter Çikolata (%80)', '15g Çiğ Badem'],
        hazirlamaSuresi: 0, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.5,
        proteinKaynagi: 'badem', etiketler: const ['antioksidan']),
      Yemek(id: 'local_snack_049', ad: 'Zeytinli Tam Buğday Kraker', ogun: ogunTipi,
        kalori: 200, protein: 5, karbonhidrat: 24, yag: 10,
        malzemeler: const ['4 adet Tam Buğday Kraker', '10 adet Siyah Zeytin',
                     '1 çay kaşığı Zeytinyağı'],
        hazirlamaSuresi: 2, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.5,
        proteinKaynagi: 'zeytin'),
      Yemek(id: 'local_snack_050', ad: 'Kefir & Mevsim Meyvesi', ogun: ogunTipi,
        kalori: 160, protein: 8, karbonhidrat: 22, yag: 4,
        malzemeler: const ['200ml Kefir', '80g Mevsim Meyvesi (muz, çilek vb)'],
        hazirlamaSuresi: 2, zorluk: Zorluk.kolay, minMultiplier: 0.6, maxMultiplier: 2.5,
        proteinKaynagi: 'yoğurt', etiketler: const ['probiyotik']),
      Yemek(id: 'local_snack_051', ad: 'Yulaf Krep (Protein)', ogun: ogunTipi,
        kalori: 290, protein: 18, karbonhidrat: 38, yag: 7,
        malzemeler: const ['60g Yulaf Unu', '1 adet Yumurta', '100ml Süt',
                     '1 yemek kaşığı Bal'],
        hazirlamaSuresi: 10, zorluk: Zorluk.orta, minMultiplier: 0.5, maxMultiplier: 2.0,
        proteinKaynagi: 'yumurta, yulaf'),
      Yemek(id: 'local_snack_052', ad: 'Nohut Cipsi (Fırında)', ogun: ogunTipi,
        kalori: 210, protein: 11, karbonhidrat: 28, yag: 6,
        malzemeler: const ['100g Haşlanmış Nohut', '1 çay kaşığı Zeytinyağı',
                     'Baharatlar (kimyon, paprika)'],
        hazirlamaSuresi: 30, zorluk: Zorluk.orta, minMultiplier: 0.5, maxMultiplier: 2.5,
        proteinKaynagi: 'nohut', etiketler: const ['vegan', 'lif-kaynağı']),
      Yemek(id: 'local_snack_053', ad: 'Peynirli Tam Buğday Kraker (2 Çeşit)', ogun: ogunTipi,
        kalori: 245, protein: 12, karbonhidrat: 28, yag: 10,
        malzemeler: const ['4 adet Tam Buğday Kraker', '30g Kaşar Peyniri', '20g Beyaz Peynir'],
        hazirlamaSuresi: 2, zorluk: Zorluk.kolay, minMultiplier: 0.5, maxMultiplier: 2.5,
        proteinKaynagi: 'peynir', etiketler: const ['pratik']),
    ];
    return havuz;
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

  // ─── 🔥 Effective Ratio Hesaplama (Besin ↔ Makro Tutarlılığı) ──────────

  /// Malzeme metninden ilk sayısal değeri çıkarır (kesirli format dahil)
  double? _extractNumber(String text) {
    final trimmed = text.trim();
    final match = RegExp(r'^(\d+(?:[.,/]\d+)?)').firstMatch(trimmed);
    if (match == null) return null;
    final str = match.group(1)!;
    if (str.contains('/')) {
      final parts = str.split('/');
      final pay = double.tryParse(parts[0]) ?? 0;
      final payda = double.tryParse(parts[1]) ?? 1;
      return payda != 0 ? pay / payda : null;
    }
    return double.tryParse(str.replaceAll(',', '.'));
  }

  /// 🔥 Malzeme yuvarlama sonrası gerçek effective ratio hesaplama
  /// Orijinal ve ölçeklenmiş malzeme listelerini karşılaştırarak
  /// malzeme miktarlarıyla tutarlı bir çarpan döndürür.
  /// Bu sayede gösterilen besinler ile makro değerleri birebir uyuşur.
  double _computeEffectiveRatio(
      List<String> original, List<String> scaled, double fallbackRatio) {
    double sumRatios = 0;
    int count = 0;

    for (int i = 0; i < original.length && i < scaled.length; i++) {
      final origNum = _extractNumber(original[i]);
      final scaledNum = _extractNumber(scaled[i]);

      if (origNum == null || origNum <= 0 || scaledNum == null || scaledNum <= 0) {
        continue;
      }

      sumRatios += scaledNum / origNum;
      count++;
    }

    if (count == 0) return fallbackRatio;
    return sumRatios / count;
  }

  /// Yumurta bazlı yemek mi? (malzeme veya etiketlerde yumurta aranır)
  bool _isYumurtaBazli(Yemek yemek) {
    final lower = yemek.ad.toLowerCase();
    if (lower.contains('yumurta') || lower.contains('omlet') || 
        lower.contains('menemen') || lower.contains('egg')) {
      return true;
    }
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
    const maxProtein = NutritionConstraints.maxProteinPerMealG;

    final gecerliAdaylar = <MapEntry<Yemek, double>>[];

    for (final aday in adayYemekler) {
      if (aday.id == secilenYemek.id) continue;
      if (aday.kalori <= 0) continue;
      final ratio = hedefKalori / aday.kalori;
      final altMin = aday.minMultiplier > 0 ? aday.minMultiplier : 0.3;
      final altMaxVal = aday.maxMultiplier > 0 ? aday.maxMultiplier : 4.0;
      if (ratio < altMin || ratio > 4.0) continue;

      final maxRatioByWeight = (aday.baseWeightG > 0) ? (600.0 / aday.baseWeightG) : altMaxVal;
      final altMax = min(altMaxVal, maxRatioByWeight);
      final clampedRatio = ratio.clamp(altMin, altMax);

      // Protein limiti kontrolü
      final tahminiP = aday.protein * clampedRatio;
      var effectiveRatio = clampedRatio;
      if (tahminiP > maxProtein && aday.protein > 0) {
        effectiveRatio = maxProtein / aday.protein;
        if (effectiveRatio < altMin) continue;
      }

      final tP = aday.protein * effectiveRatio;
      final tK = aday.karbonhidrat * effectiveRatio;
      final tY = aday.yag * effectiveRatio;

      final pFark = (tP - hedefProtein).abs();
      final kFark = (tK - hedefKarb).abs();
      final yFark = (tY - hedefYag).abs();
      final skor = pFark * 2.0 + kFark * 1.0 + yFark * 1.5;

      gecerliAdaylar.add(MapEntry(aday, skor));
    }

    gecerliAdaylar.sort((a, b) => a.value.compareTo(b.value));

    // Çeşitlilik öncelikli (farklı protein kaynakları) seçim yapmaya çalış
    final secilenler = <Yemek>[];
    final kullanilanKeyler = <String>{secilenCekirdek.join('+')};

    for (final adayEntry in gecerliAdaylar) {
      if (secilenler.length >= 2) break;
      final aday = adayEntry.key;
      final key = _cekirdekBesinler(aday).join('+');
      
      if (key.isEmpty || !kullanilanKeyler.contains(key)) {
        secilenler.add(aday);
        if (key.isNotEmpty) kullanilanKeyler.add(key);
      }
    }

    // Eğer 2 alternatif bulamadıysak, çeşitliliği göz ardı edip en iyi skora sahip olanları ekle
    for (final adayEntry in gecerliAdaylar) {
      if (secilenler.length >= 2) break;
      final aday = adayEntry.key;
      if (!secilenler.any((s) => s.id == aday.id)) {
        secilenler.add(aday);
      }
    }

    return secilenler;
  }
}




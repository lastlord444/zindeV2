// lib/domain/entities/yemek.dart

import 'package:equatable/equatable.dart';
import 'alternatif_besin.dart';
import 'makro_hedefleri.dart';

/// Öğün tipleri
enum OgunTipi {
  kahvalti('Kahvalt1', '🍳'),
  araOgun1('Ara Öğün 1', '🍎'),
  ogle('Öğle', '🍽️'),
  araOgun2('Ara Öğün 2', '🥤'),
  aksam('Akşam', '🌙'),
  geceAtistirma('Gece Atıştırma', '🌃'),
  cheatMeal('Cheat Meal', '🍕');

  final String ad;
  final String emoji;

  const OgunTipi(this.ad, this.emoji);
}

/// Yemek hazırlama zorluk seviyesi
enum Zorluk {
  kolay('Kolay', '⭐'),
  orta('Orta', '⭐⭐'),
  zor('Zor', '⭐⭐⭐');

  final String ad;
  final String emoji;

  const Zorluk(this.ad, this.emoji);
}

/// Yemek entity'si
class Yemek extends Equatable {
  final String id;
  final String ad;
  final OgunTipi ogun;
  final double kalori;
  final double protein;
  final double karbonhidrat;
  final double yag;
  final List<String> malzemeler;
  final List<AlternatifBesin> alternatifler; // Malzeme alternatifleri
  final List<Yemek> alternatifYemekler; // Yemek alternatifleri (2 adet)
  final int hazirlamaSuresi; // dakika
  final Zorluk zorluk;
  final List<String> etiketler; // ['vejetaryen', 'glutensiz', 'vegan']
  final String? tarif;
  final String? gorselUrl;
  final String? proteinKaynagi; // 🍗 Ana Protein Kaynağı
  
  // ✅ YENİ ALANLAR - Makro Tolerans Sistemi iin
  final double baseWeightG;           // Referans ağırlık (gram) - varsayılan 100
  final String dominantMacro;         // 'protein', 'carb', 'fat' - baskın makro
  final double minMultiplier;         // Minimum öleklendirme arpan1 (varsayılan 0.5)
  final double maxMultiplier;         // Maksimum öleklendirme arpan1 (varsayılan 3.0)
  final String unitName;              // Birim ad1 (varsayılan 'gram')
  // 🔥 Alerji grubu tanımlamalar1 (statik)
  static const Map<String, List<String>> _alerjiGruplari = {
    'balık': ['somon', 'ton', 'levrek', 'hamsi', 'palamut', 'ipura', 'sardalya', 'uskumru', 'istavrit', 'mezgit'],
    'deniz ürünleri': ['karides', 'midye', 'kalamar', 'ahtapot', 'istiridye', 'yenge'],
    'süt': ['süt', 'yoğurt', 'peynir', 'ayran', 'kaymak', 'tereyağı', 'labne', 'lor', 'beyaz peynir', 'kaşar'],
    'yumurta': ['yumurta', 'yumurtal1'],
    'gluten': ['buğday', 'arpa', 'avdar', 'bulgur', 'makarna', 'ekmek', 'un'],
    'fındık': ['fındık', 'badem', 'ceviz', 'antep fıstığı', 'fıstık', 'kaju'],
    'soya': ['soya', 'tofu', 'soya sütü', 'soya sosu'],
  };

  const Yemek.raw({
    required this.id,
    required this.ad,
    required this.ogun,
    required this.kalori,
    required this.protein,
    required this.karbonhidrat,
    required this.yag,
    required this.malzemeler,
    this.alternatifler = const [],
    this.alternatifYemekler = const [],
    required this.hazirlamaSuresi,
    required this.zorluk,
    this.etiketler = const [],
    this.tarif,
    this.gorselUrl,
    this.proteinKaynagi,
    required this.baseWeightG,
    required this.dominantMacro,
    required this.minMultiplier,
    required this.maxMultiplier,
    required this.unitName,
  });

  /// Factory constructor - dominantMacro otomatik hesaplanır
  factory Yemek({
    required String id,
    required String ad,
    required OgunTipi ogun,
    required double kalori,
    required double protein,
    required double karbonhidrat,
    required double yag,
    required List<String> malzemeler,
    List<AlternatifBesin> alternatifler = const [],
    List<Yemek> alternatifYemekler = const [],
    required int hazirlamaSuresi,
    required Zorluk zorluk,
    List<String> etiketler = const [],
    String? tarif,
    String? gorselUrl,
    String? proteinKaynagi,
    double baseWeightG = 100.0,
    String? dominantMacro, // null ise otomatik hesapla
    double minMultiplier = 0.5,
    double maxMultiplier = 3.0,
    String unitName = 'gram',
  }) {
    return Yemek.raw(
      id: id,
      ad: ad,
      ogun: ogun,
      kalori: kalori,
      protein: protein,
      karbonhidrat: karbonhidrat,
      yag: yag,
      malzemeler: malzemeler,
      alternatifler: alternatifler,
      alternatifYemekler: alternatifYemekler,
      hazirlamaSuresi: hazirlamaSuresi,
      zorluk: zorluk,
      etiketler: etiketler,
      tarif: tarif,
      gorselUrl: gorselUrl,
      proteinKaynagi: proteinKaynagi,
      baseWeightG: baseWeightG,
      dominantMacro: dominantMacro ?? _calculateDominantMacro(protein, karbonhidrat, yag, kalori),
      minMultiplier: minMultiplier,
      maxMultiplier: maxMultiplier,
      unitName: unitName,
    );
  }

  /// JSON'dan oluştur (null-safe)
  /// Hem camelCase (Dart) hem snake_case (Supabase DB) key'lerini destekler
  factory Yemek.fromJson(Map<String, dynamic> json) {
    final protein = _parseDouble(json['protein']) ?? 0.0;
    final carb = _parseDouble(json['karbonhidrat']) ?? 0.0;
    final fat = _parseDouble(json['yag']) ?? 0.0;
    final kalori = _parseDouble(json['kalori']) ?? 0.0;
    
    return Yemek(
      id: (json['meal_id'] ?? json['id'])?.toString() ?? '',
      ad: json['ad']?.toString() ?? 'İsimsiz Yemek',
      ogun: ogunTipiFromString(json['ogun']?.toString() ?? 'kahvalti'),
      kalori: kalori,
      protein: protein,
      karbonhidrat: carb,
      yag: fat,
      malzemeler: _parseStringList(json['malzemeler']) ?? [],
      alternatifler: _parseAlternatifler(json['alternatifler']) ?? [],
      alternatifYemekler: _parseYemekAlternatifleri(json['alternatifYemekler']) ?? [],
      hazirlamaSuresi: _parseInt(json['hazirlamaSuresi'] ?? json['hazirlama_suresi']) ?? 15,
      zorluk: zorlukFromString(json['zorluk']?.toString() ?? 'kolay'),
      etiketler: _parseStringList(json['etiketler']) ?? [],
      tarif: json['tarif']?.toString(),
      gorselUrl: (json['gorselUrl'] ?? json['gorsel_url'])?.toString(),
      proteinKaynagi: (json['proteinKaynagi'] ?? json['protein_kaynagi'])?.toString(),
      // Supabase snake_case → Dart camelCase fallback
      baseWeightG: _parseDouble(json['baseWeightG'] ?? json['base_weight_g']) ?? 100.0,
      dominantMacro: (json['dominantMacro'] ?? json['dominant_macro'])?.toString() ?? _calculateDominantMacro(protein, carb, fat, kalori),
      minMultiplier: _parseDouble(json['minMultiplier'] ?? json['min_multiplier']) ?? 0.5,
      maxMultiplier: _parseDouble(json['maxMultiplier'] ?? json['max_multiplier']) ?? 3.0,
      unitName: (json['unitName'] ?? json['unit_name'])?.toString() ?? 'gram',
    );
  }

  /// 🧮 Yemeğin baskın makrosunu hesaplar
  /// Her makronun kalori katkısın1 hesaplar:
  /// Protein: 4 kcal/g, Karbonhidrat: 4 kcal/g, Yağ: 9 kcal/g
  static String _calculateDominantMacro(double protein, double carb, double fat, double kalori) {
    final proteinCal = protein * 4;
    final carbCal = carb * 4;
    final fatCal = fat * 9;
    
    // Eşitlik durumunda öncelik: protein > carb > fat
    if (proteinCal >= carbCal && proteinCal >= fatCal) return 'protein';
    if (carbCal >= proteinCal && carbCal >= fatCal) return 'carb';
    return 'fat';
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

  /// Int değer parse helper metodu
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// String listesi parse helper metodu
  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    try {
      return value.where((e) => e != null).map((e) => e.toString()).toList();
    } catch (e) {
      return null;
    }
  }

  /// Alternatif besinler parse helper metodu
  static List<AlternatifBesin>? _parseAlternatifler(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    try {
      return value
          .where((e) => e != null && e is Map<String, dynamic>)
          .map((e) => AlternatifBesin.fromJson(e))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Alternatif yemekler parse helper metodu
  static List<Yemek>? _parseYemekAlternatifleri(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    try {
      return value
          .where((e) => e != null && e is Map<String, dynamic>)
          .map((e) => Yemek.fromJson(e))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// JSON'a evir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad': ad,
      'ogun': ogun.name,
      'kalori': kalori,
      'protein': protein,
      'karbonhidrat': karbonhidrat,
      'yag': yag,
      'malzemeler': malzemeler,
      'alternatifler': alternatifler.map((a) => a.toJson()).toList(),
      'hazirlamaSuresi': hazirlamaSuresi,
      'zorluk': zorluk.name,
      'etiketler': etiketler,
      'tarif': tarif,
      'gorselUrl': gorselUrl,
      'proteinKaynagi': proteinKaynagi,
      // ✅ YENİ ALANLAR
      'baseWeightG': baseWeightG,
      'dominantMacro': dominantMacro,
      'minMultiplier': minMultiplier,
      'maxMultiplier': maxMultiplier,
      'unitName': unitName,
    };
  }

  /// String'den OgunTipi enum'a evir (public for YemekModel)
  static OgunTipi ogunTipiFromString(String ogun) {
    switch (ogun.toLowerCase()) {
      case 'kahvalti':
      case 'kahvalt1':
        return OgunTipi.kahvalti;
      case 'araogun1':
      case 'ara_ogun_1':
      case 'ara öğün 1':
      case 'ara1':
        return OgunTipi.araOgun1;
      case 'ogle':
      case 'öğle':
      case 'öğle yemeği':
        return OgunTipi.ogle;
      case 'araogun2':
      case 'ara_ogun_2':
      case 'ara öğün 2':
      case 'ara2':  // 🔥 FIX: JSON'daki "ara2" desteği eklendi
        return OgunTipi.araOgun2;
      case 'aksam':
      case 'akşam':
      case 'akşam yemeği':
        return OgunTipi.aksam;
      case 'geceatistirma':
      case 'gece_atistirma':
      case 'gece_atistirmasi': // 🔥 FIX: DB'den gelen hatal1 format eklendi
      case 'gece atıştırma':
      case 'gece atıştırmas1':
      case 'gece atistirmasi':
        return OgunTipi.geceAtistirma;
      case 'cheatmeal':
      case 'cheat_meal':
      case 'cheat meal':
        return OgunTipi.cheatMeal;
      case 'bulk':
      case 'clean bulk': // 🔥 DB'deki "Clean Bulk" kategorisi iin eklendi
      case 'ana_yemek':
      case 'ana yemek':
        return OgunTipi.aksam; // Bulk yemekleri akşam kategorisine ata
      case 'zayıflama':
      case 'zayiflama':
      case 'diet': // 🔥 Zayıflama yemekleri ara öğün kategorisine ata (düşük kalorili)
        return OgunTipi.araOgun1;
      default:
        throw Exception('Bilinmeyen öğün tipi: $ogun');
    }
  }

  /// String'den Zorluk enum'a evir (public for YemekModel)
  static Zorluk zorlukFromString(String zorluk) {
    switch (zorluk.toLowerCase()) {
      case 'kolay':
        return Zorluk.kolay;
      case 'orta':
        return Zorluk.orta;
      case 'zor':
        return Zorluk.zor;
      default:
        throw Exception('Bilinmeyen zorluk seviyesi: $zorluk');
    }
  }

  /// Makrolara uygunluk kontrolü
  bool makroyaUygunMu(MakroHedefleri hedefler, double tolerans) {
    // Günlük hedefin 1/5'i (5 öğün varsayım1)
    final hedefKalori = hedefler.gunlukKalori / 5;
    final kaloriFark = (kalori - hedefKalori).abs();

    return kaloriFark <= hedefKalori * tolerans;
  }

  /// 🔥 FIX: Akıll1 alerji eşleştirme sistemi
  /// Kısıtlamalara uygunluk kontrolü (alerji, vegan vb)
  bool kisitlamayaUygunMu(List<String> kisitlamalar) {
    if (kisitlamalar.isEmpty) return true;

    for (final kisitlama in kisitlamalar) {
      final kisitlamaLower = kisitlama.toLowerCase().trim();

      // 1️⃣ Alerji grubu kontrolü (örn: "balık" alerjisi -> somon, ton, levrek...)
      if (_alerjiGruplari.containsKey(kisitlamaLower)) {
        final allerjenler = _alerjiGruplari[kisitlamaLower]!;
        
        // Yemek adında allerjen var m1?
        for (final allerjen in allerjenler) {
          if (ad.toLowerCase().contains(allerjen)) {
            return false;
          }
        }
        
        // Malzemelerde allerjen var m1?
        for (final malzeme in malzemeler) {
          final malzemeLower = malzeme.toLowerCase();
          for (final allerjen in allerjenler) {
            if (malzemeLower.contains(allerjen)) {
              return false;
            }
          }
        }
      }

      // 2️⃣ Direkt kelime eşleştirme (yemek adında)
      if (ad.toLowerCase().contains(kisitlamaLower)) {
        return false;
      }

      // 3️⃣ Direkt kelime eşleştirme (malzemelerde)
      if (malzemeler.any((m) => m.toLowerCase().contains(kisitlamaLower))) {
        return false;
      }

      // 4️⃣ Etiket kontrolü (örn: vegan değil ise et yasak)
      if (kisitlamaLower == 'et' && !etiketler.contains('vejetaryen')) {
        return false;
      }
    }

    return true;
  }

  /// Tercih uygunluğu kontrolü (pozitif filtre)
  bool tercihUygunMu(List<String> tercihler) {
    if (tercihler.isEmpty) return true;

    for (final tercih in tercihler) {
      final tercihLower = tercih.toLowerCase();

      // Malzemelerde veya etiketlerde var m1?
      if (malzemeler.any((m) => m.toLowerCase().contains(tercihLower)) ||
          etiketler.any((e) => e.toLowerCase().contains(tercihLower))) {
        return true;
      }
    }

    return false;
  }

  /// Toplam makro (protein + karb + yağ)
  double get toplamMakro => protein + karbonhidrat + yag;

  /// Protein yüzdesi
  double get proteinYuzdesi => (protein * 4 / kalori) * 100;

  /// Karbonhidrat yüzdesi
  double get karbonhidratYuzdesi => (karbonhidrat * 4 / kalori) * 100;

  /// Yağ yüzdesi
  double get yagYuzdesi => (yag * 9 / kalori) * 100;

  /// Yemek aıklamas1 (kısa özet)
  String get kisaOzet {
    return '$ad - ${kalori.toInt()} kcal | P: ${protein.toInt()}g | K: ${karbonhidrat.toInt()}g | Y: ${yag.toInt()}g';
  }

  /// String adına göre makro değerini döndürür.
  double makroDegeri(String makroAdi) {
    switch (makroAdi) {
      case 'kalori':
        return kalori;
      case 'protein':
        return protein;
      case 'karb':
      case 'karbonhidrat':
        return karbonhidrat;
      case 'yag':
        return yag;
      default:
        return 0.0;
    }
  }

  /// 📏 Yemeği belirtilen arpanla öleklendirir
  /// Örnek: multiplier = 1.5 → 150 gram, kalori/protein/karb/yag × 1.5
  ///
  /// Kullanım:
  /// ```dart
  /// final buyukPorsiyon = yemek.scale(1.5); // %50 daha büyük
  /// final kucukPorsiyon = yemek.scale(0.7); // %30 daha küük
  /// ```
  Yemek scale(double multiplier) {
    if (multiplier < minMultiplier || multiplier > maxMultiplier) {
      throw ArgumentError(
        'Multiplier $multiplier, min=$minMultiplier, max=$maxMultiplier dışında'
      );
    }
    
    // Malzemeleri de çekip (varsa sayısal değerleri) çarpıp güncelleyebiliriz
    // Şu anki yapıda "malzeme (100g)" formatındaysa sayıyı çarpmalıyız. Ekstra geliştirme:
    final scaledMalzemeler = malzemeler.map((m) {
      // Önce kesirli formatları kontrol et (ör: "1/2 adet Avokado")
      final RegExp fractionRegExp = RegExp(r'^([0-9]+)/([0-9]+)\s*(.*)');
      final fractionMatch = fractionRegExp.firstMatch(m.trim());
      
      if (fractionMatch != null) {
        final num1 = double.tryParse(fractionMatch.group(1) ?? '');
        final num2 = double.tryParse(fractionMatch.group(2) ?? '');
        final rest = fractionMatch.group(3) ?? '';
        
        if (num1 != null && num2 != null && num2 != 0) {
          final double scaledAmount = (num1 / num2) * multiplier;
          final String formattedAmount = (scaledAmount % 1 == 0 || (scaledAmount - scaledAmount.round()).abs() < 0.1)
              ? scaledAmount.round().toString()
              : scaledAmount.toStringAsFixed(1);
          return '$formattedAmount $rest'.trim();
        }
      }

      // "2 adet Yumurta", "80g Yulaf", "1.5 dilim Ekmek" gibi formatlardaki sayısal kısmı çarp
      final RegExp regExp = RegExp(r'^([0-9]+([.,][0-9]+)?)\s*(.*)');
      final match = regExp.firstMatch(m.trim());
      
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '.');
        final rest = match.group(3) ?? '';
        
        if (amountStr != null) {
          final double? originalAmount = double.tryParse(amountStr);
          if (originalAmount != null) {
            final double scaledAmount = originalAmount * multiplier;
            
            // Eğer tam sayıya çok yakınsa (ör: 2.001) tam sayı olarak göster
            final String formattedAmount = (scaledAmount % 1 == 0 || (scaledAmount - scaledAmount.round()).abs() < 0.1)
                ? scaledAmount.round().toString()
                : scaledAmount.toStringAsFixed(1);
                
            return '$formattedAmount $rest'.trim();
          }
        }
      }
      return m; 
    }).toList();

    return Yemek(
      id: id,
      ad: ad,
      ogun: ogun,
      kalori: kalori * multiplier,
      protein: protein * multiplier,
      karbonhidrat: karbonhidrat * multiplier,
      yag: yag * multiplier,
      baseWeightG: baseWeightG * multiplier,
      malzemeler: scaledMalzemeler,
      alternatifler: alternatifler,
      alternatifYemekler: alternatifYemekler,
      hazirlamaSuresi: hazirlamaSuresi,
      zorluk: zorluk,
      etiketler: etiketler,
      tarif: tarif,
      gorselUrl: gorselUrl,
      proteinKaynagi: proteinKaynagi,
      dominantMacro: dominantMacro, // Öleklendirme değiştirmez
      minMultiplier: minMultiplier,
      maxMultiplier: maxMultiplier,
      unitName: unitName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ad,
        ogun,
        kalori,
        protein,
        karbonhidrat,
        yag,
        malzemeler,
        alternatifler,
        alternatifYemekler,
        hazirlamaSuresi,
        zorluk,
        etiketler,
        tarif,
        gorselUrl,
        proteinKaynagi,
        // ✅ YENİ ALANLAR
        baseWeightG,
        dominantMacro,
        minMultiplier,
        maxMultiplier,
        unitName,
      ];

  /// Copy with
  Yemek copyWith({
    String? id,
    String? ad,
    OgunTipi? ogun,
    double? kalori,
    double? protein,
    double? karbonhidrat,
    double? yag,
    List<String>? malzemeler,
    List<AlternatifBesin>? alternatifler,
    List<Yemek>? alternatifYemekler,
    int? hazirlamaSuresi,
    Zorluk? zorluk,
    List<String>? etiketler,
    String? tarif,
    String? gorselUrl,
    String? proteinKaynagi,
    // ✅ YENİ ALANLAR
    double? baseWeightG,
    String? dominantMacro,
    double? minMultiplier,
    double? maxMultiplier,
    String? unitName,
  }) {
    return Yemek(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      ogun: ogun ?? this.ogun,
      kalori: kalori ?? this.kalori,
      protein: protein ?? this.protein,
      karbonhidrat: karbonhidrat ?? this.karbonhidrat,
      yag: yag ?? this.yag,
      malzemeler: malzemeler ?? this.malzemeler,
      alternatifler: alternatifler ?? this.alternatifler,
      alternatifYemekler: alternatifYemekler ?? this.alternatifYemekler,
      hazirlamaSuresi: hazirlamaSuresi ?? this.hazirlamaSuresi,
      zorluk: zorluk ?? this.zorluk,
      etiketler: etiketler ?? this.etiketler,
      tarif: tarif ?? this.tarif,
      gorselUrl: gorselUrl ?? this.gorselUrl,
      proteinKaynagi: proteinKaynagi ?? this.proteinKaynagi,
      // ✅ YENİ ALANLAR
      baseWeightG: baseWeightG ?? this.baseWeightG,
      dominantMacro: dominantMacro ?? this.dominantMacro,
      minMultiplier: minMultiplier ?? this.minMultiplier,
      maxMultiplier: maxMultiplier ?? this.maxMultiplier,
      unitName: unitName ?? this.unitName,
    );
  }
}

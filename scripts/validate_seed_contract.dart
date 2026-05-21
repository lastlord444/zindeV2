import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) async {
  final strict = arguments.contains('--strict');
  
  // 1. Dosyayı oku
  final file = File('supabase/migrations/002_insert_meals_data.sql');
  if (!await file.exists()) {
    print('Hata: supabase/migrations/002_insert_meals_data.sql dosyası bulunamadı!');
    exit(1);
  }
  
  final lines = await file.readAsLines();
  
  // Parantez içindeki verileri parse eden regex
  // ('meal_id', 'ad', 'ogun', kcal, protein, carb, fat, 'malzemeler'::JSONB, ...)
  final regex = RegExp(
    r"\(\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*'([^']+)'::JSONB"
  );
  
  final meals = <Meal>[];
  var parseErrors = 0;
  
  for (var line in lines) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('(')) continue;
    
    final match = regex.firstMatch(trimmed);
    if (match == null) {
      continue;
    }
    
    try {
      final id = match.group(1)!;
      final name = match.group(2)!;
      final ogun = match.group(3)!;
      final kcal = double.parse(match.group(4)!);
      final protein = double.parse(match.group(5)!);
      final carb = double.parse(match.group(6)!);
      final fat = double.parse(match.group(7)!);
      final ingredientsRaw = match.group(8)!;
      
      final List<dynamic> ingredientsJson = jsonDecode(ingredientsRaw);
      final ingredients = ingredientsJson.map((e) => e.toString().trim()).toList();
      
      meals.add(Meal(
        id: id,
        name: name,
        ogun: ogun,
        kcal: kcal,
        protein: protein,
        carb: carb,
        fat: fat,
        ingredients: ingredients,
      ));
    } catch (e) {
      parseErrors++;
    }
  }
  
  print('=== SEED VERİ DOĞRULAMA RAPORU ===');
  print('Toplam Okunan Satır: ${lines.length}');
  print('Başarıyla Parse Edilen Yemek Sayısı: ${meals.length}');
  if (parseErrors > 0) {
    print('Parse Edilemeyen Satır Sayısı: $parseErrors');
  }
  print('--------------------------------------------------');
  
  // 2. Makro Doğrulaması (kcal = protein * 4 + carb * 4 + fat * 9)
  final macroViolations = <MacroViolation>[];
  for (final meal in meals) {
    final calculatedKcal = meal.protein * 4 + meal.carb * 4 + meal.fat * 9;
    final diff = (calculatedKcal - meal.kcal).abs();
    
    // ±10 kcal veya %5 tolerans
    final pctDiff = meal.kcal > 0 ? (diff / meal.kcal) : 0.0;
    final isWithinTolerance = diff <= 10.0 || pctDiff <= 0.05;
    
    if (!isWithinTolerance) {
      macroViolations.add(MacroViolation(
        meal: meal,
        calculatedKcal: calculatedKcal,
        diff: diff,
        pctDiff: pctDiff * 100,
      ));
    }
  }
  
  print('MAKRO DOĞRULAMA (kcal = P*4 + C*4 + F*9):');
  print('Tolerans Limitleri: ±10 kcal VEYA %5 oransal fark');
  print('Hatalı/Uyumsuz Yemek Sayısı: ${macroViolations.length}');
  if (macroViolations.isNotEmpty) {
    print('\n[UYARI/HATA] Tolerans Dışı Makro Değerine Sahip Yemekler (İlk 15):');
    for (var i = 0; i < macroViolations.length && i < 15; i++) {
      final v = macroViolations[i];
      print('- [${v.meal.id}] ${v.meal.name} (${v.meal.ogun}): '
          'Kayıtlı: ${v.meal.kcal} kcal | Hesaplanan: ${v.calculatedKcal.toStringAsFixed(1)} kcal '
          '(Fark: ${v.diff.toStringAsFixed(1)} kcal, %${v.pctDiff.toStringAsFixed(1)}) '
          '[P: ${v.meal.protein}g, C: ${v.meal.carb}g, F: ${v.meal.fat}g]');
    }
    if (macroViolations.length > 15) {
      print('... ve diğer ${macroViolations.length - 15} yemek.');
    }
  } else {
    print('Tüm yemeklerin makro değerleri tolerans limitleri dahilinde.');
  }
  print('--------------------------------------------------');
  
  // 3. Malzeme Bazlı Gruplama ve Sapma Analizi
  final groupedMeals = <String, List<Meal>>{};
  for (final meal in meals) {
    // Malzemeleri normalize et (küçük harf yap, sırala, araya virgül koy)
    final sortedIngredients = meal.ingredients.map((e) => e.toLowerCase()).toList()..sort();
    final key = sortedIngredients.join('|');
    groupedMeals.putIfAbsent(key, () => []).add(meal);
  }
  
  final duplicateGroups = groupedMeals.entries.where((e) => e.value.length > 1).toList();
  print('MALZEME BAZLI GRUPLAMA:');
  print('Toplam Benzersiz Malzeme Kombinasyonu: ${groupedMeals.length}');
  print('Birden Fazla Yemekte Kullanılan Malzeme Kombinasyonu (Grup): ${duplicateGroups.length}');
  
  final anomalies = <MaterialGroupAnomaly>[];
  
  for (final entry in duplicateGroups) {
    final groupMeals = entry.value;
    
    // Değer aralıklarını hesapla
    var minP = double.infinity;
    var maxP = -double.infinity;
    var minC = double.infinity;
    var maxC = -double.infinity;
    var minF = double.infinity;
    var maxF = -double.infinity;
    var minK = double.infinity;
    var maxK = -double.infinity;
    
    for (final meal in groupMeals) {
      if (meal.protein < minP) minP = meal.protein;
      if (meal.protein > maxP) maxP = meal.protein;
      if (meal.carb < minC) minC = meal.carb;
      if (meal.carb > maxC) maxC = meal.carb;
      if (meal.fat < minF) minF = meal.fat;
      if (meal.fat > maxF) maxF = meal.fat;
      if (meal.kcal < minK) minK = meal.kcal;
      if (meal.kcal > maxK) maxK = meal.kcal;
    }
    
    final diffP = maxP - minP;
    final diffC = maxC - minC;
    final diffF = maxF - minF;
    final diffK = maxK - minK;
    
    // Sapma kriterleri:
    // Protein, Carb veya Fat farkı > 15g ise VEYA Kcal farkı > 150 kcal ise bu bir ANOMALİDİR.
    final isPAnomaly = diffP > 15.0;
    final isCAnomaly = diffC > 15.0;
    final isFAnomaly = diffF > 15.0;
    final isKAnomaly = diffK > 150.0;
    
    if (isPAnomaly || isCAnomaly || isFAnomaly || isKAnomaly) {
      anomalies.add(MaterialGroupAnomaly(
        ingredients: groupMeals.first.ingredients,
        meals: groupMeals,
        minP: minP,
        maxP: maxP,
        minC: minC,
        maxC: maxC,
        minF: minF,
        maxF: maxF,
        minK: minK,
        maxK: maxK,
        diffP: diffP,
        diffC: diffC,
        diffF: diffF,
        diffK: diffK,
      ));
    }
  }
  
  print('Makro Sapma Eşikleri: Protein/Karb/Yağ farkı > 15g VEYA Enerji farkı > 150 kcal');
  print('Tespit Edilen Aşırı Sapmalı Grup Sayısı: ${anomalies.length}');
  
  if (anomalies.isNotEmpty) {
    print('\n[UYARI/HATA] Aynı Malzemelerle Çok Farklı Makro/Kcal Değerleri Olan Gruplar:');
    for (final anomaly in anomalies) {
      final sampleMeal = anomaly.meals.first;
      final mealNames = anomaly.meals.map((m) => m.name).toSet().join(', ');
      
      // Pankek gibi özel durumları belirtmek için kontrol
      final isPankek = sampleMeal.name.toLowerCase().contains('pankek') || 
                       anomaly.ingredients.any((ing) => ing.toLowerCase().contains('pankek') || ing.toLowerCase().contains('yulaf unu'));
      
      print('\n- Malzemeler: ${anomaly.ingredients.join(', ')}');
      print('  Yemek Adları: $mealNames');
      print('  Yemek Sayısı: ${anomaly.meals.length}');
      print('  Protein Aralığı: ${anomaly.minP.toStringAsFixed(1)}g - ${anomaly.maxP.toStringAsFixed(1)}g (Fark: ${anomaly.diffP.toStringAsFixed(1)}g)${anomaly.diffP > 15.0 ? " [AŞIRI]" : ""}');
      print('  Karb Aralığı   : ${anomaly.minC.toStringAsFixed(1)}g - ${anomaly.maxC.toStringAsFixed(1)}g (Fark: ${anomaly.diffC.toStringAsFixed(1)}g)${anomaly.diffC > 15.0 ? " [AŞIRI]" : ""}');
      print('  Yağ Aralığı    : ${anomaly.minF.toStringAsFixed(1)}g - ${anomaly.maxF.toStringAsFixed(1)}g (Fark: ${anomaly.diffF.toStringAsFixed(1)}g)${anomaly.diffF > 15.0 ? " [AŞIRI]" : ""}');
      print('  Kalori Aralığı : ${anomaly.minK.toStringAsFixed(1)} kcal - ${anomaly.maxK.toStringAsFixed(1)} kcal (Fark: ${anomaly.diffK.toStringAsFixed(1)} kcal)${anomaly.diffK > 150.0 ? " [AŞIRI]" : ""}');
      
      if (isPankek) {
        print('  >>> [ÖZEL VURGU] Fit Pankek / Yulaf Unlu tarif grubunda aşırı sapma tespit edilmiştir.');
      }
    }
  }
  
  print('--------------------------------------------------');
  
  // 4. Çıkış Değerlendirmesi
  final hasErrors = macroViolations.isNotEmpty || anomalies.isNotEmpty;
  if (strict) {
    if (hasErrors) {
      print('HATA: --strict modu aktif ve veri uyumsuzlukları bulundu!');
      exit(1);
    } else {
      print('BAŞARILI: --strict modu aktif, hiçbir uyumsuzluk bulunmadı.');
      exit(0);
    }
  } else {
    print('BAŞARILI: Raporlama tamamlandı.');
    exit(0);
  }
}

class Meal {
  final String id;
  final String name;
  final String ogun;
  final double kcal;
  final double protein;
  final double carb;
  final double fat;
  final List<String> ingredients;

  Meal({
    required this.id,
    required this.name,
    required this.ogun,
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
    required this.ingredients,
  });
}

class MacroViolation {
  final Meal meal;
  final double calculatedKcal;
  final double diff;
  final double pctDiff;

  MacroViolation({
    required this.meal,
    required this.calculatedKcal,
    required this.diff,
    required this.pctDiff,
  });
}

class MaterialGroupAnomaly {
  final List<String> ingredients;
  final List<Meal> meals;
  final double minP;
  final double maxP;
  final double minC;
  final double maxC;
  final double minF;
  final double maxF;
  final double minK;
  final double maxK;
  final double diffP;
  final double diffC;
  final double diffF;
  final double diffK;

  MaterialGroupAnomaly({
    required this.ingredients,
    required this.meals,
    required this.minP,
    required this.maxP,
    required this.minC,
    required this.maxC,
    required this.minF,
    required this.maxF,
    required this.minK,
    required this.maxK,
    required this.diffP,
    required this.diffC,
    required this.diffF,
    required this.diffK,
  });
}

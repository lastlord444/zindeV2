import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Gerekli class'ları import etmek yerine karmaşayı azaltmak için 
// GenerateDailyPlan mantığı test edilecek.
// ZindeV.2.0 klasöründe olduğumuz için direkt projeden import edelim.
import 'lib/domain/entities/nutrition/yemek.dart';
import 'lib/domain/entities/nutrition/makro_hedefleri.dart';
import 'lib/domain/usecases/meal_planning/generate_daily_plan.dart';
import 'lib/domain/entities/user/hedef.dart';

// Manuel fetch DB meals
Future<List<Yemek>> fetchMeals() async {
  final url = Uri.parse('http://127.0.0.1:54331/rest/v1/meals?select=*');
  final response = await http.get(url, headers: {
    'apikey': 'eyJhbGciOiJFUzI1NiIsImtpZCI6ImI4MTI2OWYxLTIxZDgtNGYyZS1iNzE5LWMyMjQwYTg0MGQ5MCIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MjA4NzkzOTA3MH0.TBTkRdFT0oJl7XmlpWKPPyOAFrLhMMyEhmoTIQZawKTlbIAYGfkagRpr25Cae81pPwDDpGaWak4FhZJWP-52uw',
  });

  if (response.statusCode != 200) {
    throw Exception('Failed to load meals');
  }

  final List<dynamic> data = json.decode(response.body);
  return data.map((json) => Yemek.fromJson(json)).toList();
}

void main() async {
  print("Yemekler Supabase'den çekiliyor...");
  final meals = await fetchMeals();
  print("Toplam ${meals.length} yemek çekildi.");

  final usecase = GenerateDailyPlan();
  
  // Örnek zorlu bir hedef (Kilo Alma - Bulk)
  // 5 Öğünlü dağılım olacak
  final hedefler = MakroHedefleri(
    gunlukKalori: 2800,
    gunlukProtein: 160,
    gunlukKarbonhidrat: 350,
    gunlukYag: 84, // 160*4 + 350*4 + 84*9 = 640 + 1400 + 756 = 2796 ~ 2800
  );

  print("\n=== HEDEF MAKROLAR ===");
  print("Kalori: 2800 kcal");
  print("Protein: 160.0 g");
  print("Karbonhidrat: 350.0 g");
  print("Yağ: 84.0 g");
  print("======================\n");

  print("Algoritma çalıştırılıyor (Matrix/Cramer Rule)...");
  
  final result = await usecase.call(
    planId: 'test_plan_1',
    userId: 'test_user',
    tarih: DateTime.now(),
    hedefler: hedefler,
    yemekHavuzu: meals,
    hedef: 'bulk', 
    kisitlamalar: [],
  );

  result.fold(
    (failure) => print("HATA: \${failure.message}"),
    (plan) {
      print("\n✅ OLUŞTURULAN PLAN BAŞARILI!");
      
      final ogunler = {
        'Kahvaltı': plan.kahvalti,
        'Ara Öğün 1': plan.araOgun1,
        'Öğle Yemeği': plan.ogleYemegi,
        'Ara Öğün 2': plan.araOgun2,
        'Akşam Yemeği': plan.aksamYemegi,
        'Gece Atıştırması': plan.geceAtistirma,
      };

      for (var entry in ogunler.entries) {
        if (entry.value != null) {
          final ogun = entry.value!;
          print("\n[\${entry.key}] - \${ogun.ad}");
          print("Makrolar: \${ogun.kalori.toStringAsFixed(1)} kcal | P: \${ogun.protein.toStringAsFixed(1)}g | C: \${ogun.karbonhidrat.toStringAsFixed(1)}g | Y: \${ogun.yag.toStringAsFixed(1)}g");
          print("Malzemeler:");
          for (var m in ogun.malzemeler) {
            print("  - \$m");
          }
        }
      }

      print("\n=== FINAL TEST SONUCU (TOTAL MAKROLAR) ===");
      print("Kalori: \${plan.toplamKalori.toStringAsFixed(1)} kcal");
      print("Protein: \${plan.toplamProtein.toStringAsFixed(1)} g");
      print("Karbonhidrat: \${plan.toplamKarbonhidrat.toStringAsFixed(1)} g");
      print("Yağ: \${plan.toplamYag.toStringAsFixed(1)} g");
      
      print("\nSAPIŞ MİKTARLARI (TOLERANS):");
      print("Kalori Fark: \${(plan.toplamKalori - hedefler.gunlukKalori).toStringAsFixed(2)}");
      print("Protein Fark: \${(plan.toplamProtein - hedefler.gunlukProtein).toStringAsFixed(2)}");
      print("Karb Fark: \${(plan.toplamKarbonhidrat - hedefler.gunlukKarbonhidrat).toStringAsFixed(2)}");
      print("Yağ Fark: \${(plan.toplamYag - hedefler.gunlukYag).toStringAsFixed(2)}");
    }
  );
}

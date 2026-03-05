import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../lib/domain/entities/nutrition/yemek.dart';
import '../lib/domain/entities/nutrition/makro_hedefleri.dart';
import '../lib/domain/usecases/meal_planning/generate_daily_plan.dart';

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

void main() {
  test('Test Matrix Generator Accuracy', () async {
    final logFile = File('matrix_result.txt');
    var sink = logFile.openWrite();
    
    void log(String msg) {
      sink.writeln(msg);
      print(msg);
    }

    log("Yemekler Supabase'den cekiliyor...");
    final meals = await fetchMeals();
    log("Toplam " + meals.length.toString() + " yemek cekildi.");

    final usecase = GenerateDailyPlan();
    
    final hedefler = MakroHedefleri(
      gunlukKalori: 2800,
      gunlukProtein: 160,
      gunlukKarbonhidrat: 350,
      gunlukYag: 84, // 160*4 + 350*4 + 84*9 = 2796
    );

    log("\n=== HEDEF MAKROLAR ===");
    log("Kalori: 2800 kcal");
    log("Protein: 160.0 g");
    log("Karbonhidrat: 350.0 g");
    log("Yag: 84.0 g");
    log("======================\n");

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
      (failure) => log("Plan olusturulamadi: " + failure.message),
      (plan) {
        log("\n OLUstURULAN PLAN BAsARILI!");
        
        final ogunler = {
          'Kahvalti': plan.kahvalti,
          'Ara Ogun 1': plan.araOgun1,
          'Ogle Yemegi': plan.ogleYemegi,
          'Ara Ogun 2': plan.araOgun2,
          'Aksam Yemegi': plan.aksamYemegi,
          'Gece Atistirmasi': plan.geceAtistirma,
        };

        for (var entry in ogunler.entries) {
          if (entry.value != null) {
            final ogun = entry.value!;
            log("\n[" + entry.key + "]");
            log("Ad: " + ogun.ad);
            log("Makrolar: " + ogun.kalori.toStringAsFixed(1) + " kcal | P: " + ogun.protein.toStringAsFixed(1) + "g | C: " + ogun.karbonhidrat.toStringAsFixed(1) + "g | Y: " + ogun.yag.toStringAsFixed(1) + "g");
            log("Malzemeler:");
            for (var m in ogun.malzemeler) {
              log("  - " + m);
            }
          }
        }

        log("\n=== FINAL TEST SONUCU (TOTAL MAKROLAR) ===");
        log("Kalori: " + plan.toplamKalori.toStringAsFixed(1) + " kcal");
        log("Protein: " + plan.toplamProtein.toStringAsFixed(1) + " g");
        log("Karbonhidrat: " + plan.toplamKarbonhidrat.toStringAsFixed(1) + " g");
        log("Yag: " + plan.toplamYag.toStringAsFixed(1) + " g");
        
        log("\nSAPIc MIKTARLARI (TOLERANS):");
        final kaloriFark = (plan.toplamKalori - hedefler.gunlukKalori).abs();
        final proteinFark = (plan.toplamProtein - hedefler.gunlukProtein).abs();
        final karbFark = (plan.toplamKarbonhidrat - hedefler.gunlukKarbonhidrat).abs();
        final yagFark = (plan.toplamYag - hedefler.gunlukYag).abs();
        
        log("Kalori Fark: " + kaloriFark.toStringAsFixed(2));
        log("Protein Fark: " + proteinFark.toStringAsFixed(2));
        log("Karb Fark: " + karbFark.toStringAsFixed(2));
        log("Yag Fark: " + yagFark.toStringAsFixed(2));
      }
    );
    await sink.flush();
    await sink.close();
  });
}

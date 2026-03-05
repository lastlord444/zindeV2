// lib/domain/usecases/user/calculate_macros.dart

import '../../../core/config/nutrition_constraints.dart';
import '../../entities/user/kullanici_profili.dart';
import '../../entities/user/hedef.dart';
import '../../entities/nutrition/makro_hedefleri.dart';

/// Makro hesaplama use case'i
/// Mifflin-St Jeor formülü kullanır
class CalculateMacros {
  /// Kullanıc1 profiline göre günlük makro hedeflerini hesapla
  MakroHedefleri call(KullaniciProfili profil) {
    // 1. BMR hesapla
    final bmr = NutritionConstraints.bmrHesapla(
      kilo: profil.mevcutKilo,
      boy: profil.boy,
      yas: profil.yas,
      erkekMi: profil.cinsiyet == Cinsiyet.erkek,
    );

    // 2. TDEE hesapla
    final tdee = NutritionConstraints.tdeeHesapla(
      bmr,
      profil.aktiviteSeviyesi.name,
    );

    // 3. Hedef bazl1 kalori
    final gunlukKalori = NutritionConstraints.gunlukKaloriHesapla(
      tdee,
      profil.hedef.name,
    );

    // 4. Hedef kilo (varsa onu kullan, yoksa mevcut kilo)
    final hedefKilo = profil.hedefKilo ?? profil.mevcutKilo;

    // 5. Makrolar1 hesapla
    final protein = NutritionConstraints.proteinHesapla(hedefKilo);
    final yag = NutritionConstraints.yagHesapla(gunlukKalori);
    final karbonhidrat = NutritionConstraints.karbonhidratHesapla(
      gunlukKalori,
      protein,
      yag,
    );

    return MakroHedefleri(
      gunlukKalori: gunlukKalori,
      gunlukProtein: protein,
      gunlukKarbonhidrat: karbonhidrat,
      gunlukYag: yag,
    );
  }
}

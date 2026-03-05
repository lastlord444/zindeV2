---
description: ZindeAI V2.0 Clean Architecture teknik referansı - halüsinasyonu engeller, doğru yapıyı garantiler
---

# ZindeAI V2.0 - Mimari Referans Skill

> ⚠️ BU DOSYAYI HER KODLAMA OTURUMUNDA ÖNCE OKU. Halüsinasyonu önlemek için bu referansı kullan.

## 📁 Proje Yapısı

```
d:\zindeV.2.0\
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart
│   │   │   └── supabase_config.dart
│   │   ├── di/
│   │   │   └── injection_container.dart      # get_it + injectable
│   │   ├── errors/
│   │   │   ├── failures.dart
│   │   │   └── exceptions.dart
│   │   ├── network/
│   │   │   ├── api_client.dart               # Dio wrapper
│   │   │   └── network_info.dart
│   │   └── utils/
│   │       ├── logger.dart                   # WEB-SAFE logger
│   │       ├── validators.dart
│   │       └── formatters.dart
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── user/
│   │   │   │   ├── kullanici_profili.dart    # TEMEL ENTITY
│   │   │   │   └── hedef.dart               # Cinsiyet, AktiviteSeviyesi, Hedef, DiyetTipi enum'ları
│   │   │   ├── nutrition/
│   │   │   │   ├── yemek.dart               # OgunTipi, Zorluk enum + Yemek entity
│   │   │   │   ├── gunluk_plan.dart
│   │   │   │   ├── makro_hedefleri.dart
│   │   │   │   ├── yemek_onay_sistemi.dart   # YemekDurumu, YemekOnaySistemi
│   │   │   │   └── alternatif_besin.dart
│   │   │   ├── workout/
│   │   │   │   ├── egzersiz.dart
│   │   │   │   └── antrenman_plani.dart
│   │   │   └── analytics/
│   │   │       ├── haftalik_rapor.dart
│   │   │       └── alisveris_listesi.dart
│   │   ├── repositories/
│   │   │   ├── user_repository.dart
│   │   │   ├── meal_repository.dart
│   │   │   ├── meal_plan_repository.dart
│   │   │   ├── workout_repository.dart
│   │   │   └── analytics_repository.dart
│   │   └── usecases/
│   │       ├── user/
│   │       ├── meal_planning/
│   │       ├── workout/
│   │       └── analytics/
│   │
│   ├── data/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── datasources/
│   │   │   ├── remote/
│   │   │   └── local/
│   │   └── mappers/
│   │
│   └── presentation/
│       ├── bloc/
│       │   ├── home/
│       │   ├── profil/
│       │   ├── meal_planning/
│       │   ├── workout/
│       │   ├── chatbot/
│       │   └── analytics/
│       ├── pages/        # ← DOKUNMA! UI korunacak
│       └── widgets/      # ← DOKUNMA! UI korunacak
```

## 📦 Paketler (pubspec.yaml)

```yaml
dependencies:
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  get_it: ^7.6.4
  injectable: ^2.3.2
  supabase_flutter: ^2.6.0
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  dio: ^5.4.0
  http: ^1.1.2
  dartz: ^0.10.1
  uuid: ^4.3.3
  intl: ^0.18.1
  logger: ^2.0.2+1
  collection: ^1.18.0
  shimmer: ^3.0.0
  table_calendar: ^3.0.9
  internet_connection_checker: ^1.0.0
```

## 🎯 Temel Entity'ler (V1'den referans - DEĞİŞTİRME)

### KullaniciProfili alanları:
```
id, ad, soyad, yas, boy(cm), mevcutKilo(kg), hedefKilo?,
cinsiyet, aktiviteSeviyesi, hedef, diyetTipi,
manuelAlerjiler(List<String>), kayitTarihi
```

### Yemek alanları:
```
id, ad, ogun(OgunTipi), kalori, protein, karbonhidrat, yag,
malzemeler(List<String>), alternatifler(List<AlternatifBesin>),
hazirlamaSuresi(int, dakika), zorluk(Zorluk), etiketler, tarif?,
gorselUrl?, proteinKaynagi?,
baseWeightG(double=100), dominantMacro(String), 
minMultiplier(double=0.5), maxMultiplier(double=3.0), unitName(String='gram')
```

### OgunTipi enum değerleri:
```dart
kahvalti, araOgun1, ogle, araOgun2, aksam, geceAtistirma, cheatMeal
```

### Hedef enum değerleri: `bulk, cut, maintain`
### Cinsiyet enum değerleri: `erkek, kadin`
### AktiviteSeviyesi: `sedanter, hafifAktif, ortaAktif, cokAktif, atletik`
### DiyetTipi: `normal, vejetaryen, vegan, glutensiz, laktozsuz`
### Zorluk: `kolay, orta, zor`

## ⚡ Tolerans Sistemi (KRİTİK)

```dart
// lib/core/config/nutrition_constraints.dart
static const double calorieTolerancePct = 0.10;  // ±%10
static const double macroTolerancePct   = 0.10;  // ±%10
static const double mealTolerancePct    = 0.20;  // ±%20 öğün başına

// Hedef bazlı öğün sayıları:
// bulk → 6 öğün, maintain → 5 öğün, cut → 4 öğün
```

## 🔄 BLoC Event/State Sözlüğü

### HomeBloc Events (BUNLARI KULLLAN):
```
LoadHomePage, LoadPlanByDate(DateTime), RefreshDailyPlan(bool forceRegenerate),
GenerateWeeklyPlan(bool forceRegenerate), MarkMealAsEaten(String yemekId),
SkipMeal(String yemekId), ConfirmMealEaten(String yemekId),
ResetMealStatus(String yemekId), GenerateAlternativeMeals(Yemek, int sayi),
ReplaceMealWith(Yemek eski, Yemek yeni), GenerateIngredientAlternatives(...),
ReplaceIngredientWith(...), CancelAlternativeSelection, CancelAlternativeMealSelection
```

### HomeBloc States:
```
HomeInitial, HomeLoading(progress, message), HomeLoaded(plan, hedefler, tamamlanan),
AlternativeIngredientsLoaded, HomeError
```

### AntrenmanBloc Events:
```
LoadAntrenmanProgramlari, FilterByZorluk(Zorluk), StartAntrenman(AntrenmanProgrami),
CompleteEgzersiz(String), CompleteAntrenman(...), LoadAntrenmanGecmisi
```

### AnalyticsBloc Events:
```
LoadWeeklyAnalytics, LoadMonthlyAnalytics
```

## 🔴 DOKUNULMAYACAK DOSYALAR

```
lib/presentation/pages/home_page_yeni.dart
lib/presentation/pages/profil_page.dart
lib/presentation/pages/antrenman_page.dart
lib/presentation/pages/ai_chatbot_page.dart
lib/presentation/pages/alisveris_listesi_page.dart
lib/presentation/pages/haftalik_rapor_page.dart
lib/presentation/pages/meal_detail_page.dart
lib/presentation/pages/favori_yemekler_page.dart
lib/presentation/pages/analytics_page.dart
lib/presentation/pages/macro_calculator_page.dart
lib/presentation/widgets/*.dart (13 dosya)
```

## ✅ Makro Hesaplama (Mifflin-St Jeor)

```dart
// Erkek: BMR = (10 × kilo) + (6.25 × boy) - (5 × yaş) + 5
// Kadın: BMR = (10 × kilo) + (6.25 × boy) - (5 × yaş) - 161
// TDEE = BMR × aktivite_katsayisi
// Hedef bazlı kalori:
//   bulk:     TDEE + 300-500 kcal
//   maintain: TDEE
//   cut:      TDEE - 300-500 kcal
// Protein: hedef_kilo × 2.0-2.2 g/kg
// Karb:    kalan kalorinin %50'si  ÷ 4
// Yağ:     kalan kalorinin %30'u   ÷ 9
```

## 🤖 AI Servis (Pollinations.AI)

```dart
// Endpoint: https://text.pollinations.ai/
// Model: openai (gpt-4o-mini)
// Kategoriler: supplement, nutrition, training, general, dietician
// Sohbet geçmişi: son 10 mesaj
```

## 📊 Supabase Tablo Yapısı

Supabase'de kullanılacak tablolar:
```sql
-- user_profiles (id, ad, soyad, yas, boy, mevcut_kilo, hedef_kilo, 
--               cinsiyet, aktivite_seviyesi, hedef, diyet_tipi, 
--               manuel_alerjiler, kayit_tarihi)
-- daily_plans (id, user_id, tarih, kahvalti_json, ara_ogun1_json, 
--              ogle_json, ara_ogun2_json, aksam_json, hedefler_json,
--              tamamlanan_ogunler_json)
-- meal_confirmations (id, user_id, yemek_id, tarih, durum)
-- workout_completions (id, user_id, program_id, tarih, tamamlanan_egzersizler)
```

## ⚠️ Platform Uyumluluğu (Web + Mobil)

```dart
// ❌ KULLANMA:
// import 'dart:io';
// Platform.isAndroid veya Platform.isIOS direkt

// ✅ KULLAN:
import 'package:flutter/foundation.dart';
if (kIsWeb) { ... } else { ... }
```

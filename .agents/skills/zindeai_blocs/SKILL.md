---
description: ZindeAI V2.0 BLoC event/state sözlüğü - UI ile backend bağlantısı referansı
---

# ZindeAI V2.0 - BLoC Referans Skill

> ⚠️ UI dosyaları bu event ve state'leri bekliyor. SADECE aşağıdakileri kullan, isim değiştirme!

---

## 🏠 HomeBloc

### Events
```dart
class LoadHomePage extends HomeEvent {}
class LoadPlanByDate extends HomeEvent { final DateTime tarih; }
class RefreshDailyPlan extends HomeEvent { final bool forceRegenerate; }
class GenerateWeeklyPlan extends HomeEvent { final bool forceRegenerate; }
class MarkMealAsEaten extends HomeEvent { final String yemekId; }
class SkipMeal extends HomeEvent { final String yemekId; }
class ConfirmMealEaten extends HomeEvent { final String yemekId; }
class ResetMealStatus extends HomeEvent { final String yemekId; }
class GenerateAlternativeMeals extends HomeEvent {
  final Yemek mevcutYemek;
  final int sayi;
}
class ReplaceMealWith extends HomeEvent {
  final Yemek eskiYemek;
  final Yemek yeniYemek;
}
class GenerateIngredientAlternatives extends HomeEvent {
  final String ogunId;
  final String besinAdi;
  final double miktar;
  final String birim;
}
class ReplaceIngredientWith extends HomeEvent {
  final String ogunId;
  final AlternatifBesin alternatif;
}
class CancelAlternativeSelection extends HomeEvent {}
class CancelAlternativeMealSelection extends HomeEvent {}
```

### States
```dart
class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {
  final double progress;    // 0.0 - 1.0
  final String message;
}
class HomeLoaded extends HomeState {
  final GunlukPlan plan;
  final MakroHedefleri hedefler;
  final Map<String, bool> tamamlananOgunler;
  final List<Yemek>? alternatifYemekler;  // null ise gösterme
}
class AlternativeIngredientsLoaded extends HomeState {
  final String ogunId;
  final String besinAdi;
  final List<AlternatifBesin> alternatifler;
}
class HomeError extends HomeState { final String mesaj; }
```

---

## 👤 ProfilBloc

### Events
```dart
class ProfilYukle extends ProfilEvent {}
class ProfilDegisti extends ProfilEvent { final KullaniciProfili profil; }
class ProfilKaydet extends ProfilEvent { final KullaniciProfili profil; }
class ProfilTemizle extends ProfilEvent {}
```

### States
```dart
class ProfilInitial extends ProfilState {}
class ProfilYukleniyor extends ProfilState {}
class ProfilYuklendi extends ProfilState { final KullaniciProfili profil; }
class ProfilGuncellendi extends ProfilState {
  final KullaniciProfili profil;
  final MakroHedefleri makrolar;
}
class ProfilMakrolariGuncellendi extends ProfilState {
  final MakroHedefleri makrolar;
  final bool toleranstaMi;
  final List<String> toleransDisindakiler;
}
class ProfilKaydedildi extends ProfilState { final KullaniciProfili profil; }
class ProfilHata extends ProfilState { final String mesaj; }
```

---

## 🍽️ MealPlanningBloc

### Events
```dart
class MealPlanYukle extends MealPlanningEvent { final DateTime tarih; }
class MealPlanOlustur extends MealPlanningEvent {
  final MakroHedefleri hedefler;
  final DateTime tarih;
}
class AlternatifOlustur extends MealPlanningEvent {
  final Yemek mevcutYemek;
  final int sayi;
}
class YemekDegistir extends MealPlanningEvent {
  final Yemek eskiYemek;
  final Yemek yeniYemek;
}
```

### States
```dart
class MealPlanInitial extends MealPlanningState {}
class MealPlanYukleniyor extends MealPlanningState {}
class MealPlanYuklendi extends MealPlanningState { final GunlukPlan plan; }
class MealPlanHata extends MealPlanningState { final String mesaj; }
```

---

## 🏋️ WorkoutBloc

### Events
```dart
class LoadAntrenmanProgramlari extends WorkoutEvent {}
class FilterByZorluk extends WorkoutEvent { final Zorluk zorluk; }
class StartAntrenman extends WorkoutEvent { final AntrenmanPlani program; }
class CompleteEgzersiz extends WorkoutEvent { final String egzersizId; }
class CompleteAntrenman extends WorkoutEvent {
  final String programId;
  final DateTime tarih;
}
class LoadAntrenmanGecmisi extends WorkoutEvent {}
```

### States
```dart
class AntrenmanInitial extends WorkoutState {}
class AntrenmanYukleniyor extends WorkoutState {}
class AntrenmanProgramlariLoaded extends WorkoutState {
  final List<AntrenmanPlani> programlar;
  final Zorluk? aktifFiltre;
}
class AntrenmanAktif extends WorkoutState {
  final AntrenmanPlani aktifProgram;
  final int tamamlananEgzersiz;
}
class AntrenmanGecmisiLoaded extends WorkoutState {
  final List<dynamic> gecmis;  // TamamlananAntrenman listesi
}
class AntrenmanHata extends WorkoutState { final String mesaj; }
```

---

## 🤖 ChatbotBloc

### Events
```dart
class ChatbotMesajGonder extends ChatbotEvent {
  final String mesaj;
  final AIKategori kategori;
}
class ChatbotKategoriDegistir extends ChatbotEvent { final AIKategori kategori; }
class ChatbotTemizle extends ChatbotEvent {}
```

### States
```dart
enum AIKategori { supplement, nutrition, training, general, dietician }

class ChatbotInitial extends ChatbotState {}
class ChatbotBekliyor extends ChatbotState {}
class ChatbotYanit extends ChatbotState {
  final String yanit;
  final List<ChatMesaj> mesajlar;
}
class ChatbotHata extends ChatbotState { final String mesaj; }

class ChatMesaj {
  final String icerik;
  final bool kullanicidan;  // true=kullanıcı, false=AI
  final DateTime zaman;
}
```

---

## 📊 AnalyticsBloc

### Events
```dart
class LoadWeeklyAnalytics extends AnalyticsEvent {}
class LoadMonthlyAnalytics extends AnalyticsEvent {}
```

### States
```dart
class AnalyticsInitial extends AnalyticsState {}
class AnalyticsYukleniyor extends AnalyticsState {}
class WeeklyAnalyticsLoaded extends AnalyticsState {
  final HaftalikRapor rapor;
  final List<GunlukPlan> planlar;
}
class MonthlyAnalyticsLoaded extends AnalyticsState {
  final List<HaftalikRapor> raporlar;
}
class AnalyticsHata extends AnalyticsState { final String mesaj; }
```

---

## ⚠️ UI Bağlantısı Kuralı

UI dosyaları şu şekilde BLoC'ları kullanır:
```dart
// Okuma:
BlocBuilder<HomeBloc, HomeState>(
  builder: (context, state) { ... }
)

// Event gönderme:
context.read<HomeBloc>().add(LoadHomePage());

// Provider'lar main.dart'ta tanımlanmalı:
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => sl<HomeBloc>()..add(LoadHomePage())),
    BlocProvider(create: (_) => sl<ProfilBloc>()),
    BlocProvider(create: (_) => sl<WorkoutBloc>()),
    BlocProvider(create: (_) => sl<ChatbotBloc>()),
    BlocProvider(create: (_) => sl<AnalyticsBloc>()),
  ],
)
```

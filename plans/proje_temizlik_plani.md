# 🧹 ZindeAI V2.0 - Tam Temizlik Planı

## 📋 Sorunun Özeti

Projenizde **import tutarsızlığı** ve **gereksiz shim dosyaları** var. Bu durum:
- Flutter'ın eski build cache'leri kullanmasına
- Hot reload/restart'ın düzgün çalışmamasına
- Değişikliklerin yansımamasına neden oluyor

## 🎯 Hedef

Tüm import'ları doğru yola yönlendirip gereksiz shim dosyalarını kaldırarak projeyi temizlemek.

---

## 📁 Silinecek Dosyalar (Toplam 13 Dosya)

### A. Nutrition Entity Shim'leri (3 dosya)
```
lib/domain/entities/yemek.dart
lib/domain/entities/gunluk_plan.dart
lib/domain/entities/yemek_onay_sistemi.dart
```

### B. User Entity Shim'leri (2 dosya)
```
lib/domain/entities/hedef.dart
lib/domain/entities/kullanici_profili.dart
```

### C. Workout Entity Shim'leri (2 dosya)
```
lib/domain/entities/antrenman.dart
lib/domain/entities/egzersiz.dart
```

### D. Analytics Entity Shim'leri (2 dosya)
```
lib/domain/entities/alisveris_listesi.dart
lib/domain/entities/haftalik_rapor.dart
```

### E. Nutrition Entity Legacy (1 dosya)
```
lib/domain/entities/alternatif_besin_legacy.dart
```

### F. Repository Shim (1 dosya)
```
lib/data/repositories/meal_repository_v2.dart
```

### G. UseCase Shim (1 dosya)
```
lib/domain/usecases/ogun_planlayici.dart
```

### H. Deprecated Service (1 dosya)
```
lib/domain/services/deprecated/alternatif_oneri_servisi.dart
```

---

## 🔧 Düzeltilecek Import'lar (5 Dosya)

### 1. `lib/presentation/widgets/ogun_card.dart`

**Satır 4:**
```dart
// ❌ ÖNCE
import '../../domain/entities/yemek.dart';

// ✅ SONRA
import '../../domain/entities/nutrition/yemek.dart';
```

---

### 2. `lib/presentation/widgets/detayli_ogun_card.dart`

**Satır 2-3:**
```dart
// ❌ ÖNCE
import '../../domain/entities/yemek.dart';
import '../../domain/entities/yemek_onay_sistemi.dart';

// ✅ SONRA
import '../../domain/entities/nutrition/yemek.dart';
import '../../domain/entities/nutrition/yemek_onay_sistemi.dart';
```

---

### 3. `lib/presentation/widgets/alternatif_yemek_bottom_sheet.dart`

**Satır 2:**
```dart
// ❌ ÖNCE
import '../../domain/entities/yemek.dart';

// ✅ SONRA
import '../../domain/entities/nutrition/yemek.dart';
```

---

### 4. `lib/presentation/pages/meal_detail_page.dart`

**Satır 2:**
```dart
// ❌ ÖNCE
import '../../domain/entities/yemek.dart';

// ✅ SONRA
import '../../domain/entities/nutrition/yemek.dart';
```

---

### 5. `lib/presentation/widgets/alternatif_besin_bottom_sheet.dart`

**Satır 2:**
```dart
// ❌ ÖNCE
import '../../domain/entities/alternatif_besin_legacy.dart';

// ✅ SONRA
import '../../domain/entities/nutrition/alternatif_besin.dart';
```

---

## 📝 Uygulama Adımları

### Faz 1: Import Düzeltmeleri

```bash
# 1. ogun_card.dart'ı düzelt
# Satır 4: yemek.dart -> nutrition/yemek.dart

# 2. detayli_ogun_card.dart'ı düzelt
# Satır 2-3: Her ikisini de nutrition/ altına al

# 3. alternatif_yemek_bottom_sheet.dart'ı düzelt
# Satır 2: yemek.dart -> nutrition/yemek.dart

# 4. meal_detail_page.dart'ı düzelt
# Satır 2: yemek.dart -> nutrition/yemek.dart

# 5. alternatif_besin_bottom_sheet.dart'ı düzelt
# Satır 2: alternatif_besin_legacy.dart -> nutrition/alternatif_besin.dart
```

### Faz 2: Shim Dosyalarını Sil

```bash
# Nutrition shim'leri
rm lib/domain/entities/yemek.dart
rm lib/domain/entities/gunluk_plan.dart
rm lib/domain/entities/yemek_onay_sistemi.dart

# User shim'leri
rm lib/domain/entities/hedef.dart
rm lib/domain/entities/kullanici_profili.dart

# Workout shim'leri
rm lib/domain/entities/antrenman.dart
rm lib/domain/entities/egzersiz.dart

# Analytics shim'leri
rm lib/domain/entities/alisveris_listesi.dart
rm lib/domain/entities/haftalik_rapor.dart

# Legacy
rm lib/domain/entities/alternatif_besin_legacy.dart

# Repository & UseCase shim
rm lib/data/repositories/meal_repository_v2.dart
rm lib/domain/usecases/ogun_planlayici.dart

# Deprecated
rm lib/domain/services/deprecated/alternatif_oneri_servisi.dart
rmdir lib/domain/services/deprecated  # Klasör boşsa sil
```

### Faz 3: Build Cache Temizliği (ÖNEMLİ!)

```bash
# Flutter cache'i tamamen temizle
flutter clean

# Build klasörlerini manuel sil
rm -rf build/
rm -rf .dart_tool/

# Pub cache'i temizle
flutter pub cache clean
flutter pub cache repair

# Dependencies'i yeniden yükle
flutter pub get

# Build runner varsa
flutter pub run build_runner build --delete-conflicting-outputs

# Test build
flutter run
```

---

## ✅ Doğrulama Kontrol Listesi

Temizlik sonrası şunları kontrol edin:

- [ ] Hiçbir dosya `entities/yemek.dart` import etmiyor
- [ ] Hiçbir dosya `entities/alternatif_besin_legacy.dart` import etmiyor
- [ ] Tüm entity import'ları doğru alt klasöre yönlendiriyor:
  - `entities/nutrition/*` için nutrition
  - `entities/user/*` için user
  - `entities/workout/*` için workout
  - `entities/analytics/*` için analytics
- [ ] `flutter clean` çalıştırıldı
- [ ] Build cache'ler temizlendi
- [ ] `flutter pub get` başarılı
- [ ] Uygulama hatasız çalışıyor
- [ ] Hot reload düzgün çalışıyor

---

## 🔍 Potansiyel Sorunlar ve Çözümleri

### Sorun 1: "Cannot find import" hatası

**Çözüm:**
```bash
flutter clean
rm -rf .dart_tool
flutter pub get
```

### Sorun 2: Hot reload hala çalışmıyor

**Çözüm:**
```bash
# Uygulamayı tamamen durdur
# Cache'i temizle
flutter clean
# Yeniden başlat
flutter run
```

### Sorun 3: Build runner hataları

**Çözüm:**
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📊 Beklenen İyileştirmeler

✅ Import tutarlılığı sağlanacak
✅ Gereksiz 13 dosya kaldırılacak
✅ Build cache sorunları çözülecek
✅ Hot reload düzgün çalışacak
✅ Değişiklikler anında yansıyacak
✅ Kod tabanı daha temiz ve bakımı kolay olacak

---

## 🚀 Sonraki Adımlar

Bu temizlik tamamlandıktan sonra:

1. **Git commit** yapın: `git commit -m "refactor: Clean up shim files and fix imports"`
2. **Test** edin: Tüm önemli senaryoları test edin
3. **Takıma bilgi** verin: Değişikliklerden haberdar edin

---

## 📞 Destek

Sorun yaşarsanız:
- Build cache'i tekrar temizleyin
- IDE'yi yeniden başlatın (VS Code / Android Studio)
- Flutter doctor çalıştırın: `flutter doctor -v`

---

**Oluşturulma Tarihi:** 2026-03-07
**Proje:** ZindeAI V2.0
**Durum:** Onay Bekliyor ✋

# ZindeAI V2.0 - Repo Sadeleştirme Planı

## Amaç

Proje yapısını herkesin anlayabileceği şekilde sadeleştirmek. Gereksiz dosyaları kaldırmak, kodu temizlemek ve projeyi bakımı kolay bir hale getirmek.

---

## Mevcut Durum Analizi

### Sorunlar

1. **Kök dizin kirliliği:** 60+ geçici dosya (log, json, script)
2. **Boş/ gereksiz klasörler:** `lib/data/models/`, `lib/data/mappers/`, `lib/data/local/`
3. **Shim dosyaları:** Gerçek dosyaları taklit eden, sadece yönlendirme yapan dosyalar
4. **Encoding sorunları:** Bazı Dart dosyalarında Türkçe karakter bozulması
5. **Açık dosyalar:** VSCode'da 100+ açık sekmeyi gösteren dosyalar
6. **Belge tutarsızlığı:** README ve PROGRESS.md güncel değil

### Beklenen Faydalar

- Proje daha kolay anlaşılacak
- Yeni geliştiriciler daha hızlı adapte olacak
- Build cache sorunları azalacak
- Git history daha temiz olacak

---

## Temizlik Planı

### Faz 1: Kök Dizin Temizliği (En Öncelik)

Bu dosyalar proje için gerekli değil ve geliştirme süreçlerinin kalıntıları:

#### 1.1 Log Dosyaları (27 dosya)

```
analyze_log_utf8.txt
analyze_log.txt
analyze_output.json
analyze_output.txt
analyze_presentation.txt
analyze_son_utf8.txt
analyze_son.txt
analyze_utf8.txt
analyze_v2_utf8.txt
analyze_v2.txt
analyze_v3_utf8.txt
analyze_v3.txt
analyze_v4_utf8.txt
analyze_v4.txt
analyze_v5_utf8.txt
analyze_v5.txt
analyze_v6_utf8.txt
analyze_v6.txt
analyze_v7_utf8.txt
analyze_v7.txt
analyze.txt
analyze2.txt
analyze3.txt
analyze4.txt
analyze5.txt
analyze6.txt
analyze7.txt
analyze8.txt
analyze9.txt
analyze10.txt
```

#### 1.2 Build Log Dosyaları (6 dosya)

```
build_error.log
build_log_2_utf8.txt
build_log_2.txt
build_log_utf8.txt
build_log.txt
build_web_error.log
```

#### 1.3 Geçici Test/Debug Dosyaları (10 dosya)

```
flutter_doctor_output.txt
flutter_doctor_utf8.txt
machine_utf8.txt
machine.txt
matrix_result.txt
test_analyze.txt
test_err.txt
test_out_utf8.txt
test_out.txt
test_output.txt
```

#### 1.4 Geçici JSON/Veri Dosyaları (8 dosya)

```
batch_err.json
err.json
supabase_utf8.json
supabase.json
tmp_cols.txt
tmp_orig.txt
tmp_sample.json
seed_out.txt
```

#### 1.5 Fix Script Dosyaları (7 dosya)

```
fix_chatbot.dart
fix_encoding.dart
fix_encoding.js
fix_encoding.py
fix_macros.py
fix_macros2.py
fix_profil.dart
```

#### 1.6 Diğer Fix Scriptleri (6 dosya)

```
fix_ui.py
fix_ui_2.py
fix_ui_3.py
fix_ui_ufffd.py
revert_fuckups.py
unfuck_files.py
```

#### 1.7 Geçici Dosyalar (3 dosya)

```
ara_ogun_1
output.txt
test_regex.dart
```

### Faz 2: Boş Klasör Temizliği

Bu klasörler boş veya kullanılmıyor:

```
lib/data/models/          # Boş klasör
lib/data/mappers/         # Boş klasör
lib/data/local/           # hive_service.dart zaten yok
```

### Faz 3: Shim Dosyaları Temizliği

Bu dosyalar sadece diğer dosyalara yönlendirme yapıyor, gerçek işlev yok:

#### 3.1 lib/core/utils/app_logger.dart

```dart
// Bu dosya sadece logger.dart'a export yapıyor
// Doğrudan logger.dart kullanılmalı
```

#### 3.2 lib/data/datasources/antrenman_local_data_source.dart

```dart
// Bu dosya sadece WorkoutRepository'e yönlendirme yapıyor
// Doğrudan WorkoutRepository kullanılmalı
```

### Faz 4: Encoding Sorunları

Bazı Dart dosyalarında Türkçe karakterler bozuk görünüyor:

```
lib/presentation/bloc/home/home_bloc.dart
lib/domain/services/circadian_feedback_service.dart
lib/core/di/injection_container.dart
```

Bu dosyalardaki bozuk karakterler düzeltilmeli:
- `i` → `ı`
- `s` → `ş`
- `g` → `ğ`
- vb.

### Faz 5: .gitignore Güncelleme

Geçici dosyaların Git'e işlenmemesi için kurallar eklenecek:

```gitignore
# Log dosyaları
*.log
*.txt
analyze*.txt
analyze*.json

# Build dosyaları
build_*.txt
build_*.log

# Geçici dosyalar
tmp_*
*_tmp.*
*_temp.*

# Python fix scriptleri (kalıcı olmayan)
fix_*.py
fix_*.js
fix_*.dart

# Test çıktıları
test_*.txt
test_*.json

# Supabase geçici dosyaları
supabase.json
supabase_*.json
```

### Faz 6: Dokümantasyon Güncelleme

#### 6.1 README.md

- Güncel proje durumunu yansıtacak şekilde güncellenecek
- Temizlik sonrası yapısı gösterilecek

#### 6.2 PROGRESS.md

- Temizlik adımları işaretlenecek
- Güncel durum notları eklenecek

---

## Uygulama Adımları

### Adım 1: Yedekleme (ÖNEMLİ!)

```bash
# Önce projenin yedeğini al
git add -A
git commit -m "Yedek: Temizlik öncesi durum"
git push origin main
```

### Adım 2: Kök Dizin Temizliği

```bash
# Windows PowerShell veya CMD kullanarak
# Log dosyaları
del analyze*.txt
del analyze*.json

# Build logları
del build*.log
del build*.txt

# Test çıktıları
del test*.txt
del test*.json

# Geçici dosyalar
del tmp*.txt
del tmp*.json
del output.txt

# Fix scriptleri
del fix_*.py
del fix_*.js
del fix_*.dart

# Diğer dosyalar
del revert_fuckups.py
del unfuck_files.py
del test_regex.dart
del ara_ogun_1
```

### Adım 3: Boş Klasörleri Sil

```bash
# Boş klasörleri sil
rmdir lib\data\models
rmdir lib\data\mappers
rmdir lib\data\local
```

### Adım 4: Shim Dosyalarını Sil

```bash
del lib\core\utils\app_logger.dart
del lib\data\datasources\antrenman_local_data_source.dart
```

### Adım 5: Import Düzeltmeleri

Shim dosyalarını kullanan dosyaları bulup düzelt:

```bash
# app_logger.dart kullanan dosyaları bul
# logger.dart ile değiştir
```

Düzeltilmesi gereken import örnekleri:
```dart
// ÖNCESİ
import '../../core/utils/app_logger.dart';

// SONRASI
import '../../core/utils/logger.dart';
```

### Adım 6: Build Cache Temizliği

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Adım 7: Test

```bash
# Uygulamayı çalıştır
flutter run

# Analyze kontrol
flutter analyze
```

---

## Sonraki Adımlar

Temizlik tamamlandıktan sonra:

1. **Git commit** ile değişiklikleri kaydet
2. **Yeni branch** oluştur ve test et
3. **Code review** yaptır
4. **Merge** et

---

## Başarı Kriterleri

- [ ] Kök dizinde sadece gerekli dosyalar var
- [ ] Boş klasörler temizlendi
- [ ] Shim dosyaları kaldırıldı
- [ ] Import'lar düzeltildi
- [ ] `flutter analyze` hatasız çalışıyor
- [ ] Uygulama sorunsuz build alıyor
- [ ] Git history temizlendi

---

## İletişim

Sorularınız için proje sahibiyle iletişime geçin.

---

**Oluşturulma Tarihi:** 2025-01-19
**Durum:** Onay Bekliyor
**Tahmini Süre:** 1-2 saat

# ZindeAI v2.0

![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![License](https://img.shields.io/badge/license-Proprietary-red)

Yapay zeka destekli kişisel antrenör ve diyetisyen uygulaması. Kullanıcıların beslenme hedeflerine göre günlük yemek planları oluşturur, antrenman programları sunar ve ilerleme takibi sağlar.

## 🎯 Özellikler

### Beslenme Planlama
- **Kişiselleştirilmiş Yemek Planları:** Kullanıcının antropometrik verilerine (boy, kilo, yaş, cinsiyet) ve hedeflerine (kilo vermek, korumak, almak) göre günlük kalori ve makro hesaplaması
- **Mifflin-St Jeor Formülü:** BMR hesaplamasında kullanılan kanıtlanmış formül
- **Akıllı Makro Dağılımı:** Protein, karbonhidrat ve yağ oranlarının aktivite seviyesine göre optimize edilmesi
- **Yemek Alternatifleri:** Önerilen yemeklerin kullanıcı tercihlerine göre değiştirilebilmesi
- **AI Foto Analizi:** Yemek fotoğraflarından içerik analizi (PollinationsAI entegrasyonu)

### Antrenman Programları
- **Hazır Antrenman Planları:** Farklı seviyelerde (başlangıç, orta, ileri) antrenman programları
- **Egzersiz Detayları:** Set, tekrar ve dinlenme süreleri
- **İlerleme Takibi:** Tamamlanan antrenmanların kaydı

### Analitik ve Raporlama
- **Haftalık Raporlar:** Kilo değişimi, kalori alımı, makro dağılımı özeti
- **Alışveriş Listesi:** Haftalık yemek planına göre otomatik alışveriş listesi oluşturma
- **Görsel Grafikler:** Flutter Graphs ile ilerleme görselleştirmesi

### Teknik Özellikler
- **Clean Architecture:** Domain, Data, Presentation katmanları
- **State Management:** Flutter BLoC
- **Dependency Injection:** GetIt + Injectable
- **Local Storage:** SharedPreferences + FlutterSecureStorage
- **Backend:** Supabase (PostgreSQL)

## 📁 Proje Yapısı

```
lib/
├── core/                    # Temel bileşenler
│   ├── network/            # Ağ yapılandırması
│   ├── services/           # AI servisleri (Pollinations)
│   └── utils/              # Logger, validators, formatters
├── data/                   # Veri katmanı
│   ├── datasources/        # Local & Remote veri kaynakları
│   └── repositories/       # Repository implementasyonları
├── domain/                 # İş mantığı katmanı
│   ├── entities/           # Domain modelleri
│   ├── repositories/       # Repository arayüzleri
│   ├── services/           # Domain servisleri
│   └── usecases/           # Kullanım durumları
└── presentation/           # UI katmanı
    ├── bloc/              # BLoC state yönetimi
    ├── pages/             # Sayfalar
    └── widgets/           # Yeniden kullanılabilir widget'lar
```

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Supabase hesabı

### Adımlar

1. Repoyu klonlayın:
```bash
git clone https://github.com/lastlord444/zindeV2.git
cd zindeV2
```

2. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

3. Supabase yapılandırması:
   - Supabase projesi oluşturun
   - `supabase/migrations/` altındaki SQL dosyalarını çalıştırın
   - `.env` dosyasını oluşturun:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

4. Uygulamayı çalıştırın:
```bash
flutter run
```

## 🧪 Testler

```bash
# Unit testler
flutter test

# Widget testleri
flutter test test/widget_test.dart

# Entegrasyon testleri
flutter test integration_test/
```

## 📦 Kullanılan Teknolojiler

| Kategori | Kütüphane |
|----------|-----------|
| **State Management** | flutter_bloc, provider |
| **Dependency Injection** | get_it, injectable |
| **Network** | dio, http, internet_connection_checker |
| **Database** | supabase_flutter |
| **Local Storage** | shared_preferences, flutter_secure_storage |
| **UI** | table_calendar, shimmer |
| **Utils** | intl, logger, dartz, uuid |

## 🧮 Makro Hesaplama Formülü

### BMR (Bazal Metabolizma Hızı) - Mifflin-St Jeor

**Erkekler:**
```
BMR = 10 × kilo + 6.25 × boy - 5 × yaş + 5
```

**Kadınlar:**
```
BMR = 10 × kilo + 6.25 × boy - 5 × yaş - 161
```

### Günlük Kalori İhtiyacı

```
TDEE = BMR × Aktivite Katsayısı
```

**Aktivite Katsayıları:**
- Sedanter: 1.2
- Hafif Aktif: 1.375
- Orta Aktif: 1.55
- Çok Aktif: 1.725
- Ekstra Aktif: 1.9

### Hedefe Göre Kalori Ayarı

- **Kilo Vermek:** TDEE - 500 kcal
- **Kilo Korumak:** TDEE
- **Kilo Almak:** TDEE + 500 kcal

## 📄 Lisans

Bu proje ticari kullanım için lisanslanmıştır. İzinsiz kopyalanması veya dağıtılması yasaktır.

## 👨‍💻 Geliştirici

[ZindeAI Team](https://github.com/lastlord444)

---

**Not:** Bu uygulama sağlık profesyonellerinin yerini almaz. Herhangi bir sağlık sorunu için mutlaka bir doktora danışın.

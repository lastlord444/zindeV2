---
description: ZindeAI V2.0 tüm entity'lerin tam alan tanımları - halüsinasyonu önlemek için referans
---

# ZindeAI V2.0 - Entity Referans Skill

> ⚠️ Yeni bir entity yazarken ÖNCE bu dosyayı oku, alanları buradan kopyala.

---

## 🔵 KullaniciProfili (domain/entities/user/kullanici_profili.dart)

```dart
class KullaniciProfili extends Equatable {
  final String id;
  final String ad;
  final String soyad;
  final int yas;
  final double boy;            // cm
  final double mevcutKilo;     // kg
  final double? hedefKilo;     // kg, null olabilir
  final Cinsiyet cinsiyet;
  final AktiviteSeviyesi aktiviteSeviyesi;
  final Hedef hedef;
  final DiyetTipi diyetTipi;
  final List<String> manuelAlerjiler;  // ['gluten', 'süt', ...]
  final DateTime kayitTarihi;

  // Metodlar:
  List<String> get tumKisitlamalar        // diyetTipi + manuelAlerjiler
  bool yemekYenebilirMi(List<String>)    // içerik kontrolü
  Map<String, dynamic> toJson()
  factory KullaniciProfili.fromJson(Map<String,dynamic>)
  KullaniciProfili copyWith({...})
}
```

### Enum: Hedef (hedef.dart)
```dart
enum Hedef { bulk, cut, maintain }
enum Cinsiyet { erkek, kadin }
enum AktiviteSeviyesi { sedanter, hafifAktif, ortaAktif, cokAktif, atletik }
enum DiyetTipi { normal, vejetaryen, vegan, glutensiz, laktozsuz }
```

`DiyetTipi.varsayilanKisitlamalar` → `List<String>` döner

---

## 🔴 Yemek (domain/entities/nutrition/yemek.dart)

```dart
class Yemek extends Equatable {
  final String id;
  final String ad;
  final OgunTipi ogun;
  final double kalori;
  final double protein;
  final double karbonhidrat;
  final double yag;
  final List<String> malzemeler;
  final List<AlternatifBesin> alternatifler;  // boş liste varsayılan
  final int hazirlamaSuresi;     // dakika
  final Zorluk zorluk;
  final List<String> etiketler;  // ['vejetaryen', 'glutensiz']
  final String? tarif;
  final String? gorselUrl;
  final String? proteinKaynagi;
  // Tolerans sistemi için:
  final double baseWeightG;       // varsayılan: 100.0
  final String dominantMacro;     // 'protein' | 'carb' | 'fat' → OTOMATİK hesaplanır
  final double minMultiplier;     // varsayılan: 0.5
  final double maxMultiplier;     // varsayılan: 3.0
  final String unitName;          // varsayılan: 'gram'

  // Factory constructor (dominantMacro otomatik hesaplanır):
  factory Yemek({...})
  
  // Metodlar:
  Yemek scale(double multiplier)  // ölçeklendirme
  bool makroyaUygunMu(MakroHedefleri, double tolerans)
  bool kisitlamayaUygunMu(List<String> kisitlamalar)
  double get proteinYuzdesi
  double get karbonhidratYuzdesi
  double get yagYuzdesi
  String get kisaOzet
  Map<String,dynamic> toJson()
  factory Yemek.fromJson(Map<String,dynamic>)
}

enum OgunTipi { kahvalti, araOgun1, ogle, araOgun2, aksam, geceAtistirma, cheatMeal }
enum Zorluk { kolay, orta, zor }
```

---

## 🟡 MakroHedefleri (domain/entities/nutrition/makro_hedefleri.dart)

```dart
class MakroHedefleri extends Equatable {
  final double gunlukKalori;
  final double gunlukProtein;       // gram
  final double gunlukKarbonhidrat;  // gram
  final double gunlukYag;           // gram

  // Metodlar:
  bool kaloriBandindaMi(double mevcut, {double tolerans = 0.10})
  bool proteinBandindaMi(double mevcut, {double tolerans = 0.10})
  // ... diğer tolerans metodları
  Map<String,dynamic> toJson()
  factory MakroHedefleri.fromJson(Map<String,dynamic>)
}
```

---

## 🟢 GunlukPlan (domain/entities/nutrition/gunluk_plan.dart)

```dart
class GunlukPlan extends Equatable {
  final String id;
  final String userId;
  final DateTime tarih;
  final MakroHedefleri hedefler;
  final Yemek? kahvalti;
  final Yemek? araOgun1;
  final Yemek? ogleYemegi;
  final Yemek? araOgun2;
  final Yemek? aksamYemegi;
  final Yemek? geceAtistirma;    // opsiyonel (sadece bulk)
  final Map<String, bool> tamamlananOgunler; // {yemekId: true/false}

  // Metodlar:
  double get toplamKalori
  double get toplamProtein
  double get toplamKarbonhidrat
  double get toplamYag
  bool kaloriToleranstaMi(double tolerans)
  bool proteinToleranstaMi(double tolerans)
  bool karbToleranstaMi(double tolerans)
  bool yagToleranstaMi(double tolerans)
  List<Yemek> get tumOgunler
  GunlukPlan copyWith({...})
}
```

---

## 🟣 YemekDurumu / YemekOnaySistemi (domain/entities/nutrition/yemek_onay_sistemi.dart)

```dart
enum YemekDurumu { yenilecek, yenildi, atlandi, onaylandi }

class YemekOnaySistemi extends Equatable {
  final String userId;
  final DateTime tarih;
  final Map<String, YemekDurumu> ogunDurumlari; // {yemekId: durum}

  // Metodlar:
  bool tumOgunlerTamamlandi()
  int tamamlananSayisi()
  YemekDurumu durumGetir(String yemekId)
}
```

---

## 🔶 AlternatifBesin (domain/entities/nutrition/alternatif_besin.dart)

```dart
class AlternatifBesin extends Equatable {
  final String orijinalBesinAdi;
  final String alternatifAdi;
  final double miktar;
  final String birim;     // 'gram', 'adet', 'ml'
  final double kalori;
  final double protein;
  final double karbonhidrat;
  final double yag;

  Map<String,dynamic> toJson()
  factory AlternatifBesin.fromJson(Map<String,dynamic>)
}
```

---

## 🏋️ AntrenmanPlani (domain/entities/workout/antrenman_plani.dart)

```dart
class AntrenmanPlani extends Equatable {
  final String id;
  final String ad;
  final String aciklama;
  final Zorluk zorluk;
  final int sureDakika;
  final List<Egzersiz> egzersizler;
  final ProgramTuru programTuru;   // kas, kuvvet, kardiyo

  int get egzersizSayisi
}

enum ProgramTuru { kas, kuvvet, kardiyo }

class Egzersiz extends Equatable {
  final String id;
  final String ad;
  final int set;
  final int tekrar;
  final double? agirlik;    // kg, null ise vücut ağırlığı
  final String? aciklama;
  final String? gorselUrl;
  bool tamamlandi;
}
```

---

## 📊 HaftalikRapor (domain/entities/analytics/haftalik_rapor.dart)

```dart
class HaftalikRapor extends Equatable {
  final String userId;
  final DateTime haftaBaslangic;
  final DateTime haftaBitis;
  final List<GunlukPlan> gunlukPlanlar;
  final double ortalamKalori;
  final double ortalamProtein;
  final double ortalamKarb;
  final double ortalamYag;
  final double uyumYuzdesi;     // 0.0 - 1.0
  final List<String> tavsiyeler;
}
```

---

## 🛒 AlisverisListesi (domain/entities/analytics/alisveris_listesi.dart)

```dart
class AlisverisListesi extends Equatable {
  final String userId;
  final DateTime baslangicTarihi;
  final DateTime bitisTarihi;
  final Map<String, List<MalzemeDetayi>> kategoriGruplari;
  // Kategoriler: 'et_balik', 'sebze_meyve', 'sut_urunleri', 'tahil', 'diger'

  double get toplamMaliyet
  int get toplamKalemSayisi
}

class MalzemeDetayi {
  final String ad;
  final double miktar;
  final String birim;
  final double tahminiMaliyet;
  final String oncelik;   // 'kritik', 'normal', 'opsiyonel'
  bool alindiMi;
}
```

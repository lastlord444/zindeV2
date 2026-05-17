# Nutrition Engine Audit Raporu

## 1. Mevcut Gerçek Durum
Şu anki ZindeV2 sisteminde günlük öğün planları (kahvaltı, öğle, akşam, vb.) `generate_daily_plan.dart` kullanılarak oluşturulmaktadır. Planlama sırasında hedeflenen makrolara (kalori, protein, karbonhidrat, yağ) en yakın olan yemekler Supabase ve lokal havuzdan seçilmektedir. Sistem, "5000 adet mükemmel makrolu yemek" ürettiğini iddia eden `scripts/generate_meals.dart` scripti ile doldurulmuş bir veritabanı tohumuna (seed) dayanmaktadır.

## 2. Kanıtlanan Problemler
Audit sonucunda sistemde birbirine bağlı iki kritik problem tespit edilmiştir:
1. **Yemek Çeşitliliği İllüzyonu ve Tekrarı:** Kullanıcılara her gün aynı yemekler (Fit Pankek, Kıymalı Makarna vb.) farklı sıfatlarla ("Nefis", "Doyurucu") sunulmaktadır. Haftalık tekrar engeli (repetition blocker) çalışmamaktadır.
2. **Sentetik (Fake) Makro Verileri:** Yemeklerin içerdiği malzemeler ile bildirdikleri makro/kalori değerleri arasında matematiksel veya besinsel bir tutarlılık yoktur. Makrolar rastgele çarpanlarla oluşturulmuştur.

## 3. Fake/Synthetic Makro Riski
`scripts/generate_meals.dart` incelendiğinde, yemeklerin makrolarının **malzemelerin gramajından hesaplanmadığı** açıkça görülmektedir.
Script, her base yemek için tanımlı sabit makro değerlerini (`basePro`, `baseCarb`, `baseFat`) alıp **%70 ile %150 arasında rastgele bir çarpanla** (`pMult`, `cMult`, `fMult`) çarpmaktadır.

```dart
// scripts/generate_meals.dart satır 76-83
double pMult = 0.7 + random.nextDouble() * 0.8;
double p = double.parse((base.basePro * pMult).toStringAsFixed(1));
// ...
```
**Sonuç:** Aynı malzeme listesine sahip (örneğin "1 Yumurta, 50g Yulaf Unu") iki farklı veritabanı satırı, birbirinden tamamen farklı (biri 15g, diğeri 30g) protein değerlerine sahip olabilmektedir. Bu, diyetisyen standartlarına göre kabul edilemez bir "fake" veridir. Kullanıcıya gösterilen makro ile yediği malzeme birbirini tutmamaktadır.

## 4. Aynı Yemek Tekrarının Teknik Sebebi
`generate_daily_plan.dart` içerisinde, aynı yemeğin gün içinde veya hafta içinde tekrar edilmesini engellemek için `getBaseId` fonksiyonu kullanılmaktadır.
```dart
String getBaseId(String idStr) {
  var base = idStr;
  if (base.contains('_v7_')) base = base.split('_v7_').first;
  // ...
  return base;
}
```
Ancak `scripts/generate_meals.dart`, veritabanına veri eklerken `meal_id` formatını `meal_kahvalti_00001`, `meal_kahvalti_00002` şeklinde oluşturmaktadır.
Base id'ler ("Fit Pankek" vb.) ID'nin içinde yer almaz. Bu yüzden `getBaseId('meal_kahvalti_00001')` yine `meal_kahvalti_00001` döner. Sistem `meal_kahvalti_00001` ile `meal_kahvalti_00002`'yi tamamen farklı yemekler sanır. Oysa ikisi de "Nefis Fit Pankek" ve "Ev Yapımı Fit Pankek" isimli aynı base yemeğin kopyalarıdır. Bu sebeple tekrar filtresi %100 by-pass edilmektedir.

## 5. Kahvaltı Fit Pankek Örnek Hesap Analizi
- **Tarif:** 1 Yumurta, 65g Yulaf Unu, 125ml Süt, 1.5 Tatlı Kaşığı Bal
- **Kullanıcıya Gösterilen Makro:** ~567 kcal / 31g P / 65g K / 20g Y
- **Gerçek Besin Değeri (Yaklaşık):**
  - 1 Yumurta: 6g P, 5g Y (72 kcal)
  - 65g Yulaf: 9g P, 44g K, 4.5g Y (250 kcal)
  - 125ml Süt: 4g P, 6g K, 4g Y (75 kcal)
  - 1.5 tk Bal: 0g P, 12g K, 0g Y (48 kcal)
  - **Toplam Gerçek:** ~19g P, 62g K, 13.5g Y (~445 kcal)
**Fark:** Gösterilen 31g protein, gerçek olan 19g protein ile uyuşmamaktadır. Aradaki 12g proteinlik fark, generation script'in uyguladığı rastgele `pMult` (örneğin 1.5x) çarpımından kaynaklanan tamamen sentetik bir veridir.

## 6. Hangi Dosyalar Riskli
- `scripts/generate_meals.dart` (Kök sorun)
- `supabase/migrations/002_insert_meals_data.sql` (Hatalı tohum verileri)
- `lib/domain/usecases/meal_planning/generate_daily_plan.dart` (ID ayıklama mantığı eksik)
- `lib/domain/entities/nutrition/yemek.dart` (Scale işlemlerinde hatalı sentetik makronun büyütülmesi)

## 7. Hangi Değişiklikler Yapılmalı
1. **DB Seed Refactor:** `generate_meals.dart` scripti tamamen kaldırılmalı veya değiştirilmeli. Makrolar sentetik randomizasyon yerine malzemelerin standart referans gramaj değerlerinden (örn. USDA veri tabanı eşdeğeri) 1:1 hesaplanmalı.
2. **Base ID Düzeltmesi:** Yemek ID'leri base tarifi belirtecek bir yapıda olmalı (örneğin `meal_pankek_001` gibi) veya `Yemek` entity'sine `baseTemplateId` alanı eklenerek `generate_daily_plan`'daki repetition tracker bu alana bakmalı.
3. **Gerçek Scale (Ölçekleme) Mantığı:** `Yemek.scale()` metodu çalıştırıldığında, makrolar base yemeğin rastgele makrolarına göre değil, doğrudan porsiyona veya gramaja göre oranlanmalı.

## 8. Uygulama Sırası
1. Veritabanı için gerçek besin değerlerine sahip temiz, küçük ama tutarlı bir yemek kütüphanesi (JSON veya yeni script) oluşturulması.
2. Yemek tablosuna `base_id` veya `template_id` kolonunun eklenmesi.
3. `generate_daily_plan.dart` içindeki repetition logic'in `base_id` üzerine kaydırılması.
4. Yeni tohum (seed) verisi ile Supabase'in güncellenmesi.

## 9. Test/Validator Önerileri
- **Makro/Malzeme Tutarlılık Testi:** Bir yemek objesindeki malzemelerin gramajları parse edilip standart makrolarla çarpıldığında, yemeğin `.kalori`, `.protein` değerleriyle %10 tolerans içinde eşleştiğini assert eden bir validator script yazılmalı.
- **Tekrar Testi:** `generate_daily_plan.dart` üst üste 7 gün çalıştırıldığında aynı `base_id`'nin belirlenen limitten (örn. haftada 2) fazla gelmediğini assert eden bir test eklenmeli.

# Nutrition Engine Audit Raporu

## 1. Repo Truth Summary
Bu proje bir Flutter + Dart + Supabase (PostgreSQL) mobil uygulamasıdır. Herhangi bir React, Next.js veya web projesine rewrite yapılması kesinlikle yasaktır. Yapay zeka hiçbir koşulda makro hesaplaması yapmamalı veya kendi kendine yemek uydurmamalıdır; tüm hesaplamalar DB, RPC ve Dart içindeki optimizer tarafından yapılmalıdır. Sistem Türkçe önceliklidir ve "1 ana + 2 alternatif" kuralı gözetilmektedir.

## 2. İncelenen Dosyalar
- `lib/domain/services/meal_optimizer.dart`
- `lib/domain/usecases/meal_planning/generate_daily_plan.dart`
- `supabase/migrations/20260316_v4_meal_optimizer_rpc.sql`

## 3. Kritik Bulgular

- **`get_best_fit_foods` içinde 500 kcal sabiti var mı?**
  **EVET.** SQL migration dosyasında (satır 125) `v_target_calories NUMERIC := 500.0;` şeklinde doğrudan hardcode edilmiştir.

- **`targetCalories` Dart'tan RPC'ye gerçekten gidiyor mu?**
  **HAYIR.** `meal_optimizer.dart` dosyasındaki RPC çağrısında `targetCalories` veritabanına gönderilmiyor. RPC sadece protein, karb ve yağ oranlarını (`p_target_p_ratio` vb.) parametre olarak alıyor. 

- **RPC `targetCalories` parametresi alıyor mu?**
  **HAYIR.** RPC'nin parametre listesinde hedef kalori yoktur. Bu nedenle DB tarafı her yemeği önce 500 kcal'e göre ölçeklendiriyor, ardından Dart tarafı bunu tekrar hedefe göre ölçeklemeye çalışıyor; bu durum ciddi porsiyon ve hesaplama hatalarına yol açar.

- **`meal_type` contract tek mi? `gece_atistirma` / `gece_atistirmasi` mismatch var mı?**
  **EVET, MISMATCH VAR.** Supabase CHECK constraint'i `gece_atistirma` kullanırken, Dart kodundaki `ogunTipiFromString` her iki varyasyonu (`gece_atistirmasi` dahil) yakalamaya çalışıyor. Veri bütünlüğünü bozabilecek bir çelişki mevcut.

- **Her `meal_type` için 1 ana + 2 alternatif garanti mi? / Ara öğünlerde alternatif garanti mi?**
  **GARANTİ DEĞİL.** `generate_daily_plan.dart` içinde `_bulAlternatifler` metodu sadece bulabildiğini (0, 1 veya 2) dönüyor. Her zaman 2 tane bulmasını zorunlu kılan bir mekanizma (hard gate) bulunmuyor. Bu durum ara öğünler için de geçerlidir.

- **Alternatifler hard gate mi?**
  **HAYIR.** Eğer 2 alternatif bulunamazsa veya makroları denk değilse, sistem durmuyor; elindeki eksik veya uyumsuz veriyi listeye ekleyip yola devam ediyor.

- **Final plan validator hard gate mi? / Plan hedef tolerans dışındaysa kullanıcıya dönebiliyor mu?**
  **HAYIR.** `generate_daily_plan.dart` içinde 5 denemelik bir "retry" mekanizması var. Ancak 5 deneme sonucunda plan hala %10 veya %15 toleransın dışındaysa (örn. 300 kcal aşıldıysa), sistem "Right(finalPlan)" diyerek bu hatalı planı geçerliymiş gibi kullanıcıya dönüyor.

- **Raw/Cooked (Çiğ/Pişmiş) ayrımı var mı?**
  **YOK.** Yemek tablosunda sadece "100g bazlı" değerler bulunuyor. Pişmiş pirinç ile çiğ pirinç arasındaki ağırlık/kalori farkını algılayacak bir mekanizma olmadığı için makro hedeflerinde ciddi sapmalar oluşma riski var.

- **AI makro hesaplıyor veya yemek uyduruyor mu?**
  **HAYIR.** Mimari gereği besin seçimi Supabase (Euclidean Distance) ve Dart kodları tarafından yapılıyor. AI burada makro hesaplamıyor.

- **Mobil app içinde LLM API key riski var mı?**
  **POTANSİYEL RİSK.** Projede `flutter_dotenv` kullanıldığı ve PollinationsAI entegrasyonu olduğu için, API key'lerin `.env` dosyasıyla derlenip uygulamanın içine (client-side) paketlenme riski çok yüksektir.

## 4. Risk Seviyesi
**CRITICAL (Kritik).**
Core beslenme motoru yanlış çalışmaktadır. Herhangi bir yeni özellik eklenmeden önce, RPC'nin 500 kcal sabitinden arındırılması ve final validator'ın hatalı planları onaylamasının engellenmesi (hard gate) ŞARTTIR.

## 5. Fix Sırası
1. Supabase `get_best_fit_foods` RPC'sine `p_target_calories` parametresinin eklenmesi ve 500.0 sabitinin kaldırılması.
2. `meal_optimizer.dart` içindeki RPC çağrısında `targetCalories` değerinin parametre olarak iletilmesi.
3. Final plan validator mekanizmasının "Hard Gate" (hata fırlatan: `Left(PlanHatasi)`) yapısına geçirilmesi.
4. "1 ana + 2 alternatif" kuralının hard gate yapılması.
5. `meal_type` isimlendirme karmaşasının (`gece_atistirma` vs `gece_atistirmasi`) standardize edilmesi.
6. Raw/Cooked ayrımının veri modeline entegre edilmesi.
7. Mobil client içinde tutulan LLM/AI servis anahtarlarının Supabase Edge Functions'a taşınması (Güvenlik).

## 6. PR Önerileri
Lütfen bu düzeltmeleri devasa tek bir PR'da YAPMAYIN.
- **PR 1:** RPC TargetCalories Fix & MealType Normalize
- **PR 2:** Alternatifler ve Final Validator Hard Gate
- **PR 3:** Raw/Cooked Data Model Update & AI API Security (Edge Functions)

## 7. Merge Blocker Listesi
Eğer bir PR'da aşağıdaki maddelerden biri eksikse, GPT Mentor PR'ın merge edilmesini **REDDETMELİDİR**:
- RPC 500 kcal sabiti düzeltilmemişse.
- Hatalı (tolerans dışı) bir plan "Right" objesi olarak dönmeye devam ediyorsa.
- `gece_atistirma` isimlendirmeleri hem Dart hem DB seviyesinde birebir eşitlenmemişse.
- AI API key'ler mobil uygulamanın source kodunda (veya `.env` asset'i içerisinde) tutulmaya devam ediliyorsa.

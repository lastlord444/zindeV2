# ZindeMentor Protokolü

Bu dosya, ZindeAI projesinde hangi işi hangi uzman modele götüreceğimizi ve GPT mentorun nasıl karar vereceğini tanımlar.

## 1. Rol Tanımı

GPT mentor, ZindeAI projesinde üst seviye mimar, ürün mentoru ve review yöneticisi gibi davranır.

Görevi:
- Değişiklik isteklerini sınıflandırmak
- Doğru uzman modele yönlendirmek
- Sonnet / Opus / Gemini çıktısını değerlendirmek
- Final karar vermek
- PR merge öncesi riskleri kontrol etmek
- Main branch’i korumak

GPT mentor doğrudan “hemen kod yaz” demez.
Önce sorunu sınıflandırır, sonra doğru uzmana gidilecek promptu üretir.

## 2. Uzman Model Dağılımı

### Sonnet — Senior Engineer / Kod / DB / Altyapı

Sonnet’e gidecek konular:
- Supabase/Postgres şemaları
- migration tasarımı
- RLS kuralları
- RPC fonksiyonları
- Edge Functions
- validator mantığı
- CI/test/gate
- Flutter mimari
- nutrition engine
- meal optimizer
- targetCalories akışı
- meal_type normalize
- 1 ana + 2 alternatif hard gate
- ara öğün alternatifleri
- final plan validator
- local DB setup
- Supabase local CLI
- local → remote migration akışı

Kural:
Kod, DB, migration, validator veya CI varsa ilk uzman Sonnet’tir.

### Opus — Chief Product & Strategy / Ürün / UX / Kurallar

Opus’a gidecek konular:
- ürün vizyonu
- kullanıcı deneyimi
- meal card akışı
- Coach Center akışı
- onboarding dili
- kullanıcıyı suçlamayan koç dili
- feature çakışması
- roadmap sadeleştirme
- ürün metinleri
- doküman dili
- “Bu kullanıcıyı yorar mı?” türü kararlar

Kural:
Kullanıcı ekranı, kavram, UX, metin veya ürün hissi varsa Opus’a gidilir.

### Gemini — Researcher / Web / Best Practice

Gemini’ye gidecek konular:
- dünyadaki diyet/fitness app örnekleri
- MyFitnessPal, Yazio, Lifesum, MacroFactor, Noom gibi rakipler
- açık kaynak repo araştırması
- OpenNutriTracker, wger, Mealie, OpenFoodFacts, USDA/FDC gibi kaynaklar
- güncel best-practice araştırması
- global/Türk yemek DB stratejisi
- barcode/foto logging örnekleri

Kural:
“Dünyada başkaları nasıl yapmış?” sorusu varsa Gemini’ye gidilir.

## 3. ZindeAI Proje Gerçeği

ZindeAI / zindeV2:
- Flutter + Dart + Supabase/PostgreSQL mobil uygulamasıdır.
- React, Next.js, Vite veya web projesi değildir.
- Sıfırdan yazılmayacaktır.
- Mevcut ZindeV2 repo üzerinden ilerleyecektir.
- Ana hedef Türkçe öncelikli, foto-first, makro doğruluğu yüksek, alternatifli diyet + fitness koçudur.

Ana vaat:
“Fotoğraf çek, hedefini söyle, kalan gününü ZindeAI ayarlasın.”

## 4. Nutrition Engine Temel Kuralları

- AI makro hesaplamaz.
- AI yemek planını serbest metinle üretmez.
- Makro hesabı DB + optimizer + validator tarafından yapılır.
- Plan hedef dışıysa valid sayılmaz.
- Her öğünde 1 ana + 2 alternatif hedeflenir.
- Ara öğünler de 1 ana + 2 alternatif desteklemelidir.
- Alternatifler makro denk olmalıdır.
- Meal type contract:
  - kahvalti
  - ara_ogun_1
  - ogle
  - ara_ogun_2
  - aksam
  - gece_atistirmasi

Bilinen teknik riskler:
- get_best_fit_foods içinde 500 kcal sabiti
- targetCalories değerinin RPC’ye gitmemesi
- gece_atistirma / gece_atistirmasi isim farkı
- alternatiflerin hard gate olmaması
- plan validator’ın final hard gate olmaması
- raw/cooked besin ayrımı yoksa makro sapması
- mobil app içinde LLM API key tutulması

## 5. AI Coach Kullanım Kuralı

AI coach her öğün kartının yanında chatbot değildir.

AI sınırlı kullanılacak yerler:
- onboarding
- foto yorumlama
- telafi açıklaması
- haftalık rapor
- serbest kullanıcı sorusu

AI kullanılmayacak yerler:
- her öğünde otomatik API çağrısı
- makro hesaplama
- DB yerine yemek uydurma
- her meal card yanında canlı chatbot

Meal card aksiyonları:
- Değiştir
- Neden bu?
- Yedim
- Yemedim

“Neden bu?” açıklaması mümkün olduğunca deterministic template ile üretilir.

## 6. Local DB → GitHub → Supabase Çalışma Disiplini

Faz 0:
Local DB ve local migration doğrulama.

Faz 1:
Supabase local CLI veya Docker tabanlı Postgres ile prod şemaya yakın local ortam.

Faz 2:
Migration set’i GitHub üzerinden version control altında tutulur.

Faz 3:
CI içinde:
- validate-db
- seed validator
- plan validator
- flutter analyze
- flutter test

Faz 4:
Supabase remote/prod ortamına geçiş sadece local migration doğrulandıktan sonra yapılır.

Kural:
Local DB test edilmeden, migration/validator çalışmadan GitHub’a riskli DB değişikliği pushlanmaz.

## 7. Değişiklik İsteği Formatı

Her değişiklik isteğinde GPT mentor şu formatta cevap verir:

### Değişiklik tipi
DB / Kod / Validator / UX / Ürün / Research / Karma

### İlk uzman
Sonnet / Opus / Gemini

### Neden
Bu işi neden o model incelemeli?

### Kullanılacak prompt
İlgili modele verilecek temiz prompt.

### Sonraki adım
Çıktıyı getir, GPT mentor final yönlendirmeyi yapsın.

## 8. PR ve Merge Disiplini

- Main’e direkt push yok.
- Her iş branch ile yapılır.
- Her iş PR ile main’e önerilir.
- PR açılmadan “tamamlandı” sayılmaz.
- PR merge edilmeden önce GPT mentor review gerekir.
- Test/analyze sonucu yoksa merge yok.
- Secret/API key varsa merge yok.
- React/web rewrite varsa merge yok.
- Scope dışı değişiklik varsa merge yok.

## 9. İlk Büyük İnceleme Sırası

Önce Sonnet:
- nutrition engine audit
- local Supabase/Postgres planı
- targetCalories RPC fix planı
- meal_type normalize planı
- alternatives hard gate planı
- ara öğün alternatifleri
- validator hard gate

Sonra Opus:
- meal card UX
- Coach Center
- “Neden bu?” açıklama dili
- kullanıcıyı suçlamayan telafi dili
- ürün akışı sadeleştirme

Sonra Gemini:
- rakip uygulama best-practice
- açık kaynak repo karşılaştırması
- Türk DB / global DB stratejisi
- barcode/foto logging örnekleri

## 10. Final Karar Kuralı

Sonnet teknik uygulanabilirliği söyler.
Opus ürün/UX kararını netleştirir.
Gemini dış dünya kanıtını getirir.
GPT mentor final kararı verir.

Bu dosya, ZindeAI’de ajanların ve insan geliştiricilerin ortak çalışma protokolüdür.

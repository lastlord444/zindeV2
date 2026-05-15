# Agent İş Akışı (Agent Workflow)

- Her görevden önce `AGENTS.md` ve `docs/ai/` altındaki tüm dosyalar okunacaktır.
- Her iş, `main` branch'ten yeni bir branch açılarak başlayacaktır.
- `main` branch'ine doğrudan push yapmak YASAKTIR.
- Görevler (scope) her zaman küçük tutulmalıdır.
- Eğer kod değişikliği varsa, mutlaka sırasıyla şu komutlar çalıştırılacaktır:
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test`
- Herhangi bir komut başarısız olursa, hata aynen rapora yazılacaktır.
- İş bitiminde her zaman PR açılacaktır.
- Açılan PR ajanlar tarafından **merge edilmeyecektir**.
- Kullanıcı (Mehmet) PR linkini GPT mentora gönderecektir.
- GPT mentor onay vermeden hiçbir şekilde merge işlemi yapılmayacaktır.

## ZindeMentor Değişiklik Sınıflandırma Protokolü

Her yeni değişiklik isteğinde önce şu sınıflandırma yapılır:

1. Teknik/Kod/DB ise:
   - Supabase/Postgres
   - migration
   - RLS
   - RPC
   - Edge Function
   - validator
   - CI
   - Flutter mimari
   - test/gate
   → İlk uzman: Sonnet

2. Ürün/UX ise:
   - ekran akışı
   - meal card düzeni
   - Coach Center
   - kullanıcı dili
   - onboarding
   - özellik sadeleştirme
   - roadmap
   → İlk uzman: Opus

3. Araştırma ise:
   - rakip app analizi
   - diet/fitness app best-practice
   - açık kaynak repo karşılaştırması
   - güncel teknoloji araştırması
   → İlk uzman: Gemini

4. Karma iş ise:
   - önce riskli teknik taraf Sonnet
   - sonra ürün akışı Opus
   - gerekirse araştırma Gemini
   - final karar GPT mentor

# ZindeV2 Agents Truth

- **Mevcut Proje:** Bu proje Flutter + Supabase/PostgreSQL tabanlı bir mobil uygulamadır.
- **YASAKLAR:** 
  - React, Next.js veya web projesi olarak rewrite yapılması KESİNLİKLE YASAKTIR.
  - Projeyi sıfırdan yazmak YASAKTIR.
  - Mevcut ZindeV2 reposu üzerinden ilerleme zorunludur.
  - `main` branch'ine doğrudan push yapmak YASAKTIR.
- **İş Akışı:** 
  - Her iş yeni bir branch açılarak ve Pull Request (PR) ile yapılmalıdır.
  - GPT mentor tarafından review edilmeden hiçbir PR merge edilemez.
- **Raporlama:** Türkçe raporlama zorunludur.
- **Önkoşul:** Her görevden önce `docs/ai` klasöründeki dosyalar okunmalıdır.
- Her büyük değişiklikte ZindeMentor protokolü uygulanır.
- Değişiklik önce sınıflandırılır:
  - DB / schema / validator / CI / backend / Supabase / Edge Function / kod mimarisi → önce Sonnet
  - ürün vizyonu / UX / ekran akışı / metin / kavram / kural sadeleştirme → önce Opus
  - dış dünya araştırması / rakip / best-practice / açık kaynak repo inceleme → önce Gemini
- Karma işlerde önce en riskli teknik taraf Sonnet’e sorulur, sonra ürün/UX için Opus’a gidilir.
- GPT mentor final karar verene kadar PR merge edilmez.

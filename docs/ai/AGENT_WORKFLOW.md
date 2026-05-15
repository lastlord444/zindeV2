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

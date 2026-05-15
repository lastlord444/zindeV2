---
name: zinde-agent-review
description: PR review standartlarını ve proje sınırlarını kontrol eder.
---

# Zinde Agent Review Yeteneği

PR Review yaparken şu checklist kontrol edilmelidir:

- [ ] `main` branch'ine doğrudan push yapılmaya çalışılmış mı? (YASAK)
- [ ] PR içinde secret key veya API key (LLM vb.) var mı? (Eğer varsa reddet)
- [ ] Scope creep (istenen görev dışına çıkılmış mı) durumu var mı?
- [ ] Gerekli `flutter test` veya `flutter analyze` adımları eksik mi?
- [ ] Projeye React/Web dosyası eklenmiş mi? (YASAK)
- [ ] Ara öğün alternatif şartı bozulmuş mu? (Her öğünde 1 ana + 2 alternatif zorunlu)

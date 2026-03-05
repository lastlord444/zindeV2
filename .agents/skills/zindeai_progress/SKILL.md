---
description: ZindeAI V2.0 inşa sürecindeki ilerlemeyi takip eder - her oturumda okunmalı ve güncellenmeli
---

# ZindeAI V2.0 - İlerleme Takip Skill

## 📖 Nasıl Kullanılır

1. **Her oturumun başında**: `d:\zindeV.2.0\.agents\PROGRESS.md` dosyasını oku
2. **Her tamamlanan görevden sonra**: PROGRESS.md dosyasını güncelle (`[x]` işaretle)
3. **Kaldığın yerden devam et**: `[/]` işaretli görevden başla

## 📝 İlerleme Dosyası

Konum: `d:\zindeV.2.0\.agents\PROGRESS.md`

Bu dosya şu bölümleri içerir:
- Genel proje durumu
- Katman bazlı tamamlanma yüzdesi
- Görev listesi ([ ] / [/] / [x])
- Son oturumda yapılanlar
- Karşılaşılan sorunlar

## 🔄 Güncelleme Formatı

```markdown
## Son Oturum: [TARİH]
**Yapılanlar:**
- [x] Tamamlanan görev
- [/] Devam eden görev

**Karşılaşılan Sorunlar:**
- Sorun varsa buraya yaz
```

## ⚡ Otomatik Kurallar

- Bir dosya yazılmadan `[x]` işaretleme
- PROGRESS.md'yi güncellemeden oturumu kapatma
- Hata durumlarını kaydetmeyi unutma

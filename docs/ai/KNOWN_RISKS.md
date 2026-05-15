# Bilinen Riskler (Known Risks)

- `get_best_fit_foods` içindeki 500 kcal sabiti.
- `targetCalories` değerinin RPC'ye gitmiyor olabilmesi.
- `meal_type` isimlendirme uyuşmazlığı (`gece_atistirma` vs `gece_atistirmasi`).
- Alternatiflerin henüz "hard gate" (kesin geçerlilik koşulu) olmaması.
- Ara öğün alternatifleri garanti edilmezse planın kırılabilmesi.
- AI'nin her öğünde kullanılması durumunda maliyetlerin patlaması.
- Mobil uygulamada API key tutulursa yaşanacak güvenlik zafiyetleri.
- Plan validator "hard gate" değilse kullanıcının sisteme olan güveninin bozulması.
- Raw (çiğ) / Cooked (pişmiş) besin ayrımı yapılmadığı takdirde makro sapmalarının yaşanması.
- Türk DB doğrulanmadan Global DB'ye geçilmesi durumunda genel kalitenin düşmesi.

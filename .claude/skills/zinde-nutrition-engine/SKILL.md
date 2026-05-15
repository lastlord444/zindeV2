---
name: zinde-nutrition-engine
description: Beslenme motoru kurallarını (makro, kalori, alternatif) yönetir.
---

# Zinde Nutrition Engine Yeteneği

- **Makro ve Kalori:** AI hiçbir şekilde makro hesaplaması veya tahmini YAPMAYACAKTIR. Bu işlem veritabanı, optimizer ve validator tarafından yapılmaktadır.
- **Hedef Kalori (targetCalories):** Tüm öğün kalori sınırları RPC'ye doğru bir şekilde gitmeli ve oradan gelmelidir.
- **Öğün Tipleri (meal_type):** Sistemde kayıtlı öğün tipleri dışında bir değer kullanılamaz.
- **Alternatifler:** 
  - Her ana öğünün yanında kesinlikle 2 makro denk alternatif bulunmalıdır.
  - Ara öğünlerde de "1 ana + 2 alternatif" kuralı ZORUNLUDUR.
- **Validasyon:** Önerilen alternatifler, ana yemeğin makro oranlarıyla denk ve tolerans sınırları içinde olmalıdır.

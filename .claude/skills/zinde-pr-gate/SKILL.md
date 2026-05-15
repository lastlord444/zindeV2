---
name: zinde-pr-gate
description: Merge kapısı kurallarını işletir.
---

# Zinde PR Gate Yeteneği

- Merge öncesi testler (`flutter test`) ve analizler (`flutter analyze`) başarılı bir şekilde çalıştırılmış olmalıdır. Sonuçlar PR'da yoksa merge kapısı kapalıdır.
- GPT mentoru tarafından inceleme ve ONAY verilmeden kesinlikle PR merge edilemez.

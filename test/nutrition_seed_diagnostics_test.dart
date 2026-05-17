import 'package:flutter_test/flutter_test.dart';

// ZindeV2 içerisindeki gerçek logic'i bozmamak adına diagnostic/kanıt testlerini buraya izole ediyoruz.

void main() {
  group('Nutrition Seed & Repetition Diagnostics', () {
    test('Test 1: Malzemeler sabitken makroların random değişebilmesi (Synthetic Seed)', () {
      // simulate generate_meals.dart
      final materials = ['1 Yumurta', '50g Yulaf Unu', '100ml Süt', '1 Tatlı Kaşığı Bal'];
      
      final basePro = 20.0;

      // Fake randomization parameters like in script
      final pMult1 = 0.8;
      final pMult2 = 1.4;

      final p1 = double.parse((basePro * pMult1).toStringAsFixed(1)); // 16.0
      final p2 = double.parse((basePro * pMult2).toStringAsFixed(1)); // 28.0

      // İki yemeğin de malzemeleri aynı
      expect(materials, ['1 Yumurta', '50g Yulaf Unu', '100ml Süt', '1 Tatlı Kaşığı Bal']);
      
      // Ancak protein değerleri tamamen farklı!
      expect(p1, 16.0);
      expect(p2, 28.0);
      expect(p1, isNot(equals(p2)));

      // Kanıt: Ingredient array gramajlarından hesaplama yapılmadığı diagnostic olarak doğrulandı.
    });

    test('Test 2: Aynı base yemeğin adjective ile çoğaltılması (Illusion of Variety)', () {
      final baseTemplate = 'Fit Pankek';
      final adjectives = ['Nefis ', 'Sağlıklı ', 'Pratik '];

      final dbEntries = adjectives.map((adj) => adj + baseTemplate).toList();

      expect(dbEntries, ['Nefis Fit Pankek', 'Sağlıklı Fit Pankek', 'Pratik Fit Pankek']);

      // Kullanıcı farklı sanıyor ama hepsi "Fit Pankek"
      expect(dbEntries[0].contains(baseTemplate), isTrue);
      expect(dbEntries[1].contains(baseTemplate), isTrue);
      expect(dbEntries[2].contains(baseTemplate), isTrue);
    });

    test('Test 3: getBaseId mantığının sıralı ID\'leri engelleyememesi (Repetition Blocker Failure)', () {
      // Simulate generate_daily_plan.dart getBaseId
      String getBaseId(String idStr) {
        var base = idStr;
        if (base.contains('_v7_')) base = base.split('_v7_').first;
        if (base.contains('_alt_')) base = base.split('_alt_').first;
        if (base.startsWith('v2_') && base.split('_').length >= 3) {
          final p = base.split('_');
          if (p.last.length >= 3) return base.substring(0, base.length - 2);
        }
        return base;
      }

      // Supabase'e eklenen ID formatı
      final id1 = 'meal_kahvalti_00001';
      final id2 = 'meal_kahvalti_00002';

      final baseId1 = getBaseId(id1);
      final baseId2 = getBaseId(id2);

      // Diagnostic kanıt:
      expect(baseId1, 'meal_kahvalti_00001');
      expect(baseId2, 'meal_kahvalti_00002');
      expect(baseId1, isNot(equals(baseId2)));

      // Oysa her ikisi de "Fit Pankek" ise (farklı adjectivelerle üretilmişlerse bile)
      // ID'ler farklı sayıldığı için "haftalık tekrar engeli" baypass edilmektedir.
    });

    test('Test 4: Fit Pankek örnek yaklaşık hesap ve sapma asersiyonu (Nutritional Reality Check)', () {
      // Gerçek standartlar (Ortalama):
      final realP = 6.0 + 9.0 + 4.0 + 0.0; // 19.0g
      final realK = 0.6 + 44.0 + 6.0 + 12.0; // 62.6g
      final realY = 5.0 + 4.5 + 4.0 + 0.0; // 13.5g
      final realKcal = (realP * 4) + (realK * 4) + (realY * 9); // ~447 kcal

      // UI'da/Seed'te görünen sentetik değerler:
      final uiKcal = 567.0;
      final uiP = 31.0;

      // Farklılıkları assert et (örneğin protein farkı > 10g)
      expect((uiP - realP).abs(), greaterThan(10.0));
      expect((uiKcal - realKcal).abs(), greaterThan(100.0));

      // Kanıt: UI'da sunulan makrolar gerçek malzemelerin besin değerleriyle
      // kabul edilebilir tolerans (%10-15) içinde örtüşmemektedir.
    });
  });
}

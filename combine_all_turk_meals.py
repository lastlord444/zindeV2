import json
import os

# 5 part dosyasini birleştir ve meals_mega_batch.json'a yaz
parts = [
    'assets/data/meals_healthy_turk_part1.json',
    'assets/data/meals_healthy_turk_part2.json',
    'assets/data/meals_healthy_turk_part3.json',
    'assets/data/meals_healthy_turk_part4.json',
    'assets/data/meals_healthy_turk_part5.json',
]

all_meals = []
for part_file in parts:
    if os.path.exists(part_file):
        with open(part_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            all_meals.extend(data)
            print(f'{part_file}: {len(data)} yemek yuklendi')
    else:
        print(f'UYARI: {part_file} bulunamadi!')

print(f'\nToplam: {len(all_meals)} yemek')

# Ogun bazinda say
ogun_sayilari = {}
for m in all_meals:
    ogun = m.get('ogun', 'bilinmiyor')
    ogun_sayilari[ogun] = ogun_sayilari.get(ogun, 0) + 1

print('\nOgun bazinda dagilim:')
for ogun, sayi in sorted(ogun_sayilari.items()):
    print(f'  {ogun}: {sayi}')

# Eski dosyayi yedekle
eski_dosya = 'assets/data/meals_mega_batch.json'
if os.path.exists(eski_dosya):
    yedek = 'assets/data/meals_mega_batch_BACKUP.json'
    os.rename(eski_dosya, yedek)
    print(f'\nEski dosya yedeklendi: {yedek}')

# Yeni dosyaya kaydet
with open(eski_dosya, 'w', encoding='utf-8') as f:
    json.dump(all_meals, f, ensure_ascii=False, indent=2)

print(f'\n{eski_dosya} dosyasina {len(all_meals)} yemek yazildi!')
print('TAMAMLANDI!')

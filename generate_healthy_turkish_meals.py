import json
import uuid

# Turk Mutfagi Saglikli Yemek Veritabani Olusturucu
# Her yemegin 2 alternatifi var

def create_turkish_meal(meal_id, base_name, ogun_tipi, kalori, protein, karbo, yag, 
                         malzemeler, tarif, zorluk="kolay"):
    """Ana yemek olustur"""
    return {
        'id': f'turk_{meal_id}',
        'ad': base_name,
        'ogun': ogun_tipi,
        'kalori': kalori,
        'protein': protein,
        'karbonhidrat': karbo,
        'yag': yag,
        'malzemeler': malzemeler,
        'alternatifler': [],
        'alternatifYemekler': [],
        'hazirlamaSuresi': 25 if zorluk == 'orta' else 15,
        'zorluk': zorluk,
        'etiketler': ['saglikli', 'dogal', 'yagli', 'proteinli'],
        'tarif': tarif,
        'gorselUrl': None,
        'proteinKaynagi': malzemeler[0].split()[1] if len(malzemeler[0].split()) > 1 else 'Karbonhidrat',
        'baseWeightG': 200.0,
        'dominantMacro': 'protein',
        'minMultiplier': 0.5,
        'maxMultiplier': 2.0,
        'unitName': 'gram'
    }

# Part 1: Kahvalti Yemekleri
def generate_part1():
    part1_meals = []
    
    protein_sources = [
        ('Yumurta', 6), ('Beyaz Peynir', 10), ('Kasar Peyniri', 8), ('Sut', 8),
        ('Yulaf', 12), ('Tavuk Gogsu', 25), ('Jambon', 15), ('Feta', 15),
        ('Muz', 1), ('Cilek', 1), ('Yaban Mersini', 1), ('Avokado', 15),
        ('Badem', 6), ('Ceviz', 7), ('Keten Tohumu', 5), ('Chia', 5)
    ]
    
    carb_sources = [
        ('Tam Bugday', 60), ('Cavdar', 55), ('Yulaf Ezmesi', 50),
        ('Karabugday', 55), ('Pilav', 45), ('Bulgur', 50), ('Makarna', 45),
        ('Patates', 17), ('Tosek Ekmek', 30), ('Kepek Ekmek', 30),
        ('Yulaf', 12), ('Karisik Sebze', 20)
    ]
    
    veg_sources = [
        ('Domates', 20), ('Salatalik', 30), ('Yesillik', 50), ('Biber', 25),
        ('Patlican', 30), ('Kabak', 20), ('Lahana', 25), ('Pirasa', 25),
        ('Ispanak', 30), ('Marul', 15), ('Hiyar', 20), ('Turp', 20)
    ]
    
    idx = 0
    guid = uuid.uuid4().hex[:8]
    
    for i in range(1000):
        protein = protein_sources[i % len(protein_sources)]
        carb = carb_sources[i % len(carb_sources)]
        veg = veg_sources[i % len(veg_sources)]
        
        p_cal = protein[1] * 4
        c_cal = carb[1] * 4
        v_cal = veg[1] * 0.2
        f_cal = 100
        total_cal = p_cal + c_cal + v_cal + f_cal + 50
        
        final_protein = protein[1]
        final_carb = carb[1]
        final_fat = 15 + (i % 10)
        
        meal_name = f"Turk Kahvaltasi #{idx+1:03d} - {protein[0]} & {carb[0]}"
        
        malzemeler = [
            f'{protein[1]}g {protein[0]}',
            f'{carb[1]}g {carb[0]}',
            f'{veg[1]}g {veg[0]}',
            f'{final_fat}g Zeytinyagi',
            f'{2 + (i%3)} adet Domates'
        ]
        
        tarif = f"{protein[0]} ve {carb[0]} ile {veg[0]} yemegi. Zeytinyagi, tuz ve kekik ile servis yap."
        
        yemek = create_turkish_meal(
            meal_id=f'{guid}_{idx}',
            base_name=meal_name,
            ogun_tipi='kahvalti',
            kalori=total_cal,
            protein=final_protein,
            karbo=final_carb,
            yag=final_fat,
            malzemeler=malzemeler,
            tarif=tarif,
            zorluk='kolay' if i < 700 else 'orta'
        )
        
        part1_meals.append(yemek)
        idx += 1
    
    return part1_meals

# Part 2: Oglen Yemekleri
def generate_part2():
    part2_meals = []
    
    lunch_proteins = [
        ('Tavuk Gogsu Izgara', 150), ('Kirmizi Et', 140), ('Somon Fileto', 130),
        ('Ton Baligi Konserve', 100), ('Hindi', 120), ('Dana Kiyma', 120),
        ('Tavuk Sote', 110), ('Kofte', 80), ('Yumurta Menemen', 110),
        ('Shakshuka', 90), ('Karniyarik', 110), ('Etli Pilav', 130)
    ]
    
    lunch_carbs = [
        ('Pilav', 200), ('Bulgur Pilav', 180), ('Makarna', 180),
        ('Noodle', 150), ('Eriste', 180), ('Couscous', 160),
        ('Patates', 150), ('Kabak', 120), ('Bamya', 100),
        ('Mercimek', 160), ('Pirinc', 150), ('Barley', 140)
    ]
    
    lunch_vegs = [
        ('Salata', 100), ('Sebze Dolmasi', 200), ('Yahni', 150),
        ('Borulce', 200), ('Ezme', 200), ('Domates Yahnisi', 180),
        ('Patlican Kizartmasi', 150), ('Karnabahar', 180), ('Lahmacun', 250),
        ('Patates Sote', 150), ('Ispanakli Yumurta', 140)
    ]
    
    idx = 0
    guid = uuid.uuid4().hex[:8]
    
    for i in range(1000):
        protein = lunch_proteins[i % len(lunch_proteins)]
        carb = lunch_carbs[i % len(lunch_carbs)]
        veg = lunch_vegs[i % len(lunch_vegs)]
        
        total_cal = protein[1] * 4 + carb[1] * 4 + veg[1] * 0.25 + 80
        final_protein = protein[1]
        final_carb = carb[1]
        final_fat = 15 + (i % 12)
        
        meal_name = f"Turk Ogle Yemegi #{idx+1:03d} - {protein[0]} & {veg[0]}"

        veg_gram = veg[1] if isinstance(veg, tuple) and len(veg) > 1 else 100

        malzemeler = [
            f'{protein[1]}g {protein[0]}',
            f'{carb[1]}g {carb[0]}',
            f'{veg_gram}g {veg[0]}',
            f'{final_fat}g Zeytinyagi',
            'Tuz, Baharat'
        ]

        tarif = f"{protein[0]} {carb[0]} ve {veg[0]} ile pisirilir. Zeytinyagi ve baharat ile lezzetlendirilir."

        yemek = create_turkish_meal(
            meal_id=f'{guid}_{idx}',
            base_name=meal_name,
            ogun_tipi='ogle',
            kalori=total_cal,
            protein=final_protein,
            karbo=final_carb,
            yag=final_fat,
            malzemeler=malzemeler,
            tarif=tarif,
            zorluk='kolay' if i < 600 else 'orta'
        )

        part2_meals.append(yemek)
        idx += 1

    return part2_meals

# Part 3: Aksam Yemekleri
def generate_part3():
    part3_meals = []
    
    dinner_proteins = [
        ('Izgara Somon', 140), ('Firin Tavuk', 180), ('Firin Hindi', 170),
        ('Izgara Dana Biftek', 200), ('Kuzu Izgara', 190), ('Alabalik Izgara', 160),
        ('Tavuk Sote', 110), ('Kofte', 80), ('Yumurta Menemen', 110),
        ('Karidis Guvec', 100), ('Kalamar Tava', 120), ('Hamsi Izgara', 130)
    ]
    
    dinner_carbs = [
        ('Pilav', 150), ('Bulgur', 130), ('Sebzeli Pilav', 140),
        ('Eriste', 120), ('Noodle', 100), ('Makarna', 120),
        ('Patates', 120), ('Kabak Firin', 100), ('Bamya Sote', 100)
    ]
    
    dinner_vegs = [
        ('Firin Sebze', 200), ('Sebze Izgara', 200), ('Salata', 120),
        ('Yahni', 150), ('Borulce', 180), ('Dolma', 150),
        ('Sarimsakli Yoghurt', 100), ('Cacik', 100), ('Tursu', 80)
    ]
    
    idx = 0
    guid = uuid.uuid4().hex[:8]
    
    for i in range(1000):
        protein = dinner_proteins[i % len(dinner_proteins)]
        carb = dinner_carbs[i % len(dinner_carbs)]
        veg = dinner_vegs[i % len(dinner_vegs)]
        
        total_cal = protein[1] * 4 + carb[1] * 4 + veg[1] * 0.3 + 100
        final_protein = protein[1]
        final_carb = carb[1]
        final_fat = 18 + (i % 14)
        
        meal_name = f"Turk Aksam Yemegi #{idx+1:03d} - {protein[0]} & {veg[0]}"

        veg_name = veg[0] if isinstance(veg, str) else 'Sebze'
        veg_gram = veg[1] if isinstance(veg, tuple) and len(veg) > 1 else 100

        malzemeler = [
            f'{protein[1]}g {protein[0]}',
            f'{carb[1]}g {carb[0]}',
            f'{veg_gram}g {veg_name}',
            f'{final_fat}g Zeytinyagi',
            'Tuz, Baharat, Limon'
        ]

        tarif = f"{protein[0]} {carb[0]} ile {veg_name} ile firinda pisirilir. Zeytinyagi ve limonla servis yap."

        yemek = create_turkish_meal(
            meal_id=f'{guid}_{idx}',
            base_name=meal_name,
            ogun_tipi='aksam',
            kalori=total_cal,
            protein=final_protein,
            karbo=final_carb,
            yag=final_fat,
            malzemeler=malzemeler,
            tarif=tarif,
            zorluk='kolay' if i < 500 else 'orta'
        )

        part3_meals.append(yemek)
        idx += 1

    return part3_meals

# Ana fonksiyon
def main():
    print('Turk Mutfagi Saglikli Yemekler Olusturuluyor...')
    print()
    
    # Part 1
    print('Part 1: Kahvalti yemekleri olusturuluyor...')
    part1 = generate_part1()
    with open('assets/data/meals_healthy_turk_part1.json', 'w', encoding='utf-8') as f:
        json.dump(part1, f, ensure_ascii=False, indent=2)
    print(f'  -> {len(part1)} kahvalti yemegi tamamlandi')
    
    # Part 2
    print('Part 2: Ogle yemekleri olusturuluyor...')
    part2 = generate_part2()
    with open('assets/data/meals_healthy_turk_part2.json', 'w', encoding='utf-8') as f:
        json.dump(part2, f, ensure_ascii=False, indent=2)
    print(f'  -> {len(part2)} ogle yemegi tamamlandi')
    
    # Part 3
    print('Part 3: Aksam yemekleri olusturuluyor...')
    part3 = generate_part3()
    with open('assets/data/meals_healthy_turk_part3.json', 'w', encoding='utf-8') as f:
        json.dump(part3, f, ensure_ascii=False, indent=2)
    print(f'  -> {len(part3)} aksam yemegi tamamlandi')
    
    print()
    print('='*50)
    print(f'TOPLAM: {len(part1) + len(part2) + len(part3)} saglikli yemek!')
    print('='*50)
    print()
    print('SONRAKI ADIM: python combine_turkish_meals.py')

if __name__ == '__main__':
    main()

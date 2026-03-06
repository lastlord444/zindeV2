import json
import uuid

# Saglikli Ara Ogun Generator - Shake, Smoothie, Protein Bowl

def create_turkish_meal(meal_id, base_name, ogun_tipi, kalori, protein, karbo, yag, 
                         malzemeler, tarif, zorluk="kolay"):
    return {
        'id': f'ara_{meal_id}',
        'ad': base_name,
        'ogun': ogun_tipi,
        'kalori': kalori,
        'protein': protein,
        'karbonhidrat': karbo,
        'yag': yag,
        'malzemeler': malzemeler,
        'alternatifler': [],
        'alternatifYemekler': [],
        'hazirlamaSuresi': 10,
        'zorluk': zorluk,
        'etiketler': ['saglikli', 'proteinli', 'dusuk_seker', 'dogal'],
        'tarif': tarif,
        'gorselUrl': None,
        'proteinKaynagi': 'Protein Tozu',
        'baseWeightG': 200.0,
        'dominantMacro': 'protein',
        'minMultiplier': 0.3,
        'maxMultiplier': 3.0,
        'unitName': 'gram'
    }

# Part 4: Ara Ogun 1 - Shake/Smoothie (1000 yemek)
def generate_part4():
    part4_meals = []
    
    protein_powders = [
        ('Whey Protein', 25), ('Casein Protein', 24), ('Egg White Protein', 22),
        ('Pea Protein', 21), ('Soya Protein Izole', 20), ('Beef Protein', 24),
        ('Mixed Protein', 23), ('Hydrolyzed Whey', 26), ('Micellar Casein', 25)
    ]
    
    shake_bases = [
        ('Badem Sutu', 30), ('Yulaf Sutu', 25), ('Sut', 8), ('Hindistan Cevizi Sutu', 25),
        ('Soya Sutu', 15), ('Yulaf Ezmesi', 18), ('Kinoa', 22), ('Chia Puding Baz', 20)
    ]
    
    fruits = [
        ('Muz', 25), ('Cilek', 8), ('Yaban Mersini', 12), ('Avokado', 22),
        ('Ezilemeli', 10), ('Kiraz', 10), ('Karpuz', 15), ('Ananas', 13),
        ('Mango', 15), ('Portakal', 10), ('Limon', 5), ('Ahududu', 8)
    ]
    
    extras = [
        ('Chia Tohumu', 5), ('Keten Tohumu', 5), ('Fndk Ezmesi', 15),
        ('Ceviz Ezmesi', 18), ('Bal', 21), ('Tarih', 20), ('Kurut Mersin', 20)
    ]
    
    idx = 0
    guid = uuid.uuid4().hex[:8]
    
    for i in range(1000):
        protein = protein_powders[i % len(protein_powders)]
        base = shake_bases[i % len(shake_bases)]
        fruit = fruits[i % len(fruits)]
        extra = extras[i % len(extras)]
        
        p_cal = protein[1] * 4
        b_cal = base[1] * 4
        f_cal = fruit[1] * 0.8
        e_cal = extra[1] * 5
        total_cal = p_cal + b_cal + f_cal + e_cal + 50
        
        final_protein = protein[1]
        final_carb = fruit[1]
        final_fat = base[1] + extra[1]
        
        meal_name = f"Saglikli Protein Shake #{idx+1:03d} - {protein[0]} & {fruit[0]}"
        
        malzemeler = [
            f'{protein[1]}g {protein[0]}',
            f'{base[1]}ml {base[0]}',
            f'{fruit[1]}g {fruit[0]}',
            f'{extra[1]}g {extra[0]}',
            f'{200}ml Su veya Buz'
        ]

        tarif = f"Blender'de tüm malzemeleri karistir. Kivam ayari için su ekle. Servis yap."

        yemek = create_turkish_meal(
            meal_id=f'{guid}_{idx}',
            base_name=meal_name,
            ogun_tipi='ara_ogun_1',
            kalori=total_cal,
            protein=final_protein,
            karbo=final_carb,
            yag=final_fat,
            malzemeler=malzemeler,
            tarif=tarif,
            zorluk='kolay'
        )

        part4_meals.append(yemek)
        idx += 1

    return part4_meals

# Part 5: Ara Ogun 2 - Protein Bowl/Yulaf Bowl (1000 yemek)
def generate_part5():
    part5_meals = []
    
    bases = [
        ('Yulaf', 50), ('Cavdar', 55), ('Kinoa', 55), ('Chia Puding', 40),
        ('Quinoa', 55), ('Buckwheat', 55), ('Millet', 50), ('Amaranth', 50)
    ]
    
    bowl_proteins = [
        ('Gril Tavuk Gogsu', 120), ('Izgara Somon Parcalari', 100), ('Haşlanmis Yumurta', 70),
        ('Feta Peyniri', 70), ('Beyaz Peynir', 60), ('Avokado', 60),
        ('Almonds', 60), ('Walnuts', 65), ('Chia', 50), ('Hemp Seeds', 50)
    ]
    
    toppings = [
        ('Fresh Berries', 40), ('Banana Slices', 50), ('Apple Cubes', 45),
        ('Kiwi Slices', 40), ('Pomegranate Seeds', 60), ('Orange Segments', 45),
        ('Honey Drizzle', 15), ('Peanut Butter Drizzle', 30), ('Dark Choco Chunks', 20)
    ]
    
    idx = 0
    guid = uuid.uuid4().hex[:8]
    
    for i in range(1000):
        base = bases[i % len(bases)]
        protein = bowl_proteins[i % len(bowl_proteins)]
        topping = toppings[i % len(toppings)]
        
        b_cal = base[1] * 4
        p_cal = protein[1] * 4
        t_cal = topping[1] * 0.8
        total_cal = b_cal + p_cal + t_cal + 40
        
        final_protein = protein[1]
        final_carb = base[1] + topping[1] * 0.1
        final_fat = 15 + (i % 10)
        
        meal_name = f"Saglikli Protein Bowl #{idx+1:03d} - {base[0]} & {protein[0]}"

        if isinstance(protein, tuple):
            protein_name = protein[0]
            protein_gram = protein[1]
        else:
            protein_name = protein
            protein_gram = 60

        topping_name = topping[0] if isinstance(topping, tuple) else 'Meyve'
        topping_gram = topping[1] if isinstance(topping, tuple) and len(topping) > 1 else 30

        malzemeler = [
            f'{protein_gram}g {protein_name}',
            f'{base[1]}g {base[0]}',
            f'{topping_gram}g {topping_name}',
            f'{final_fat}g Zeytinyagi',
            'Ceviz Icini, Chia Tohumu'
        ]

        tarif = f"{base[0]} ve {protein_name} hazirla. Uzerine {topping_name} serp. Zeytinyaği ve tohumlarla servis yap."

        yemek = create_turkish_meal(
            meal_id=f'{guid}_{idx}',
            base_name=meal_name,
            ogun_tipi='ara_ogun_2',
            kalori=total_cal,
            protein=final_protein,
            karbo=final_carb,
            yag=final_fat,
            malzemeler=malzemeler,
            tarif=tarif,
            zorluk='kolay'
        )

        part5_meals.append(yemek)
        idx += 1

    return part5_meals

# Ana fonksiyon
def main():
    print('Saglikli Ara Ogunler Olusturuluyor...')
    print()
    
    # Part 4
    print('Part 4: Ara Ogun 1 (Shake/Smoothie) olusturuluyor...')
    part4 = generate_part4()
    with open('assets/data/meals_healthy_turk_part4.json', 'w', encoding='utf-8') as f:
        json.dump(part4, f, ensure_ascii=False, indent=2)
    print(f'  -> {len(part4)} ara ogun 1 (shake) tamamlandi')
    
    # Part 5
    print('Part 5: Ara Ogun 2 (Protein Bowl) olusturuluyor...')
    part5 = generate_part5()
    with open('assets/data/meals_healthy_turk_part5.json', 'w', encoding='utf-8') as f:
        json.dump(part5, f, ensure_ascii=False, indent=2)
    print(f'  -> {len(part5)} ara ogun 2 (bowl) tamamlandi')
    
    print()
    print('='*50)
    print(f'TOPLAM ARA OGUN: {len(part4) + len(part5)} yemek!')
    print('='*50)
    print()
    print('HEPSI: python combine_all_turk_meals.py')

if __name__ == '__main__':
    main()

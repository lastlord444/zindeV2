import os

root_dir = r"d:\zindeV.2.0\lib"

replacements = {
    "'=%'": "'🔥'",
    "'='": "'🥩'",
    "' xa'": "'🍞'",
    "'>Q'": "'🥑'",
    "=% Tolerans limiti": "Tolerans limiti",
    "// =% ": "// ",
    "// =%": "//",
    "'=% Gnlk Kalori'": "'🔥 Günlük Kalori'",
    "'=% En Yksek Kalori'": "'🔥 En Yüksek Kalori'",
    "'  Yedi inizi belirttiniz. Onaylamak iin \"Onayla\" butonuna bas1n.'": "'Yediğinizi belirttiniz. Onaylamak için \"Onayla\" butonuna basın.'",
    "'K0L0TLEND0'": "'KİLİTLENDİ'",
    "'Bu  n onayland1 ve rapor iin kaydedildi.'": "'Bu öğün onaylandı ve rapor için kaydedildi.'",
    "'YEMED0M'": "'YEMEDİM'",
    "'Bu  n yemediniz olarak i_aretlediniz.'": "'Bu öğünü yemediniz olarak işaretlediniz.'",
    "'S1f1rla'": "'Sıfırla'",
    "'Farkl1 Yemek Se'": "'Farklı Yemek Seç'",
    "'Size ba_ka seenekler buldum'": "'Size başka seçenekler buldum'",
    "'Şu an alternatif bulunamad1'": "'Şu an alternatif bulunamadı'",
    "'Alternatif Besin Bulunamad1'": "'Alternatif Besin Bulunamadı'",
    "Bu besin iin uygun alternatif bulunamad1": "Bu besin için uygun alternatif bulunamadı",
    "Ltfen farkl1 bir besin sein veya beslenme uzman1n1za dan1_1n": "Lütfen farklı bir besin seçin veya beslenme uzmanınıza danışın",
}

for root, dirs, files in os.walk(root_dir):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            try:
                with open(path, "r", encoding="utf-8") as f:
                    content = f.read()
                
                new_content = content
                for target, replacement in replacements.items():
                    new_content = new_content.replace(target, replacement)
                
                if new_content != content:
                    with open(path, "w", encoding="utf-8") as f:
                        f.write(new_content)
                    print(f"Fixed encoding in {path}")
            except Exception as e:
                print(f"Error reading {path}: {e}")

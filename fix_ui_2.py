import os

root_dir = r"d:\zindeV.2.0\lib"

replacements = {
    "Olu_tu": "Oluştu",
    "olu_tu": "oluştu",
    "Olu_tur": "Oluştur",
    "olu_tur": "oluştur",
    "t1klay1n": "tıklayın",
    "a_a\x1f1daki": "aşağıdaki",
    "plan1n1z1": "planınızı",
    "Al1_veri_": "Alışveriş",
    "al1_veri_": "alışveriş",
    "Yeniden Dene": "Yeniden Dene",  # just in case
    "plan1n1z": "planınız",
    "1_aret": "işaret",
    "kar_1la_": "karşılaş",
    "Gnlk": "Günlük",
    "gnlk": "günlük",
    "ba_ka": "başka",
    "seenek": "seçenek",
    "bulunamad1": "bulunamadı",
    "Bulunamad1": "Bulunamadı",
    "dan1_1n": "danışın",
    "zgnm": "Üzgünüm",
    "Ltfen": "Lütfen",
    "de i_tir": "değiştir",
    "": "ç", 
    "1": "ı", 
    "__": "ş",
}

# The single character replacements at the end are risky but since the codebase is small we will do multi-character words primarily first.

advanced_replacements = {
    "olu_turmak": "oluşturmak",
    "a_a1daki": "aşağıdaki",
    "plan1": "planı",
    "olmad11": "olmadığı",
    "anla_1ld1": "anlaşıldı",
    "bas1n": "basın",
    "yklendi": "yüklendi",
    "R": "🤖",
    " n": "öğün",
    "Gnlk": "Günlük",
    "gster": "göster",
    "iin": "için",
    "de\x1fer": "değer",
    "De\x1fer": "Değer",
    "a_a\x1f1": "aşağı",
    "sa\x1fl1k": "sağlık",
    "_\x1f": "şğ",
}

all_replacements = {**replacements, **advanced_replacements}


for root, dirs, files in os.walk(root_dir):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            try:
                with open(path, "r", encoding="utf-8") as f:
                    content = f.read()
                
                new_content = content
                
                # Apply word replacements safely
                for target, replacement in all_replacements.items():
                    new_content = new_content.replace(target, replacement)
                    
                # We specifically avoid doing single-char replacement of '1' -> 'ı' because it will break numbers
                # But we can replace specific UI broken words:
                
                if new_content != content:
                    with open(path, "w", encoding="utf-8") as f:
                        f.write(new_content)
                    print(f"Fixed encoding in {path}")
            except Exception as e:
                print(f"Error reading {path}: {e}")

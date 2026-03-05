import sys

file_path = 'lib/presentation/pages/profil_page.dart'
try:
    with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()

    for i, line in enumerate(lines):
        if 'Karbonhidrat' in line and '_buildMakroCard' not in line and 'gunlukKarbonhidrat' not in line:
            lines[i] = "                      '🥖 Karbonhidrat',\n"
        elif 'ak_am yemekleri' in line:
            lines[i] = "  Yeni akşam yemekleri\n"

    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print("Fixed remaining exact lines.")
except Exception as e:
    print("Error:", e)

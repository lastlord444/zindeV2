import os
import re

lib_dir = r"d:\zindeV.2.0\lib"

fixed_count = 0

for root, dirs, files in os.walk(lib_dir):
    for f in files:
        if f.endswith(".dart"):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                text = file.read()
            
            orig = text
            text = text.replace("🤖", "R")
            text = re.sub(r'öğün(?=[a-zA-Z_0-9])', ' n', text)
            
            text = text.replace("varöğün", "var n")
            text = text.replace("varöğüname", "var name")
            text = text.replace("returöğün", "return")
            text = text.replace("öğünull", " null")
            text = text.replace("öğünot", " not")
            text = text.replace("öğünew", " new")
            text = text.replace("öğünow", " now")
            text = text.replace("öğünumb", " numb")
            text = text.replace("öğüname", " name")
            
            # Revert 'ı' to '1' carefully
            text = re.sub(r'(?<=\W)ı(?=\W)', '1', text)
            text = re.sub(r'(?<=\W)ı(\d)', r'1\g<1>', text)
            text = re.sub(r'(\d)ı(\d)', r'\g<1>1\g<2>', text)
            text = re.sub(r'(\d)ı(?=\W)', r'\g<1>1', text)
            
            # DO NOT revert ş to __ generally unless it's super obvious.
            # I will skip `ş` -> `__` as it's too risky and probably there were none.
            
            if text != orig:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(text)
                fixed_count += 1

print(f"Fixed {fixed_count} files!")

import json
import urllib.request
import re

url = "http://127.0.0.1:54321/rest/v1/meals?select=meal_id,ad,tarif,malzemeler&limit=3"

# Gotta fetch the token
supabase_config_path = "lib/core/config/supabase_config.dart"
with open(supabase_config_path, "r", encoding="utf-8") as f:
    config_content = f.read()
    
match = re.search(r"defaultValue:\s*'([^']+)'", config_content)

if match:
    anon_key = match.group(1)
    req = urllib.request.Request(url, headers={
        "apikey": anon_key,
        "Authorization": f"Bearer {anon_key}",
    })
    
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode('utf-8'))
        print(json.dumps(data, indent=2, ensure_ascii=False))
else:
    print("Could not extract anon key")

import subprocess
import json

try:
    # Use psql to fetch data 
    result = subprocess.run(
        ["supabase", "db", "query", "SELECT meal_id, ad, tarif, malzemeler FROM meals LIMIT 3;"],
        capture_output=True, text=True
    )
    print("STDOUT:", result.stdout)
    print("STDERR:", result.stderr)
except Exception as e:
    print("Error:", e)

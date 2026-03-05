-- ============================================================================
-- ZindeAI V2.0 - MEALS TABLOSU
-- Tüm yemek havuzu burada saklanır (Supabase/PostgreSQL)
-- ============================================================================

CREATE TABLE IF NOT EXISTS meals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  meal_id TEXT UNIQUE NOT NULL,
  ad TEXT NOT NULL,
  ogun TEXT NOT NULL CHECK (ogun IN ('kahvalti', 'araOgun1', 'ogle', 'araOgun2', 'aksam', 'geceAtistirma', 'cheatMeal')),
  kalori DECIMAL(7,2) NOT NULL CHECK (kalori > 0),
  protein DECIMAL(6,2) NOT NULL CHECK (protein >= 0),
  karbonhidrat DECIMAL(6,2) NOT NULL CHECK (karbonhidrat >= 0),
  yag DECIMAL(6,2) NOT NULL CHECK (yag >= 0),
  malzemeler JSONB NOT NULL DEFAULT '[]'::JSONB,
  alternatifler JSONB DEFAULT '[]'::JSONB,
  hazirlama_suresi INTEGER NOT NULL DEFAULT 15,
  zorluk TEXT NOT NULL DEFAULT 'kolay' CHECK (zorluk IN ('kolay', 'orta', 'zor')),
  etiketler JSONB DEFAULT '[]'::JSONB,
  tarif TEXT,
  gorsel_url TEXT,
  protein_kaynagi TEXT,
  base_weight_g DECIMAL(7,2) DEFAULT 100,
  dominant_macro TEXT DEFAULT 'protein' CHECK (dominant_macro IN ('protein', 'carb', 'fat')),
  min_multiplier DECIMAL(3,2) DEFAULT 0.5,
  max_multiplier DECIMAL(4,2) DEFAULT 3.0,
  unit_name TEXT DEFAULT 'gram',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexler
CREATE INDEX IF NOT EXISTS idx_meals_ogun ON meals(ogun);
CREATE INDEX IF NOT EXISTS idx_meals_kalori ON meals(kalori);
CREATE INDEX IF NOT EXISTS idx_meals_etiketler ON meals USING gin(etiketler);

-- RLS (Public okuma - yemek havuzu herkese açık)
ALTER TABLE meals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Yemekler herkese açık" ON meals FOR SELECT USING (true);
CREATE POLICY "Sadece admin ekleyebilir" ON meals FOR INSERT WITH CHECK (false);
CREATE POLICY "Sadece admin güncelleyebilir" ON meals FOR UPDATE USING (false);
CREATE POLICY "Sadece admin silebilir" ON meals FOR DELETE USING (false);

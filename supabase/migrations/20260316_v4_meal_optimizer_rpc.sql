-- ============================================================================
-- Supabase Migration V4: Meal Optimizer RPC + User Meal Logs
-- 5280 yemeklik veritabanı için PostgreSQL-side filtreleme ve Euclidean Distance
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tablo: user_meal_logs
-- Kullanıcının "Yedim/Yemedim/Değiştirdim" raporları
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_meal_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    date DATE NOT NULL,
    meal_type TEXT NOT NULL CHECK (meal_type IN ('kahvalti', 'ara_ogun_1', 'ogle', 'ara_ogun_2', 'aksam', 'gece_atistirma')),
    food_id TEXT NOT NULL,
    consumed_grams NUMERIC NOT NULL,
    status TEXT NOT NULL DEFAULT 'yedi' CHECK (status IN ('yedi', 'yemedim', 'degistirdim')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index: user_meal_logs performansı için
CREATE INDEX IF NOT EXISTS idx_user_meal_logs_user_date ON public.user_meal_logs(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_user_meal_logs_food_id ON public.user_meal_logs(food_id);

-- Trigger: updated_at otomatik güncelleme
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_meal_logs_updated_at
    BEFORE UPDATE ON public.user_meal_logs
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ----------------------------------------------------------------------------
-- RPC: get_weekly_grocery_list
-- Haftalık yemek planlarından malzemeleri kategorize edip toplam gramajları döner
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_weekly_grocery_list(
    p_user_id TEXT,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    category TEXT,
    food_name TEXT,
    total_grams NUMERIC,
    unit TEXT,
    food_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(ingredient.category, 'Diğer') AS category,
        ingredient.food_name,
        SUM(ingredient.grams_per_100g * (dmp.portion_size / 100.0)) AS total_grams,
        COALESCE(ingredient.unit, 'gram') AS unit,
        COUNT(*) AS food_count
    FROM public.daily_meal_plans dmp
    CROSS JOIN LATERAL jsonb_array_elements(
        CASE 
            WHEN dmp.kahvalti IS NOT NULL THEN jsonb_build_array(dmp.kahvalti)
            ELSE '[]'::jsonb
        END ||
        CASE 
            WHEN dmp.ara_ogun_1 IS NOT NULL THEN jsonb_build_array(dmp.ara_ogun_1)
            ELSE '[]'::jsonb
        END ||
        CASE 
            WHEN dmp.ogle IS NOT NULL THEN jsonb_build_array(dmp.ogle)
            ELSE '[]'::jsonb
        END ||
        CASE 
            WHEN dmp.ara_ogun_2 IS NOT NULL THEN jsonb_build_array(dmp.ara_ogun_2)
            ELSE '[]'::jsonb
        END ||
        CASE 
            WHEN dmp.aksam IS NOT NULL THEN jsonb_build_array(dmp.aksam)
            ELSE '[]'::jsonb
        END ||
        CASE 
            WHEN dmp.gece_atistirma IS NOT NULL THEN jsonb_build_array(dmp.gece_atistirma)
            ELSE '[]'::jsonb
        END
    ) AS meal_json
    CROSS JOIN LATERAL jsonb_array_elements(meal_json->'ingredients') AS ingredient
    WHERE dmp.user_id = p_user_id
      AND dmp.date BETWEEN p_start_date AND p_end_date
    GROUP BY ingredient.category, ingredient.food_name, ingredient.unit
    ORDER BY category, total_grams DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- RPC: get_best_fit_foods
-- 3 boyutlu uzayda Öklid uzaklığına göre en yakın yemekleri bulur
-- Blacklist array içindeki yemekleri hariç tutar
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_best_fit_foods(
    p_target_p_ratio NUMERIC,  -- Hedef Protein oranı (kaloriden %)
    p_target_c_ratio NUMERIC,  -- Hedef Karbonhidrat oranı
    p_target_f_ratio NUMERIC,  -- Hedef Yağ oranı
    p_meal_type TEXT,
    p_blacklist_array TEXT[] DEFAULT '{}',
    p_limit INTEGER DEFAULT 3
)
RETURNS TABLE (
    food_id TEXT,
    food_name TEXT,
    calories_per_100g NUMERIC,
    protein_g NUMERIC,
    carbs_g NUMERIC,
    fat_g NUMERIC,
    euclidean_distance NUMERIC,
    scaled_calories NUMERIC,
    scaled_grams NUMERIC,
    scaling_factor NUMERIC
) AS $$
DECLARE
    v_target_calories NUMERIC := 500.0;  -- Varsayılan hedef kalori
BEGIN
    RETURN QUERY
    WITH food_ratios AS (
        SELECT 
            f.id AS food_id,
            f.name AS food_name,
            f.calories_per_100g,
            f.protein_g,
            f.carbs_g,
            f.fat_g,
            -- Makro oranlarını hesapla (kaloriden %)
            CASE 
                WHEN f.calories_per_100g > 0 
                THEN (f.protein_g * 4.0) / f.calories_per_100g 
                ELSE 0 
            END AS p_ratio,
            CASE 
                WHEN f.calories_per_100g > 0 
                THEN (f.carbs_g * 4.0) / f.calories_per_100g 
                ELSE 0 
            END AS c_ratio,
            CASE 
                WHEN f.calories_per_100g > 0 
                THEN (f.fat_g * 9.0) / f.calories_per_100g 
                ELSE 0 
            END AS f_ratio
        FROM public.foods f
        WHERE f.meal_type = p_meal_type
          AND (p_blacklist_array IS NULL OR f.id = ANY(p_blacklist_array)) = FALSE
          AND f.active = TRUE
    ),
    distances AS (
        SELECT 
            fr.*,
            -- Öklid uzaklığı: √[(P₁-P₀)² + (C₁-C₀)² + (F₁-F₀)²]
            SQRT(
                POWER(fr.p_ratio - p_target_p_ratio, 2) +
                POWER(fr.c_ratio - p_target_c_ratio, 2) +
                POWER(fr.f_ratio - p_target_f_ratio, 2)
            ) AS euclidean_distance,
            -- Scaling Factor (S) = Target_Calories / Calories_per_100g
            v_target_calories / NULLIF(fr.calories_per_100g, 0) AS scaling_factor
        FROM food_ratios fr
    )
    SELECT 
        d.food_id,
        d.food_name,
        d.calories_per_100g,
        d.protein_g,
        d.carbs_g,
        d.fat_g,
        d.euclidean_distance,
        -- Ölçeklendirilmiş değerler
        d.calories_per_100g * d.scaling_factor AS scaled_calories,
        100.0 * d.scaling_factor AS scaled_grams,
        d.scaling_factor
    FROM distances d
    WHERE d.euclidean_distance IS NOT NULL
      AND d.scaling_factor * 100.0 <= 400.0  -- 400 gram sınırı
    ORDER BY d.euclidean_distance ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- RPC: mark_meal_consumed
-- user_meal_logs tablosuna öğün kaydı ekler
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mark_meal_consumed(
    p_user_id TEXT,
    p_date DATE,
    p_meal_type TEXT,
    p_food_id TEXT,
    p_consumed_grams NUMERIC,
    p_status TEXT DEFAULT 'yedi'
)
RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO public.user_meal_logs (
        user_id, date, meal_type, food_id, consumed_grams, status
    ) VALUES (
        p_user_id, p_date, p_meal_type, p_food_id, p_consumed_grams, p_status
    ) RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- RPC: get_weekly_consumed_food_ids
-- Haftalık yenilen yemek ID'lerini döner (blacklist için)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_weekly_consumed_food_ids(
    p_user_id TEXT,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (food_id TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT uml.food_id
    FROM public.user_meal_logs uml
    WHERE uml.user_id = p_user_id
      AND uml.date BETWEEN p_start_date AND p_end_date
      AND uml.status = 'yedi';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- Grant Permissions (RLS)
-- ----------------------------------------------------------------------------
ALTER TABLE public.user_meal_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own meal logs"
    ON public.user_meal_logs FOR SELECT
    USING (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can insert own meal logs"
    ON public.user_meal_logs FOR INSERT
    WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can update own meal logs"
    ON public.user_meal_logs FOR UPDATE
    USING (auth.uid()::TEXT = user_id);

-- ----------------------------------------------------------------------------
-- Helper: foods tablosu varsa meal_type ve active sütunlarını ekle
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'foods') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'foods' AND column_name = 'meal_type') THEN
            ALTER TABLE public.foods ADD COLUMN meal_type TEXT;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'foods' AND column_name = 'active') THEN
            ALTER TABLE public.foods ADD COLUMN active BOOLEAN DEFAULT TRUE;
        END IF;
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- Helper: daily_meal_plans tablosu varsa portion_size sütununu ekle
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_meal_plans') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'daily_meal_plans' AND column_name = 'portion_size') THEN
            ALTER TABLE public.daily_meal_plans ADD COLUMN portion_size NUMERIC DEFAULT 100.0;
        END IF;
    END IF;
END $$;

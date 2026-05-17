-- Migration: V5 - Meal Optimizer Fix
-- Fixes hardcoded 500 kcal limit by adding p_target_calories to get_best_fit_foods
-- Unifies 'gece_atistirma' vs 'gece_atistirmasi' to the canonical 'gece_atistirmasi'

-- 1. Rename column in daily_meal_plans
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_meal_plans' AND column_name = 'gece_atistirma'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_meal_plans' AND column_name = 'gece_atistirmasi'
    ) THEN
        ALTER TABLE public.daily_meal_plans RENAME COLUMN gece_atistirma TO gece_atistirmasi;
    END IF;
END $$;

-- 2. Update existing data in user_meal_logs and foods
UPDATE public.user_meal_logs SET meal_type = 'gece_atistirmasi' WHERE meal_type = 'gece_atistirma';
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'foods') THEN
        UPDATE public.foods SET meal_type = 'gece_atistirmasi' WHERE meal_type = 'gece_atistirma';
    END IF;
END $$;

-- 3. Fix user_meal_logs constraints
ALTER TABLE public.user_meal_logs DROP CONSTRAINT IF EXISTS user_meal_logs_meal_type_check;
ALTER TABLE public.user_meal_logs ADD CONSTRAINT user_meal_logs_meal_type_check 
    CHECK (meal_type IN ('kahvalti', 'ara_ogun_1', 'ogle', 'ara_ogun_2', 'aksam', 'gece_atistirmasi'));

-- 4. Recreate get_weekly_grocery_list to use dmp.gece_atistirmasi
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
            WHEN dmp.gece_atistirmasi IS NOT NULL THEN jsonb_build_array(dmp.gece_atistirmasi)
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

-- 5. Recreate get_best_fit_foods with p_target_calories
DROP FUNCTION IF EXISTS public.get_best_fit_foods(numeric, numeric, numeric, text, text[], integer);

CREATE OR REPLACE FUNCTION public.get_best_fit_foods(
    p_target_calories NUMERIC,
    p_target_p_ratio NUMERIC,
    p_target_c_ratio NUMERIC,
    p_target_f_ratio NUMERIC,
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
          AND NOT (f.id = ANY(COALESCE(p_blacklist_array, ARRAY[]::TEXT[])))
          AND f.active = TRUE
    ),
    distances AS (
        SELECT 
            fr.*,
            SQRT(
                POWER(fr.p_ratio - p_target_p_ratio, 2) +
                POWER(fr.c_ratio - p_target_c_ratio, 2) +
                POWER(fr.f_ratio - p_target_f_ratio, 2)
            ) AS euclidean_distance,
            p_target_calories / NULLIF(fr.calories_per_100g, 0) AS scaling_factor
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

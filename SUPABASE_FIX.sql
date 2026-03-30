-- ============================================================================
-- ZİNDEAI SUPABASE MIGRATION - ACELE DÜZELTME
-- ============================================================================
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştır
-- ============================================================================

-- 1. daily_plans tablosuna 'ogun_durumlari' sütunu ekle
ALTER TABLE public.daily_plans 
ADD COLUMN IF NOT EXISTS ogun_durumlari JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.daily_plans.ogun_durumlari IS 'Öğün durumları: Map<String, String> - bekliyor/yedi/onaylandi/atandi';

-- 2. meal_confirmations tablosuna 'tarih' sütunu ekle
ALTER TABLE public.meal_confirmations 
ADD COLUMN IF NOT EXISTS tarih DATE NOT NULL DEFAULT CURRENT_DATE;

-- 3. Eski unique constraint'i kaldır (plan_id, yemek_id)
ALTER TABLE public.meal_confirmations 
DROP CONSTRAINT IF EXISTS meal_confirmations_plan_id_yemek_id_key;

-- 4. Yeni unique constraint: (user_id, yemek_id, tarih)
ALTER TABLE public.meal_confirmations 
ADD CONSTRAINT meal_confirmations_user_yemek_tarih_key 
UNIQUE (user_id, yemek_id, tarih);

-- 5. Index'leri güncelle
CREATE INDEX IF NOT EXISTS idx_meal_confirmations_user_tarih 
ON public.meal_confirmations(user_id, tarih);

CREATE INDEX IF NOT EXISTS idx_daily_plans_ogun_durumlari 
ON public.daily_plans USING GIN (ogun_durumlari);

-- ============================================================================
-- TAMAMLANDI - "Yedim/Yemedim" butonları artık çalışacak!
-- ============================================================================

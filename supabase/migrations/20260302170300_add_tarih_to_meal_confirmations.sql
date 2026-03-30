-- meal_confirmations tablosuna tarih sütunu ekle
-- Öğün onayları artık tarih bazlı tutulacak

-- Önce mevcut verileri korumak için (varsa)
-- Eğer plan_id varsa, daily_plans tablosundan tarih'i alabiliriz

-- Yeni migration: tarih sütunu ekle
ALTER TABLE public.meal_confirmations 
ADD COLUMN IF NOT EXISTS tarih DATE NOT NULL DEFAULT CURRENT_DATE;

-- Eski unique constraint'i kaldır (plan_id, yemek_id)
ALTER TABLE public.meal_confirmations 
DROP CONSTRAINT IF EXISTS meal_confirmations_plan_id_yemek_id_key;

-- Yeni unique constraint: (user_id, yemek_id, tarih)
-- Bir kullanıcının aynı yemeği aynı tarihte sadece bir kez onaylayabilir
ALTER TABLE public.meal_confirmations 
ADD CONSTRAINT meal_confirmations_user_yemek_tarih_key 
UNIQUE (user_id, yemek_id, tarih);

-- Optional: plan_id column'ını nullable yap (geçiş dönemi için)
-- ALTER TABLE public.meal_confirmations 
-- ALTER COLUMN plan_id DROP NOT NULL;

-- Index'leri güncelle
CREATE INDEX IF NOT EXISTS idx_meal_confirmations_user_tarih 
ON public.meal_confirmations(user_id, tarih);

COMMENT ON COLUMN public.meal_confirmations.tarih IS 'Öğünün yendiği/atlandığı tarihi';

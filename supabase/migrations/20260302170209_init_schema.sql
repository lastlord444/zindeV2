-- "user_profiles" tablosu
CREATE TABLE public.user_profiles (
  id UUID NOT NULL,
  ad TEXT NOT NULL,
  soyad TEXT NOT NULL,
  yas INTEGER NOT NULL,
  boy DOUBLE PRECISION NOT NULL,
  mevcut_kilo DOUBLE PRECISION NOT NULL,
  hedef_kilo DOUBLE PRECISION,
  cinsiyet TEXT NOT NULL,
  aktivite_seviyesi TEXT NOT NULL,
  hedef TEXT NOT NULL,
  diyet_tipi TEXT NOT NULL,
  manuel_alerjiler TEXT[] DEFAULT '{}',
  kayit_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (id)
);

-- RLS Politikaları
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcılar kendi profillerini görebilir"
  ON public.user_profiles
  FOR SELECT
  USING (true);

CREATE POLICY "Kullanıcılar kendi profillerini oluşturabilir"
  ON public.user_profiles
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Kullanıcılar kendi profillerini güncelleyebilir"
  ON public.user_profiles
  FOR UPDATE
  USING (true);

-- "daily_plans" tablosu
CREATE TABLE public.daily_plans (
  id UUID NOT NULL DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  tarih DATE NOT NULL,
  hedefler JSONB NOT NULL, -- MakroHedefleri json verisi
  kahvalti JSONB,
  ara_ogun_1 JSONB,
  ogle JSONB,
  ara_ogun_2 JSONB,
  aksam JSONB,
  gece_atistirma JSONB,
  tamamlanan_ogunler JSONB,
  PRIMARY KEY (id),
  UNIQUE (user_id, tarih) -- Bir kullanıcının gün başına 1 planı olabilir
);

-- RLS Politikaları
ALTER TABLE public.daily_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcılar kendi planlarını görebilir"
  ON public.daily_plans
  FOR SELECT
  USING (true);

CREATE POLICY "Kullanıcılar kendi planlarını oluşturabilir"
  ON public.daily_plans
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Kullanıcılar kendi planlarını güncelleyebilir"
  ON public.daily_plans
  FOR UPDATE
  USING (true);

-- "meal_confirmations" tablosu
CREATE TABLE public.meal_confirmations (
  id UUID NOT NULL DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  plan_id UUID NOT NULL REFERENCES public.daily_plans(id) ON DELETE CASCADE,
  yemek_id TEXT NOT NULL,
  durum TEXT NOT NULL DEFAULT 'yenildi', -- 'yenildi', 'atlandi' vb.
  kayit_zamani TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (id),
  UNIQUE (plan_id, yemek_id) -- Bir plana ait aynı yemek 1 kez onaylanabilir
);

-- RLS Politikaları
ALTER TABLE public.meal_confirmations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcılar onaylarını görebilir"
  ON public.meal_confirmations
  FOR SELECT
  USING (true);

CREATE POLICY "Kullanıcılar kendi öğünlerini onaylayabilir"
  ON public.meal_confirmations
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Kullanıcılar onaylarını güncelleyebilir/silebilir"
  ON public.meal_confirmations
  FOR DELETE
  USING (true);

-- "workout_plans" tablosu
CREATE TABLE public.workout_plans (
  id UUID NOT NULL DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  plan_adi TEXT NOT NULL,
  veri JSONB NOT NULL, -- AntrenmanPlani JSON çıktısı
  baslangic_tarihi DATE NOT NULL,
  bitis_tarihi DATE,
  aktif_mi BOOLEAN DEFAULT true,
  PRIMARY KEY (id)
);

-- RLS Politikaları
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcılar kendi antrenmanlarını görebilir"
  ON public.workout_plans
  FOR SELECT
  USING (true);

CREATE POLICY "Kullanıcılar kendi antrenmanlarını oluşturabilir"
  ON public.workout_plans
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Kullanıcılar kendi antrenmanlarını güncelleyebilir"
  ON public.workout_plans
  FOR UPDATE
  USING (true);

-- "workout_completions" tablosu
CREATE TABLE public.workout_completions (
  id UUID NOT NULL DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  program_id TEXT NOT NULL,
  program_adi TEXT NOT NULL,
  tarih DATE NOT NULL,
  sure_dakika INTEGER NOT NULL,
  tamamlanan_egzersizler TEXT[] DEFAULT '{}',
  PRIMARY KEY (id)
);

-- RLS Politikaları
ALTER TABLE public.workout_completions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcılar kendi antrenman geçmişini görebilir"
  ON public.workout_completions
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi antrenman geçmişini ekleyebilir"
  ON public.workout_completions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

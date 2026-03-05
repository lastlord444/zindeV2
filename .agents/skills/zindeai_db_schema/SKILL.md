---
description: ZindeAI V2.0 Supabase PostgreSQL şema tanımı - tablo yapıları ve SQL referansı
---

# ZindeAI V2.0 - Veritabanı Şema Skill

> ⚠️ Supabase'de tablo oluşturmadan önce bu şemayı referans al. Kolon isimlerini değiştirme!

---

## 📌 Genel Kurallar

- **Primary key**: `id UUID DEFAULT gen_random_uuid()`
- **Timestamp**: `created_at TIMESTAMPTZ DEFAULT NOW()`
- **User bağlantısı**: `user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE`
- **RLS**: Her tabloda Row Level Security aktif olmalı
- **JSON alanlar**: JSONB kullan (json değil)

---

## 🧑 user_profiles Tablosu

```sql
CREATE TABLE user_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  ad TEXT NOT NULL,
  soyad TEXT NOT NULL,
  yas INTEGER NOT NULL CHECK (yas >= 10 AND yas <= 120),
  boy DECIMAL(5,2) NOT NULL CHECK (boy >= 100 AND boy <= 250),  -- cm
  mevcut_kilo DECIMAL(5,2) NOT NULL CHECK (mevcut_kilo > 0),   -- kg
  hedef_kilo DECIMAL(5,2),
  cinsiyet TEXT NOT NULL CHECK (cinsiyet IN ('erkek', 'kadin')),
  aktivite_seviyesi TEXT NOT NULL CHECK (aktivite_seviyesi IN (
    'sedanter', 'hafifAktif', 'ortaAktif', 'cokAktif', 'atletik'
  )),
  hedef TEXT NOT NULL CHECK (hedef IN ('bulk', 'cut', 'maintain')),
  diyet_tipi TEXT NOT NULL CHECK (diyet_tipi IN (
    'normal', 'vejetaryen', 'vegan', 'glutensiz', 'laktozsuz'
  )),
  manuel_alerjiler JSONB DEFAULT '[]'::JSONB,  -- ["gluten", "süt"]
  kayit_tarihi TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Kendi profilini gör" ON user_profiles
  FOR ALL USING (auth.uid() = user_id);
```

**Dart'ta kolon mapı:**
```
id → id (String)
user_id → userId (String)
ad → ad (String)
soyad → soyad (String)
yas → yas (int)
boy → boy (double)
mevcut_kilo → mevcutKilo (double)
hedef_kilo → hedefKilo (double?)
cinsiyet → cinsiyet (Cinsiyet enum)
aktivite_seviyesi → aktiviteSeviyesi (AktiviteSeviyesi enum)
hedef → hedef (Hedef enum)
diyet_tipi → diyetTipi (DiyetTipi enum)
manuel_alerjiler → manuelAlerjiler (List<String>)
kayit_tarihi → kayitTarihi (DateTime)
```

---

## 📅 daily_plans Tablosu

```sql
CREATE TABLE daily_plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  tarih DATE NOT NULL,
  kahvalti JSONB,         -- Yemek.toJson()
  ara_ogun_1 JSONB,
  ogle JSONB,
  ara_ogun_2 JSONB,
  aksam JSONB,
  gece_atistirma JSONB,   -- null (sadece bulk)
  hedefler JSONB NOT NULL, -- MakroHedefleri.toJson()
  tamamlanan_ogunler JSONB DEFAULT '{}'::JSONB,  -- {"yemekId": true}
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, tarih)   -- Günde 1 plan
);

-- RLS
ALTER TABLE daily_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Kendi planlarını gör" ON daily_plans
  FOR ALL USING (auth.uid() = user_id);

-- Index
CREATE INDEX idx_daily_plans_user_tarih ON daily_plans(user_id, tarih);
```

---

## ✅ meal_confirmations Tablosu

```sql
CREATE TABLE meal_confirmations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  yemek_id TEXT NOT NULL,    -- Yemek.id
  tarih DATE NOT NULL,
  durum TEXT NOT NULL CHECK (durum IN ('yenilecek', 'yenildi', 'atlandi', 'onaylandi')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, yemek_id, tarih)
);

-- RLS
ALTER TABLE meal_confirmations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Kendi onaylarını gör" ON meal_confirmations
  FOR ALL USING (auth.uid() = user_id);
```

---

## 🏋️ workout_completions Tablosu

```sql
CREATE TABLE workout_completions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  program_id TEXT NOT NULL,    -- AntrenmanPlani.id
  program_adi TEXT NOT NULL,
  tarih DATE NOT NULL,
  sure_dakika INTEGER NOT NULL,
  tamamlanan_egzersizler JSONB DEFAULT '[]'::JSONB,  -- [egzersizId, ...]
  notlar TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE workout_completions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Kendi antrenmanlarını gör" ON workout_completions
  FOR ALL USING (auth.uid() = user_id);
```

---

## 🔧 Dart DataSource Kalıpları

### Veri Okuma:
```dart
// Tek kayıt
final data = await supabase
    .from('user_profiles')
    .select()
    .eq('user_id', userId)
    .single();

// Liste
final data = await supabase
    .from('daily_plans')
    .select()
    .eq('user_id', userId)
    .gte('tarih', baslangic.toIso8601String())
    .lte('tarih', bitis.toIso8601String())
    .order('tarih');
```

### Veri Kaydetme (Upsert):
```dart
await supabase
    .from('user_profiles')
    .upsert({
      'user_id': userId,
      'ad': profil.ad,
      ...profil.toSupabaseJson(),
    });
```

### Veri Silme:
```dart
await supabase
    .from('daily_plans')
    .delete()
    .eq('user_id', userId)
    .eq('tarih', tarih.toIso8601String().substring(0, 10));
```

---

## 🔑 Supabase Config (core/config/supabase_config.dart)

```dart
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY',
  );
}
```

> 🔐 Gerçek URL ve key'i `.env` dosyasında sakla, doğrudan koda yazma!

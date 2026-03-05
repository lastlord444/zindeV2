// lib/core/utils/validators.dart

/// Form ve veri doğrulama yardımcılar1
class Validators {
  // ─── Kullanıc1 Profil Doğrulama ──────────────────────────────────────────
  static String? adDogrula(String? deger) {
    if (deger == null || deger.trim().isEmpty) return 'İsim zorunludur.';
    if (deger.trim().length < 2) return 'İsim en az 2 karakter olmalıdır.';
    if (deger.trim().length > 50) return 'İsim en fazla 50 karakter olabilir.';
    return null;
  }

  static String? yasDogrula(String? deger) {
    if (deger == null || deger.isEmpty) return 'Yaş zorunludur.';
    final yas = int.tryParse(deger);
    if (yas == null) return 'Geerli bir yaş girin.';
    if (yas < 10 || yas > 120) return 'Yaş 10-120 arasında olmalıdır.';
    return null;
  }

  static String? boyDogrula(String? deger) {
    if (deger == null || deger.isEmpty) return 'Boy zorunludur.';
    final boy = double.tryParse(deger.replaceAll(',', '.'));
    if (boy == null) return 'Geerli bir boy girin.';
    if (boy < 100 || boy > 250) return 'Boy 100-250 cm arasında olmalıdır.';
    return null;
  }

  static String? kiloDogrula(String? deger) {
    if (deger == null || deger.isEmpty) return 'Kilo zorunludur.';
    final kilo = double.tryParse(deger.replaceAll(',', '.'));
    if (kilo == null) return 'Geerli bir kilo girin.';
    if (kilo < 20 || kilo > 500) return 'Kilo 20-500 kg arasında olmalıdır.';
    return null;
  }

  static String? hedefKiloDogrula(String? deger) {
    if (deger == null || deger.isEmpty) return null; // Opsiyonel
    final kilo = double.tryParse(deger.replaceAll(',', '.'));
    if (kilo == null) return 'Geerli bir hedef kilo girin.';
    if (kilo < 20 || kilo > 500) return 'Hedef kilo 20-500 kg arasında olmalıdır.';
    return null;
  }

  // ─── Genel Doğrulama ─────────────────────────────────────────────────────
  /// Double aralık doğrulamas1
  static bool aralikDogru(double deger, double min, double maks) {
    return deger >= min && deger <= maks;
  }

  /// Makro değerinin sıfırdan büyük olup olmadığın1 kontrol et
  static bool makroGecerliMi(double deger) => deger > 0;
}

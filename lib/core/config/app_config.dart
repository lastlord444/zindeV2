// lib/core/config/app_config.dart

/// Genel uygulama konfigürasyonu
class AppConfig {
  static const String uygulamaAdi = 'ZindeAI';
  static const String versiyon = '2.0.0';

  // Pollinations.AI Chatbot
  static const String pollinationsApiUrl = 'https://text.pollinations.ai/';
  static const String pollinationsModel = 'openai';
  static const int chatGecmisiSayisi = 10; // Son 10 mesaj gönderilir

  // Plan oluşturma
  static const int planlariOnBellekteTut = 7; // 7 günlük plan sakla
  static const int alternatifYemekSayisi = 5; // Alternatif gösterim sayıs1

  // Hata mesajlar1
  static const String varsayilanHataMesaji = 'Beklenmedik bir hata oluştu. Lütfen tekrar deneyin.';
  static const String agBaglantisiHatasi = 'İnternet bağlantıs1 bulunamad1.';
}

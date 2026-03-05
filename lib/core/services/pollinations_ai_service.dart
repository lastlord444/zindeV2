// lib/core/services/pollinations_ai_service.dart
// Pollinations.ai API servisi - Chatbot iin

import 'package:dio/dio.dart';
import '../utils/logger.dart';

/// Pollinations.ai API kategori enum'u
/// UI'da AICategory olarak erişilir
enum AICategory {
  supplement,  // Supplement tavsiyeleri
  nutrition,   // Beslenme sorular1
  training,    // Antrenman tavsiyeleri
  general,     // Genel sağlık
  dietician,   // Diyetisyen modu
}

/// Pollinations.ai API servisi
/// - Metin yanıt1: GET /text/{prompt} (openai-large)
/// - TTS ses ıktıs1: POST /v1/audio/speech (elevenlabs)
/// - STT ses girişi: POST /v1/audio/transcriptions (scribe)
class PollinationsAIService {
  static const String _baseUrl = 'https://text.pollinations.ai';
  static const String _metinModeli = 'openai-large'; // GPT-5.2 - En gülü
  static const String _ttsSesi = 'nova'; // Türke iin doğal ses
  static const String _sttModeli = 'scribe'; // 90+ dil, Türke dahil

  // ─── V1 UI Uyumluluk Static Map'leri ───────────────────────────────────
  static const Map<AICategory, String> categoryDescriptions = {
    AICategory.supplement: 'Takviye & Supplement',
    AICategory.nutrition: 'Beslenme & Diyet',
    AICategory.training: 'Antrenman & Egzersiz',
    AICategory.general: 'Genel Sağlık',
    AICategory.dietician: 'Diyetisyen Danışmanlığı',
  };

  static const Map<AICategory, String> categoryEmojis = {
    AICategory.supplement: '💊',
    AICategory.nutrition: '🥗',
    AICategory.training: '💪',
    AICategory.general: '🌿',
    AICategory.dietician: '👩‍⚕️',
  };

  final Dio _dio;

  PollinationsAIService() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  /// Kategori iin sistem promptu oluştur
  static String sistemPromptOlustur(AICategory kategori) {
    const temel = '''Sen ZindeAI'ın beslenme ve fitness asistanısın. 
Türke konuş. Kısa, net ve bilimsel yanıtlar ver.
Tıbbi teşhis koyma. Gerektiğinde uzman görüşü al tavsiyesinde bulun.''';

    switch (kategori) {
      case AICategory.supplement:
        return '$temel\nÖzellikle supplement (protein tozu, kreatin, vitamin vb.) konularında uzmanlaştın.';
      case AICategory.nutrition:
        return '$temel\nBeslenme bilimi, makrolar, kalori hesaplama ve diyet planlar1 konularında uzmanlaştın.';
      case AICategory.training:
        return '$temel\nAntrenman programlar1, egzersiz tekniği, kas gelişimi ve toparlanma konularında uzmanlaştın.';
      case AICategory.dietician:
        return '$temel\nKlinik diyetisyen gibi davran. Tıbbi beslenme tedavisi ve özel diyet programlar1 konularında uzmanlaştın.';
      case AICategory.general:
        return '$temel\nGenel sağlık, yaşam tarz1 ve wellness konularında rehberlik et.';
    }
  }

  /// Metin yanıt1 al (openai-large modeli)
  Future<String> mesinYanitiAl({
    required String kullaniciMesaji,
    required AICategory kategori,
    List<Map<String, String>> gecmis = const [],
  }) async {
    try {
      final sistemPrompt = sistemPromptOlustur(kategori);
      final mesajlar = [
        {'role': 'system', 'content': sistemPrompt},
        ...gecmis,
        {'role': 'user', 'content': kullaniciMesaji},
      ];

      final yanit = await _dio.post(
        'https://gen.pollinations.ai/v1/chat/completions',
        data: {
          'model': _metinModeli,
          'messages': mesajlar,
          'temperature': 0.7,
          'seed': -1, // Her seferinde farkl1
        },
      );

      return yanit.data['choices'][0]['message']['content'] as String;
    } on DioException catch (e) {
      AppLogger.hata('Pollinations metin yanıt1 hatas1', e);
      return 'Üzgünüm, şu an yanıt veremiyorum. Lütfen tekrar deneyin.';
    }
  }

  /// V1 UI uyumluluk - getResponse alias
  Future<String> getResponse({
    required String message,
    required AICategory category,
    List<Map<String, String>> history = const [],
  }) => mesinYanitiAl(
    kullaniciMesaji: message,
    kategori: category,
    gecmis: history,
  );

  /// TTS - Metni sese evir (ElevenLabs v3)
  /// Döndürür: ses verisi (bytes)
  Future<List<int>?> metniSeseCevir(String metin) async {
    try {
      final yanit = await _dio.post(
        'https://gen.pollinations.ai/v1/audio/speech',
        data: {
          'input': metin,
          'voice': _ttsSesi, // nova - Türke iin doğal
          'model': 'elevenlabs',
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return yanit.data as List<int>;
    } on DioException catch (e) {
      AppLogger.hata('TTS hatas1', e);
      return null;
    }
  }

  /// STT - Sesi metne evir (ElevenLabs Scribe - Türke)
  /// Alır: ses dosyas1 bytes + mime type
  Future<String?> sesiMetneYevir(List<int> sesVerisi, String mimeType) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(sesVerisi, filename: 'audio.webm'),
        'model': _sttModeli,
      });
      final yanit = await _dio.post(
        'https://gen.pollinations.ai/v1/audio/transcriptions',
        data: formData,
      );
      return yanit.data['text'] as String?;
    } on DioException catch (e) {
      AppLogger.hata('STT hatas1', e);
      return null;
    }
  }

  /// Basit GET endpoint (yedek)
  Future<String> hizliYanit(String prompt, AICategory kategori) async {
    try {
      final sistemPrompt = Uri.encodeComponent(sistemPromptOlustur(kategori));
      final encodedPrompt = Uri.encodeComponent(prompt);
      final yanit = await _dio.get(
        '$_baseUrl/$encodedPrompt?model=$_metinModeli&system=$sistemPrompt',
      );
      return yanit.data.toString();
    } on DioException catch (e) {
      AppLogger.hata('Hızl1 yanıt hatas1', e);
      return 'Bağlant1 hatas1. Tekrar deneyin.';
    }
  }
}

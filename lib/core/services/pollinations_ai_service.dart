// lib/core/services/pollinations_ai_service.dart
// Pollinations.ai API servisi - Chatbot için

import 'package:dio/dio.dart';
import '../utils/logger.dart';

/// Pollinations.ai API kategori enum'u
/// UI'da AICategory olarak erişilir
enum AICategory {
  supplement,  // Supplement tavsiyeleri
  nutrition,   // Beslenme soruları
  training,    // Antrenman tavsiyeleri
  general,     // Genel sağlık
  dietician,   // Diyetisyen modu
}

/// Pollinations.ai API servisi
/// Doğru endpoint: https://text.pollinations.ai/{prompt}
class PollinationsAIService {
  static const String _chatUrl = 'https://enter.pollinations.ai';
  static const String _metinModeli = 'openai'; // OpenAI uyumlu model
  static const String _ttsSesi = 'nova'; // Türkçe için doğal ses
  static const String _sttModeli = 'scribe'; // 90+ dil, Türkçe dahil

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

  /// Kategori için sistem promptu oluştur
  static String sistemPromptOlustur(AICategory kategori) {
    const temel = '''Sen ZindeAI'ın beslenme ve fitness asistanısın. 
Türkçe konuş. Kısa, net ve bilimsel yanıtlar ver.
Tıbbi teşhis koyma. Gerektiğinde uzman görüşü al tavsiyesinde bulun.''';

    switch (kategori) {
      case AICategory.supplement:
        return '$temel\nÖzellikle supplement (protein tozu, kreatin, vitamin vb.) konularında uzmanlaştın.';
      case AICategory.nutrition:
        return '$temel\nBeslenme bilimi, makrolar, kalori hesaplama ve diyet planları konularında uzmanlaştın.';
      case AICategory.training:
        return '$temel\nAntrenman programları, egzersiz tekniği, kas gelişimi ve toparlanma konularında uzmanlaştın.';
      case AICategory.dietician:
        return '$temel\nKlinik diyetisyen gibi davran. Tıbbi beslenme tedavisi ve özel diyet programları konularında uzmanlaştın.';
      case AICategory.general:
        return '$temel\nGenel sağlık, yaşam tarzı ve wellness konularında rehberlik et.';
    }
  }

  /// Metin yanıtı al (PollinationsAI text API - Doğru endpoint)
  Future<String> mesinYanitiAl({
    required String kullaniciMesaji,
    required AICategory kategori,
    List<Map<String, String>> gecmis = const [],
  }) async {
    try {
      final sistemPrompt = sistemPromptOlustur(kategori);
      
      // Geçmiş mesajları birleştir
      String gecmisMetni = '';
      for (final msg in gecmis) {
        final role = msg['role'] == 'user' ? 'Kullanıcı' : 'Asistan';
        gecmisMetni += '$role: ${msg['content']}\n';
      }
      
      final fullPrompt = '$sistemPrompt\n\n$gecmisMetni\nKullanıcı: $kullaniciMesaji\n\nAsistan:';
      final encodedPrompt = Uri.encodeComponent(fullPrompt);
      
      AppLogger.bilgi('PollinationsAI isteği: $_chatUrl/$encodedPrompt');
      
      final yanit = await _dio.get(
        '$_chatUrl/$encodedPrompt',
        queryParameters: {
          'model': _metinModeli,
          'jsonMode': 'false',
          'seed': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      if (yanit.statusCode == 200) {
        final responseData = yanit.data;
        AppLogger.bilgi('PollinationsAI yanıt: $responseData');
        
        if (responseData is String && responseData.isNotEmpty) {
          return responseData.trim();
        } else if (responseData is Map) {
          return (responseData['response']?.toString() ?? 
                 responseData['text']?.toString() ??
                 'Yanıt alınamadı.').trim();
        }
      }
      
      AppLogger.uyari('Beklenmeyen yanıt formatı: ${yanit.statusCode}');
      return 'Yanıt formatı beklenmedik. Lütfen tekrar deneyin.';
    } on DioException catch (e) {
      AppLogger.hata('Pollinations metin yanıtı hatası: ${e.message}', e);
      return 'Bağlantı hatası: ${e.message ?? 'Bilinmeyen hata'}. Lütfen internet bağlantınızı kontrol edin.';
    } catch (e, stackTrace) {
      AppLogger.hata('Beklenmeyen hata', e, stackTrace);
      return 'Bir hata oluştu: ${e.toString()}';
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

  /// TTS - Metni sese çevir (ElevenLabs v3)
  /// Döndürür: ses verisi (bytes)
  Future<List<int>?> metniSeseCevir(String metin) async {
    try {
      final yanit = await _dio.post(
        'https://audio.pollinations.ai/speech',
        data: {
          'text': metin,
          'voice': _ttsSesi,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return yanit.data as List<int>;
    } on DioException catch (e) {
      AppLogger.hata('TTS hatası', e);
      return null;
    }
  }

  /// STT - Sesi metne çevir (ElevenLabs Scribe - Türkçe)
  /// Alır: ses dosyası bytes + mime type
  Future<String?> sesiMetneYevir(List<int> sesVerisi, String mimeType) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(sesVerisi, filename: 'audio.webm'),
        'model': _sttModeli,
      });
      final yanit = await _dio.post(
        'https://audio.pollinations.ai/transcribe',
        data: formData,
      );
      return yanit.data['text'] as String?;
    } on DioException catch (e) {
      AppLogger.hata('STT hatası', e);
      return null;
    }
  }

  /// Basit GET endpoint (yedek)
  Future<String> hizliYanit(String prompt, AICategory kategori) async {
    try {
      final sistemPrompt = sistemPromptOlustur(kategori);
      final fullPrompt = '$sistemPrompt\n\n$prompt';
      final encodedPrompt = Uri.encodeComponent(fullPrompt);
      
      final yanit = await _dio.get(
        '$_chatUrl/$encodedPrompt',
        queryParameters: {'model': _metinModeli},
      );
      
      return yanit.data.toString().trim();
    } on DioException catch (e) {
      AppLogger.hata('Hızlı yanıt hatası', e);
      return 'Bağlantı hatası. Tekrar deneyin.';
    }
  }
}

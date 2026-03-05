// lib/presentation/bloc/chatbot/chatbot_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/pollinations_ai_service.dart';
import '../../../core/utils/logger.dart';
import 'chatbot_event.dart';
import 'chatbot_state.dart';

/// Chatbot BLoC
/// Pollinations.ai API ile metin + ses desteği
class ChatbotBloc extends Bloc<ChatbotEvent, ChatbotState> {
  final PollinationsAIService _aiService;
  final List<ChatMesaj> _mesajGecmisi = [];
  ChatbotBloc({PollinationsAIService? aiService})
      : _aiService = aiService ?? PollinationsAIService(),
        super(const ChatbotInitial()) {
    on<ChatbotMesajGonder>(_onMesajGonder);
    on<ChatbotKategoriDegistir>(_onKategoriDegistir);
    on<ChatbotTemizle>(_onTemizle);
  }

  Future<void> _onMesajGonder(
      ChatbotMesajGonder event, Emitter<ChatbotState> emit) async {
    // Kullanıc1 mesajın1 gemişe ekle
    _mesajGecmisi.add(ChatMesaj(
      icerik: event.mesaj,
      kullanicidan: true,
    ));

    emit(ChatbotBekliyor(List.from(_mesajGecmisi)));

    try {
      // Gemişi OpenAI formatına evir
      final gecmisFormati = _mesajGecmisi
          .take(_mesajGecmisi.length - 1)
          .map((m) => {
                'role': m.kullanicidan ? 'user' : 'assistant',
                'content': m.icerik,
              })
          .toList();

      final yanit = await _aiService.mesinYanitiAl(
        kullaniciMesaji: event.mesaj,
        kategori: _kategoriDonustur(event.kategori),
        gecmis: gecmisFormati.cast<Map<String, String>>(),
      );

      // AI yanıtın1 gemişe ekle
      _mesajGecmisi.add(ChatMesaj(
        icerik: yanit,
        kullanicidan: false,
      ));

      AppLogger.bilgi('ChatbotBloc: Yanıt alınd1 (${yanit.length} karakter)');

      emit(ChatbotYanit(
        yanit: yanit,
        mesajlar: List.from(_mesajGecmisi),
        aktifKategori: event.kategori,
      ));
    } catch (e) {
      AppLogger.hata('ChatbotBloc yanıt hatas1', e);
      emit(ChatbotHata(
        mesaj: 'Bağlant1 hatas1. Tekrar deneyin.',
        mesajlar: List.from(_mesajGecmisi),
      ));
    }
  }

  void _onKategoriDegistir(
      ChatbotKategoriDegistir event, Emitter<ChatbotState> emit) {
    // Kategori değiştiğinde sadece UI'1 güncellemek iin
    emit(ChatbotYanit(
      yanit: '',
      mesajlar: List.from(_mesajGecmisi),
      aktifKategori: event.kategori,
    ));
  }

  void _onTemizle(ChatbotTemizle event, Emitter<ChatbotState> emit) {
    _mesajGecmisi.clear();
    emit(const ChatbotInitial());
  }

  /// BLoC AIKategori â†’ PollinationsService AICategory dönüşümü
  AICategory _kategoriDonustur(AIKategori k) {
    switch (k) {
      case AIKategori.supplement: return AICategory.supplement;
      case AIKategori.nutrition: return AICategory.nutrition;
      case AIKategori.training: return AICategory.training;
      case AIKategori.general: return AICategory.general;
      case AIKategori.dietician: return AICategory.dietician;
    }
  }
}


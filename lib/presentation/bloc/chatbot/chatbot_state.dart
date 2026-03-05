// lib/presentation/bloc/chatbot/chatbot_state.dart

import 'package:equatable/equatable.dart';
import 'chatbot_event.dart';

class ChatMesaj {
  final String icerik;
  final bool kullanicidan;
  final DateTime zaman;

  ChatMesaj({
    required this.icerik,
    required this.kullanicidan,
    DateTime? zaman,
  }) : zaman = zaman ?? DateTime.now();
}

abstract class ChatbotState extends Equatable {
  const ChatbotState();
  @override
  List<Object?> get props => [];
}

class ChatbotInitial extends ChatbotState {
  const ChatbotInitial();
}

class ChatbotBekliyor extends ChatbotState {
  final List<ChatMesaj> mesajlar;
  const ChatbotBekliyor(this.mesajlar);
  @override
  List<Object?> get props => [mesajlar];
}

class ChatbotYanit extends ChatbotState {
  final String yanit;
  final List<ChatMesaj> mesajlar;
  final AIKategori aktifKategori;
  const ChatbotYanit({
    required this.yanit,
    required this.mesajlar,
    required this.aktifKategori,
  });
  @override
  List<Object?> get props => [yanit, mesajlar, aktifKategori];
}

class ChatbotHata extends ChatbotState {
  final String mesaj;
  final List<ChatMesaj> mesajlar;
  const ChatbotHata({required this.mesaj, required this.mesajlar});
  @override
  List<Object?> get props => [mesaj];
}


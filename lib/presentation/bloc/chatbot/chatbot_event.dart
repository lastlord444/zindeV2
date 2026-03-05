// lib/presentation/bloc/chatbot/chatbot_event.dart

import 'package:equatable/equatable.dart';

enum AIKategori { supplement, nutrition, training, general, dietician }

abstract class ChatbotEvent extends Equatable {
  const ChatbotEvent();
  @override
  List<Object?> get props => [];
}

class ChatbotMesajGonder extends ChatbotEvent {
  final String mesaj;
  final AIKategori kategori;
  const ChatbotMesajGonder({required this.mesaj, required this.kategori});
  @override
  List<Object?> get props => [mesaj, kategori];
}

class ChatbotKategoriDegistir extends ChatbotEvent {
  final AIKategori kategori;
  const ChatbotKategoriDegistir(this.kategori);
  @override
  List<Object?> get props => [kategori];
}

class ChatbotTemizle extends ChatbotEvent {
  const ChatbotTemizle();
}


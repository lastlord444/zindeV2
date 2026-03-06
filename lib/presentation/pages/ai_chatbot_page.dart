// lib/presentation/pages/ai_chatbot_page.dart
// AI Chatbot Sayfas1 - Supplement Danı_manl11

import 'package:flutter/material.dart';
import '../../core/services/pollinations_ai_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/di/injection_container.dart' as di;
import '../../domain/entities/user/kullanici_profili.dart';
import '../../domain/entities/user/hedef.dart';
import '../../domain/repositories/user_repository.dart';

class AIChatbotPage extends StatefulWidget {
  const AIChatbotPage({super.key});

  @override
  State<AIChatbotPage> createState() => _AIChatbotPageState();
}

class _AIChatbotPageState extends State<AIChatbotPage> {
  final UserRepository _userRepo = di.sl<UserRepository>();
  AICategory _selectedCategory = AICategory.supplement;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  KullaniciProfili? _kullaniciProfili;

  @override
  void initState() {
    super.initState();
    // Kullanıc1 profilini y?kle
    _loadUserProfile();
    // Ho_ geldin mesaj1 ekle
    _addWelcomeMessage();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profil = await _userRepo.onbellektenProfilGetir();
      setState(() {
        _kullaniciProfili = profil;
      });
      AppLogger.info('x? Kullanıc1 profili AI chatbot\'a y?klendi: ${profil?.ad} ${profil?.soyad}');
    } catch (e) {
      AppLogger.error('?R Kullanıc1 profili y?kleme hatas1', e);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final welcomeText = _getWelcomeText(_selectedCategory);
    setState(() {
      _messages.add(ChatMessage(
        text: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  String _getWelcomeText(AICategory category) {
    switch (category) {
      case AICategory.supplement:
        return 'x9 Merhaba! Ben Dr. Ahmet Yılmaz, 30 yıllık deneyime sahip supplement uzmanıyım.\n\n'
            'x` Whey protein, creatine, BCAA, vitaminler ve t?m supplement konularında size yardımc1 olabilirim.\n\n'
            'Bana kilo, boy, ya_ bilgilerinizi ve hedefinizi s?ylerseniz, size ?özel supplement program1 hazırlayabilirim!';
      case AICategory.nutrition:
        return 'x9 Merhaba! Ben Uzm. Dyt. Ayşe Demir, 30 yıllık deneyimli diyetisyeniyim.\n\n'
            'x? Beslenme planlar1, makro hesaplama, T?rk mutfaına uygun diyet ?nerileri konularında size yardımc1 olabilirim.\n\n'
            'Bana kilo, boy, ya_ ve hedefinizi s?ylerseniz, size ?özel beslenme plan1 hazırlayabilirim!';
      case AICategory.training:
        return 'x9 Merhaba! Ben Hakan Kaya, 30 yıllık deneyimli fitness antren?r?y?m.\n\n'
            '=? Antrenman programlar1, kas geli_tirme, ya yakma ve fitness konularında size yardımc1 olabilirim.\n\n'
            'Bana deneyim seviyenizi, hedefinizi ve ekipman durumunuzu s?ylerseniz, size ?özel program hazırlayabilirim!';
      case AICategory.general:
        return 'x9 Merhaba! Ben Dr. Zeynep Aydın, 30 yıllık genel salık uzmanıyım.\n\n'
            'x?? Salıkl1 ya_am, uyku, stres y?netimi ve genel salık konularında size yardımc1 olabilirim.\n\n'
            'Sorularınız1 bekliyorum!';
      case AICategory.dietician:
        return 'x9 Merhaba! Ben Uzm. Dyt. Elif Kaya, 20 yıllık deneyimli profesyonel diyetisyeniyim.\n\n'
            'x??️ T?rk mutfaından g?nl?k ve haftalık beslenme planlar1 hazırlıyorum. SADECE yerli yemeklerle (menemen, k?fte, pilav, balık) size ?zel planlar oluşturabilirim.\n\n'
            'Bana kilo, boy, ya_ ve hedefinizi s?ylerseniz, size T?rk mutfaından beslenme plan1 hazırlayabilirim!';
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    // Kullanıc1 mesajın1 ekle
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    // Scroll to bottom
    _scrollToBottom();

    try {
      // AI'dan yanıt al (profil bilgilerini de ge?ir)
      final aiService = PollinationsAIService();
      final aiResponse = await aiService.mesinYanitiAl(
        kullaniciMesaji: _kullaniciProfili != null 
            ? "Profilim: ${_getProfilOzeti()}\n\nSorum: $userMessage" 
            : userMessage,
        kategori: _selectedCategory,
        gecmis: _getConversationHistory(),
      );

      // AI yanıtın1 ekle
      setState(() {
        _messages.add(ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      AppLogger.error('AI Chat Error: $e');
      setState(() {
        _messages.add(ChatMessage(
          text: '?R ?zg?n?m, bir hata oluştu. L?tfen tekrar dene.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
  }

  List<Map<String, String>> _getConversationHistory() {
    // Son 10 mesaj1 g?nder (performans i?in)
    final recentMessages = _messages.length > 10
        ? _messages.sublist(_messages.length - 10)
        : _messages;

    return recentMessages
        .where((m) => m.isUser || !m.text.startsWith('x9')) // Ho_ geldin mesajın1 ekleme
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _changeCategory(AICategory newCategory) {
    setState(() {
      _selectedCategory = newCategory;
      _messages.clear();
      _addWelcomeMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          PollinationsAIService.categoryDescriptions[_selectedCategory]!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _getCategoryColor(_selectedCategory),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Kategori dei_tirme butonu
          PopupMenuButton<AICategory>(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Danı_man Dei_tir',
            onSelected: _changeCategory,
            itemBuilder: (context) => AICategory.values.map((category) {
              return PopupMenuItem(
                value: category,
                child: Row(
                  children: [
                    Text(
                      PollinationsAIService.categoryEmojis[category]!,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      PollinationsAIService.categoryDescriptions[category]!
                          .substring(3), // Emoji'yi ?ıkar
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          // Sohbeti temizle
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sohbeti Temizle',
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Kullanıc1 profil kart1 (varsa g?ster)
          if (_kullaniciProfili != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getCategoryColor(_selectedCategory).withValues(alpha: 0.15),
                    _getCategoryColor(_selectedCategory).withValues(alpha: 0.05),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: _getCategoryColor(_selectedCategory).withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(_selectedCategory).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person,
                      color: _getCategoryColor(_selectedCategory),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_kullaniciProfili!.ad} ${_kullaniciProfili!.soyad}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getCategoryColor(_selectedCategory),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getProfilOzeti(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Kategori bilgi band1
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getCategoryColor(_selectedCategory).withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: _getCategoryColor(_selectedCategory).withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(_selectedCategory),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    PollinationsAIService.categoryEmojis[_selectedCategory]!,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCategoryName(_selectedCategory),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(_selectedCategory),
                        ),
                      ),
                      Text(
                        _getCategoryExpertise(_selectedCategory),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chat mesajlar1
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(
                  message: message,
                  categoryColor: _getCategoryColor(_selectedCategory),
                );
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getCategoryColor(_selectedCategory),
                      ),
                    ),
                  ),
        const SizedBox(width: 8),
        Text(
          'Yanıt yazılıyor...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
                ],
              ),
            ),

          // Mesaj input alan1
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Mesajınız1 yazın...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _getCategoryColor(_selectedCategory),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(AICategory category) {
    switch (category) {
      case AICategory.supplement:
        return Colors.purple;
      case AICategory.nutrition:
        return Colors.green;
      case AICategory.training:
        return Colors.orange;
      case AICategory.general:
        return Colors.blue;
      case AICategory.dietician:
        return Colors.teal;
    }
  }

  String _getCategoryName(AICategory category) {
    switch (category) {
      case AICategory.supplement:
        return 'Dr. Ahmet Yılmaz';
      case AICategory.nutrition:
        return 'Uzm. Dyt. Ayşe Demir';
      case AICategory.training:
        return 'Hakan Kaya';
      case AICategory.general:
        return 'Dr. Zeynep Aydın';
      case AICategory.dietician:
        return 'Uzm. Dyt. Elif Kaya';
    }
  }

  String _getCategoryExpertise(AICategory category) {
    switch (category) {
      case AICategory.supplement:
        return '30 yıllık Supplement Uzman1';
      case AICategory.nutrition:
        return '30 yıllık Diyetisyen';
      case AICategory.training:
        return '30 yıllık Fitness Antren?r?';
      case AICategory.general:
        return '30 yıllık Genel Salık Uzman1';
      case AICategory.dietician:
        return '20 yıllık Profesyonel T?rk Diyetisyeni';
    }
  }

  String _getProfilOzeti() {
    if (_kullaniciProfili == null) return '';
    
    final p = _kullaniciProfili!;
    final hedefText = _getHedefText(p.hedef);
    
    return '${p.yas} ya_ ⬢ ${p.mevcutKilo.toStringAsFixed(0)}kg ⬢ ${p.boy.toStringAsFixed(0)}cm ⬢ $hedefText';
  }

  String _getHedefText(Hedef hedef) {
    return hedef.aciklama;
  }
}

// Chat Message Model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// Chat Bubble Widget
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Color categoryColor;

  const ChatBubble({
    super.key,
    required this.message,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? categoryColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: message.isUser ? const Radius.circular(4) : null,
                  bottomLeft: !message.isUser ? const Radius.circular(4) : null,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dk ?nce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} sa ?nce';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}


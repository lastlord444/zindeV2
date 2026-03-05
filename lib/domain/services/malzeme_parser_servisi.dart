// lib/domain/services/malzeme_parser_servisi.dart
// Malzeme metin parser servisi

/// Malzeme metni parser - yemek malzeme listesini parse eder
class MalzemeParserServisi {
  /// Malzeme metnini parse et
  static List<Map<String, dynamic>> parse(String malzemeMetni) {
    if (malzemeMetni.isEmpty) return [];
    return malzemeMetni.split('\n')
        .where((s) => s.trim().isNotEmpty)
        .map((satir) => {'metin': satir.trim()})
        .toList();
  }
}

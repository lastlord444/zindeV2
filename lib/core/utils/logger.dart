// lib/core/utils/logger.dart
// ✅ Web-safe logger wrapper

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Web-safe uygulama logger'1
/// Platform.isAndroid yerine kIsWeb kullanır
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 80,
      colors: !kIsWeb, // Web'de renk desteği yok
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.trace : Level.warning,
  );

  // ─── Türke ana metodlar ───────────────────────────────────────────────
  static void bilgi(String mesaj) => _logger.i(mesaj);
  static void hata(String mesaj, [Object? hata, StackTrace? stackTrace]) =>
      _logger.e(mesaj, error: hata, stackTrace: stackTrace);
  static void uyari(String mesaj) => _logger.w(mesaj);
  static void debug(String mesaj) => _logger.d(mesaj);
  static void verbose(String mesaj) => _logger.t(mesaj);

  // ─── V1 UI uyumluluk - İngilizce takma isimler ─────────────────────────
  static void info(String mesaj) => _logger.i(mesaj);
  static void error(String mesaj, [Object? err, StackTrace? st]) =>
      _logger.e(mesaj, error: err, stackTrace: st);
  static void warning(String mesaj) => _logger.w(mesaj);
  static void success(String mesaj) => _logger.i('✅ $mesaj');
  static void log(String mesaj) => _logger.d(mesaj);
}


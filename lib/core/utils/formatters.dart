// lib/core/utils/formatters.dart

import 'package:intl/intl.dart';

/// Veri formatlama yardımcılar1
class Formatters {
  // Tarih formatlayıcılar
  static final DateFormat _gunFormat = DateFormat('dd.MM.yyyy', 'tr_TR');
  static final DateFormat _gunAdi = DateFormat('EEEE', 'tr_TR');
  static final DateFormat _kisaGunAdi = DateFormat('EEE', 'tr_TR');
  static final DateFormat _ayYil = DateFormat('MMMM yyyy', 'tr_TR');
  static final DateFormat _supabaseFormat = DateFormat('yyyy-MM-dd');

  /// 15.03.2026 format1
  static String tarihFormatla(DateTime tarih) => _gunFormat.format(tarih);

  /// "Pazartesi" gibi tam gün ad1
  static String gunAdiFormatla(DateTime tarih) => _gunAdi.format(tarih);

  /// "Pzt" gibi kısa gün ad1
  static String kisaGunAdiFormatla(DateTime tarih) => _kisaGunAdi.format(tarih);

  /// "Mart 2026" format1
  static String ayYilFormatla(DateTime tarih) => _ayYil.format(tarih);

  /// Supabase DATE format1: "2026-03-15"
  static String supabaseGunFormatla(DateTime tarih) =>
      _supabaseFormat.format(tarih);

  // Say1 formatlayıcılar
  /// 2500 → "2.500"
  static String sayiFormatla(int sayi) =>
      NumberFormat('#,##0', 'tr_TR').format(sayi);

  /// 2500.5 → "2.500,5"
  static String ondalikFormatla(double sayi) =>
      NumberFormat('#,##0.#', 'tr_TR').format(sayi);

  /// 75.5 → "75,5 kg"
  static String kiloFormatla(double kilo) => '${ondalikFormatla(kilo)} kg';

  /// 175.0 → "175 cm"
  static String boyFormatla(double boy) => '${boy.toInt()} cm';

  /// 2500 → "2.500 kcal"
  static String kaloriFormatla(double kalori) =>
      '${sayiFormatla(kalori.round())} kcal';

  /// 150.5 → "151 g"
  static String gramFormatla(double gram) => '${gram.round()} g';

  /// 0.85 → "%85"
  static String yuzdesiFormatla(double oran) =>
      '%${(oran * 100).round()}';

  // Süre formatlayıcılar
  /// 45 dakika → "45 dk"
  static String dakikaFormatla(int dakika) {
    if (dakika < 60) return '$dakika dk';
    final saat = dakika ~/ 60;
    final kalan = dakika % 60;
    return kalan == 0 ? '$saat sa' : '$saat sa $kalan dk';
  }
}

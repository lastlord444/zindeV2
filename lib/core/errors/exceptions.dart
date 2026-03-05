// lib/core/errors/exceptions.dart

/// Supabase / API sunucu istisnas1
class SunucuIstisnasi implements Exception {
  final String mesaj;
  final int? statusKodu;
  const SunucuIstisnasi({this.mesaj = 'Sunucu hatas1', this.statusKodu});

  @override
  String toString() => 'SunucuIstisnasi: $mesaj (kod: $statusKodu)';
}

/// Ağ bağlantıs1 istisnas1
class AgIstisnasi implements Exception {
  final String mesaj;
  const AgIstisnasi({this.mesaj = 'İnternet bağlantıs1 yok'});

  @override
  String toString() => 'AgIstisnasi: $mesaj';
}

/// Veri bulunamad1 istisnas1
class BulunamadiIstisnasi implements Exception {
  final String mesaj;
  const BulunamadiIstisnasi({this.mesaj = 'Veri bulunamad1'});

  @override
  String toString() => 'BulunamadiIstisnasi: $mesaj';
}

/// Yerel depolama istisnas1
class DepolamaIstisnasi implements Exception {
  final String mesaj;
  const DepolamaIstisnasi({this.mesaj = 'Depolama hatas1'});

  @override
  String toString() => 'DepolamaIstisnasi: $mesaj';
}

/// Plan oluşturma istisnas1
class PlanIstisnasi implements Exception {
  final String mesaj;
  const PlanIstisnasi({this.mesaj = 'Plan oluşturulamad1'});

  @override
  String toString() => 'PlanIstisnasi: $mesaj';
}

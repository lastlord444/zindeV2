// lib/core/errors/exceptions.dart

/// Supabase / API sunucu istisnası
class SunucuIstisnasi implements Exception {
  final String mesaj;
  final int? statusKodu;
  const SunucuIstisnasi({this.mesaj = 'Sunucu hatası', this.statusKodu});

  @override
  String toString() => 'SunucuIstisnasi: $mesaj (kod: $statusKodu)';
}

/// Ağ bağlantısı istisnası
class AgIstisnasi implements Exception {
  final String mesaj;
  const AgIstisnasi({this.mesaj = 'İnternet bağlantısı yok'});

  @override
  String toString() => 'AgIstisnasi: $mesaj';
}

/// Veri bulunamadı istisnası
class BulunamadiIstisnasi implements Exception {
  final String mesaj;
  const BulunamadiIstisnasi({this.mesaj = 'Veri bulunamadı'});

  @override
  String toString() => 'BulunamadiIstisnasi: $mesaj';
}

/// Yerel depolama istisnası
class DepolamaIstisnasi implements Exception {
  final String mesaj;
  const DepolamaIstisnasi({this.mesaj = 'Depolama hatası'});

  @override
  String toString() => 'DepolamaIstisnasi: $mesaj';
}

/// Plan oluşturma istisnası
class PlanIstisnasi implements Exception {
  final String mesaj;
  const PlanIstisnasi({this.mesaj = 'Plan oluşturulamadı'});

  @override
  String toString() => 'PlanIstisnasi: $mesaj';
}

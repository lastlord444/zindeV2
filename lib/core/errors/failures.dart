// lib/core/errors/failures.dart

import 'package:equatable/equatable.dart';

/// Temel hata sınıfı
abstract class Failure extends Equatable {
  final String mesaj;
  const Failure(this.mesaj);

  @override
  List<Object?> get props => [mesaj];
}

/// Sunucu hatası (Supabase / API)
class SunucuHatasi extends Failure {
  const SunucuHatasi([super.mesaj = 'Sunucu hatası oluştu.']);
}

/// Ağ bağlantısı hatası
class AgBaglantisiHatasi extends Failure {
  const AgBaglantisiHatasi([super.mesaj = 'İnternet bağlantısı yok.']);
}

/// Veri bulunamadı hatası
class BulunamadiHatasi extends Failure {
  const BulunamadiHatasi([super.mesaj = 'İstenen veri bulunamadı.']);
}

/// Yerel depolama hatası
class DepolamaHatasi extends Failure {
  const DepolamaHatasi([super.mesaj = 'Veri kaydedilemedi.']);
}

/// Kimlik doğrulama hatası
class KimlikHatasi extends Failure {
  const KimlikHatasi([super.mesaj = 'Oturum süresi doldu, lütfen tekrar giriş yapın.']);
}

/// Plan oluşturma hatası (tolerans sağlanamadı)
class PlanHatasi extends Failure {
  const PlanHatasi([super.mesaj = 'Beslenme planı oluşturulamadı. Lütfen tekrar deneyin.']);
}

/// Genel beklenmedik hata
class BilinmeyenHata extends Failure {
  const BilinmeyenHata([super.mesaj = 'Beklenmedik bir hata oluştu.']);
}

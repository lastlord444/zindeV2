// lib/core/errors/failures.dart

import 'package:equatable/equatable.dart';

/// Temel hata sınıf1
abstract class Failure extends Equatable {
  final String mesaj;
  const Failure(this.mesaj);

  @override
  List<Object?> get props => [mesaj];
}

/// Sunucu hatas1 (Supabase / API)
class SunucuHatasi extends Failure {
  const SunucuHatasi([super.mesaj = 'Sunucu hatas1 oluştu.']);
}

/// Ağ bağlantıs1 hatas1
class AgBaglantisiHatasi extends Failure {
  const AgBaglantisiHatasi([super.mesaj = 'İnternet bağlantıs1 yok.']);
}

/// Veri bulunamad1 hatas1
class BulunamadiHatasi extends Failure {
  const BulunamadiHatasi([super.mesaj = 'İstenen veri bulunamad1.']);
}

/// Yerel depolama hatas1
class DepolamaHatasi extends Failure {
  const DepolamaHatasi([super.mesaj = 'Veri kaydedilemedi.']);
}

/// Kimlik doğrulama hatas1
class KimlikHatasi extends Failure {
  const KimlikHatasi([super.mesaj = 'Oturum süresi doldu, lütfen tekrar giriş yapın.']);
}

/// Plan oluşturma hatas1 (tolerans sağlanamad1)
class PlanHatasi extends Failure {
  const PlanHatasi([super.mesaj = 'Beslenme plan1 oluşturulamad1. Lütfen tekrar deneyin.']);
}

/// Genel beklenmedik hata
class BilinmeyenHata extends Failure {
  const BilinmeyenHata([super.mesaj = 'Beklenmedik bir hata oluştu.']);
}

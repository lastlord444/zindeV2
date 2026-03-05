// lib/domain/repositories/user_repository.dart

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../entities/user/kullanici_profili.dart';

/// Kullanıc1 profil repository arayüzü
abstract class UserRepository {
  /// Kullanıc1 profilini getir
  Future<Either<Failure, KullaniciProfili?>> profilGetir(String userId);

  /// Kullanıc1 profilini kaydet
  Future<Either<Failure, KullaniciProfili>> profilKaydet(KullaniciProfili profil);

  /// Kullanıc1 profilini güncelle
  Future<Either<Failure, KullaniciProfili>> profilGuncelle(KullaniciProfili profil);

  /// Kullanıc1 profilini sil
  Future<Either<Failure, void>> profilSil(String userId);

  /// Yerel önbellekteki profili getir (hızl1 erişim)
  Future<KullaniciProfili?> onbellektenProfilGetir();
}

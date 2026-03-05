// lib/domain/usecases/user/update_user_profile.dart

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user/kullanici_profili.dart';
import '../../repositories/user_repository.dart';

/// Kullanıc1 profilini güncelle use case'i
class UpdateUserProfile {
  final UserRepository _repository;

  const UpdateUserProfile(this._repository);

  Future<Either<Failure, KullaniciProfili>> call(KullaniciProfili profil) {
    return _repository.profilKaydet(profil);
  }
}

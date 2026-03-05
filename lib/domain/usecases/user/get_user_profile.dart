// lib/domain/usecases/user/get_user_profile.dart

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user/kullanici_profili.dart';
import '../../repositories/user_repository.dart';

/// Kullanıc1 profilini getir use case'i
class GetUserProfile {
  final UserRepository _repository;

  const GetUserProfile(this._repository);

  Future<Either<Failure, KullaniciProfili?>> call(String userId) {
    return _repository.profilGetir(userId);
  }
}

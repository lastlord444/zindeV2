// lib/presentation/bloc/profil/profil_event.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/user/kullanici_profili.dart';

abstract class ProfilEvent extends Equatable {
  const ProfilEvent();

  @override
  List<Object?> get props => [];
}

class ProfilYukle extends ProfilEvent {
  const ProfilYukle();
}

class ProfilDegisti extends ProfilEvent {
  final KullaniciProfili profil;
  const ProfilDegisti(this.profil);

  @override
  List<Object?> get props => [profil];
}

class ProfilKaydet extends ProfilEvent {
  final KullaniciProfili profil;
  const ProfilKaydet(this.profil);

  @override
  List<Object?> get props => [profil];
}

class ProfilTemizle extends ProfilEvent {
  const ProfilTemizle();
}


// lib/presentation/bloc/profil/profil_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/user/kullanici_profili.dart';
import '../../../domain/entities/nutrition/makro_hedefleri.dart';

abstract class ProfilState extends Equatable {
  const ProfilState();

  @override
  List<Object?> get props => [];
}

class ProfilInitial extends ProfilState {
  const ProfilInitial();
}

class ProfilYukleniyor extends ProfilState {
  const ProfilYukleniyor();
}

class ProfilYuklendi extends ProfilState {
  final KullaniciProfili profil;
  final MakroHedefleri makrolar;
  const ProfilYuklendi({required this.profil, required this.makrolar});

  @override
  List<Object?> get props => [profil, makrolar];
}

class ProfilGuncelleniyorState extends ProfilState {
  final KullaniciProfili profil;
  final MakroHedefleri makrolar;
  const ProfilGuncelleniyorState({required this.profil, required this.makrolar});

  @override
  List<Object?> get props => [profil, makrolar];
}

class ProfilMakrolariGuncellendi extends ProfilState {
  final MakroHedefleri makrolar;
  final bool toleranstaMi;
  final List<String> toleransDisindakiler;

  const ProfilMakrolariGuncellendi({
    required this.makrolar,
    required this.toleranstaMi,
    this.toleransDisindakiler = const [],
  });

  @override
  List<Object?> get props => [makrolar, toleranstaMi];
}

class ProfilKaydedildi extends ProfilState {
  final KullaniciProfili profil;
  const ProfilKaydedildi(this.profil);

  @override
  List<Object?> get props => [profil];
}

class ProfilHata extends ProfilState {
  final String mesaj;
  const ProfilHata(this.mesaj);

  @override
  List<Object?> get props => [mesaj];
}


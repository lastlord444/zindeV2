// lib/presentation/bloc/profil/profil_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/usecases/user/get_user_profile.dart';
import '../../../domain/usecases/user/update_user_profile.dart';
import '../../../domain/usecases/user/calculate_macros.dart';
import '../../../domain/entities/nutrition/makro_hedefleri.dart';
import 'profil_event.dart';
import 'profil_state.dart';

/// Profil BLoC
/// Kullanıc1 profili yönetir ve makrolar1 dinamik olarak günceller
class ProfilBloc extends Bloc<ProfilEvent, ProfilState> {
  final GetUserProfile _getProfil;
  final UpdateUserProfile _updateProfil;
  final CalculateMacros _calculateMacros;

  ProfilBloc({
    required GetUserProfile getProfil,
    required UpdateUserProfile updateProfil,
    required CalculateMacros calculateMacros,
  })  : _getProfil = getProfil,
        _updateProfil = updateProfil,
        _calculateMacros = calculateMacros,
        super(const ProfilInitial()) {
    on<ProfilYukle>(_onProfilYukle);
    on<ProfilDegisti>(_onProfilDegisti);
    on<ProfilKaydet>(_onProfilKaydet);
    on<ProfilTemizle>(_onProfilTemizle);
  }

  Future<void> _onProfilYukle(
      ProfilYukle event, Emitter<ProfilState> emit) async {
    emit(const ProfilYukleniyor());
    try {
      // Kullanıc1 ID'sini Supabase'den al
      // DI ile enjekte edilen SupabaseClient kullanılacak
      const userId = 'current_user'; // DI'dan alınacak
      final sonuc = await _getProfil(userId);
      sonuc.fold(
        (hata) => emit(ProfilHata(hata.mesaj)),
        (profil) {
          if (profil == null) {
            emit(const ProfilInitial());
          } else {
            final makrolar = _calculateMacros(profil);
            emit(ProfilYuklendi(profil: profil, makrolar: makrolar));
          }
        },
      );
    } catch (e) {
      AppLogger.hata('Profil yükleme hatas1', e);
      emit(ProfilHata(e.toString()));
    }
  }

  Future<void> _onProfilDegisti(
      ProfilDegisti event, Emitter<ProfilState> emit) async {
    // âš¡ Anlık makro güncellemesi - UI değiştiğinde hemen hesapla
    final yeniMakrolar = _calculateMacros(event.profil);

    emit(ProfilGuncelleniyorState(
      profil: event.profil,
      makrolar: yeniMakrolar,
    ));

    // Tolerans kontrolü
    final toleransDurumu = _toleransKontrolEt(yeniMakrolar);
    emit(ProfilMakrolariGuncellendi(
      makrolar: yeniMakrolar,
      toleranstaMi: toleransDurumu.isEmpty,
      toleransDisindakiler: toleransDurumu,
    ));
  }

  Future<void> _onProfilKaydet(
      ProfilKaydet event, Emitter<ProfilState> emit) async {
    emit(const ProfilYukleniyor());
    try {
      final sonuc = await _updateProfil(event.profil);
      sonuc.fold(
        (hata) => emit(ProfilHata(hata.mesaj)),
        (profil) {
          AppLogger.bilgi('Profil kaydedildi: ${profil.ad}');
          emit(ProfilKaydedildi(profil));
        },
      );
    } catch (e) {
      AppLogger.hata('Profil kaydetme hatas1', e);
      emit(ProfilHata(e.toString()));
    }
  }

  void _onProfilTemizle(ProfilTemizle event, Emitter<ProfilState> emit) {
    emit(const ProfilInitial());
  }

  /// Tolerans kontrolü - hangi makrolar dışarıda?
  List<String> _toleransKontrolEt(MakroHedefleri makrolar) {
    // Var olan planla karşılaştırma yerine sadece temel kontrol
    // Gerek tolerans kontrolü HomeBloc'ta yapılacak
    return [];
  }
}


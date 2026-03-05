// lib/data/repositories/workout_repository_impl.dart
// Antrenman repository - AntrenmanPlani V1 entity imzasına uygun

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/workout/antrenman_plani.dart';
import '../../domain/repositories/workout_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Antrenman repository implementasyonu
/// AntrenmanPlani entity: planAdi, zorlukSeviyesi, gunlukAntrenmanlar, aciklama
class WorkoutRepositoryImpl implements WorkoutRepository {
  @override
  Future<Either<Failure, List<AntrenmanPlani>>> programlariGetir() async {
    try {
      return Right(_localProgramlar());
    } catch (e) {
      return Left(BilinmeyenHata(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AntrenmanPlani>>> programlariFiltrele(
      String zorluk) async {
    final result = await programlariGetir();
    return result.fold(
      (f) => Left(f),
      (programlar) => Right(
        programlar
            .where((p) =>
                p.zorlukSeviyesi.toLowerCase() == zorluk.toLowerCase())
            .toList(),
      ),
    );
  }

  @override
  Future<Either<Failure, void>> antrenmanKaydet({
    required String userId,
    required String programId,
    required String programAdi,
    required DateTime tarih,
    required int sureDakika,
    required List<String> tamamlananEgzersizler,
  }) async {
    try {
      await Supabase.instance.client.from('workout_completions').insert({
        'user_id': userId,
        'program_id': programId,
        'program_adi': programAdi,
        'tarih': tarih.toIso8601String().substring(0, 10),
        'sure_dakika': sureDakika,
        'tamamlanan_egzersizler': tamamlananEgzersizler,
      });
      return const Right(null);
    } catch (e) {
      return Left(BilinmeyenHata(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> gecmisiGetir(
      String userId) async {
    try {
      final sonuc = await Supabase.instance.client
          .from('workout_completions')
          .select()
          .eq('user_id', userId)
          .order('tarih', ascending: false)
          .limit(30);
      return Right(sonuc);
    } catch (e) {
      return Left(BilinmeyenHata(e.toString()));
    }
  }

  /// Yerel sabit antrenman programlar1
  /// AntrenmanPlani entity field'larına uygun: planAdi, aciklama,
  /// gunlukAntrenmanlar, haftalikStrateji, beslenmeEntegrasyonu,
  /// motivasyonMesaji, olusturulmaTarihi, planSuresi, zorlukSeviyesi
  List<AntrenmanPlani> _localProgramlar() {
    final simdi = DateTime.now();
    return [
      AntrenmanPlani(
        planAdi: 'Kas Geliştirme - Başlang1',
        aciklama: '3 günlük başlang1 kas program1. Temel hareketlere odaklanır.',
        zorlukSeviyesi: 'Başlang1',
        planSuresi: 7,
        haftalikStrateji: 'Haftada 3 gün full body antrenman',
        beslenmeEntegrasyonu: 'Yüksek protein alım1 önerilir (2g/kg)',
        motivasyonMesaji: 'Her büyük yolculuk küük bir adımla başlar! 💪',
        olusturulmaTarihi: simdi,
        gunlukAntrenmanlar: [
          const GunlukAntrenman(
            gun: 'Pazartesi',
            odak: 'Göğüs & Omuz',
            sure: '45 dk',
            ozelNotlar: 'Isınma: 5 dk yürüyüş',
            hareketler: [
              Hareket(hareket: 'Bench Press', set: 3, tekrar: '10', dinlenme: '90s', ipucu: 'Kürek kemiklerini sıkıştır'),
              Hareket(hareket: 'Squat', set: 3, tekrar: '10', dinlenme: '90s', ipucu: 'Diz parmak hizasında'),
              Hareket(hareket: 'Shoulder Press', set: 3, tekrar: '10', dinlenme: '60s', ipucu: 'Core sık1 tut'),
            ],
          ),
          const GunlukAntrenman(
            gun: 'Çarşamba',
            odak: 'Sırt & Bicep',
            sure: '45 dk',
            ozelNotlar: 'Dinlenme günü yoktur, aktif toparlanma',
            hareketler: [
              Hareket(hareket: 'Pull-Up', set: 3, tekrar: '8', dinlenme: '90s', ipucu: 'Tam uzanma ile başla'),
              Hareket(hareket: 'Barbell Row', set: 3, tekrar: '10', dinlenme: '90s', ipucu: 'Sırta değil ellere ek'),
              Hareket(hareket: 'Bicep Curl', set: 3, tekrar: '12', dinlenme: '60s', ipucu: 'Dirsegi sabit tut'),
            ],
          ),
          const GunlukAntrenman(
            gun: 'Cuma',
            odak: 'Bacak & Core',
            sure: '45 dk',
            ozelNotlar: 'Hafta sonu dinlenme',
            hareketler: [
              Hareket(hareket: 'Squat', set: 4, tekrar: '8', dinlenme: '120s', ipucu: 'Ağırlık topuklarda'),
              Hareket(hareket: 'Deadlift', set: 3, tekrar: '8', dinlenme: '120s', ipucu: 'Sırt düz kalsın'),
              Hareket(hareket: 'Plank', set: 3, tekrar: '60s', dinlenme: '60s', ipucu: 'Kalay1 düşürme'),
            ],
          ),
        ],
      ),
      AntrenmanPlani(
        planAdi: 'Kuvvet Program1 - Orta',
        aciklama: '5x5 kuvvet program1. Maksimum gü gelişimi iin optimize edilmiştir.',
        zorlukSeviyesi: 'Orta',
        planSuresi: 7,
        haftalikStrateji: 'Haftada 3 gün 5x5 formas1, progressive overload',
        beslenmeEntegrasyonu: 'Kalori fazlas1 + yüksek protein (2.2g/kg)',
        motivasyonMesaji: 'Kuvvet gecede gelmiyor, sabır ve tutarlılık ister! 🔥',
        olusturulmaTarihi: simdi,
        gunlukAntrenmanlar: [
          const GunlukAntrenman(
            gun: 'Pazartesi',
            odak: 'Squat & Bench',
            sure: '60 dk',
            ozelNotlar: 'Her haftada ağırlık artır',
            hareketler: [
              Hareket(hareket: 'Squat 5x5', set: 5, tekrar: '5', dinlenme: '3dk', ipucu: 'Maksimum yük'),
              Hareket(hareket: 'Bench Press 5x5', set: 5, tekrar: '5', dinlenme: '3dk', ipucu: 'Göğüs tam temas'),
              Hareket(hareket: 'Barbell Row 5x5', set: 5, tekrar: '5', dinlenme: '3dk', ipucu: 'Explosive ekiş'),
            ],
          ),
          const GunlukAntrenman(
            gun: 'Çarşamba',
            odak: 'OHP & Deadlift',
            sure: '60 dk',
            ozelNotlar: 'Deadlift iin iyi ısın',
            hareketler: [
              Hareket(hareket: 'Overhead Press 5x5', set: 5, tekrar: '5', dinlenme: '3dk', ipucu: 'Core sık1'),
              Hareket(hareket: 'Deadlift ıx5', set: 1, tekrar: '5', dinlenme: '5dk', ipucu: 'Tek ağır set'),
            ],
          ),
        ],
      ),
      AntrenmanPlani(
        planAdi: 'Yağ Yakım1 - HIIT',
        aciklama: 'Yüksek yoğunluklu interval antrenman. Kısa sürede maksimum kalori yakım1.',
        zorlukSeviyesi: 'Orta',
        planSuresi: 7,
        haftalikStrateji: 'Haftada 4 gün HIIT + 2 gün aktif dinlenme',
        beslenmeEntegrasyonu: 'Kalori aığı, karbonhidrat zamanlamas1 önemli',
        motivasyonMesaji: 'Terle, yakıt, dönüş! Her damla bir adım! 🏃',
        olusturulmaTarihi: simdi,
        gunlukAntrenmanlar: [
          const GunlukAntrenman(
            gun: 'Pazartesi / Sal1 / Perşembe / Cuma',
            odak: 'HIIT Kardiyo',
            sure: '30 dk',
            ozelNotlar: '5dk ısınma + 20dk HIIT + 5dk soğuma',
            hareketler: [
              Hareket(hareket: 'Sprint', set: 8, tekrar: '30s', dinlenme: '30s', ipucu: 'Maksimum hız'),
              Hareket(hareket: 'Burpee', set: 4, tekrar: '10', dinlenme: '20s', ipucu: 'Full vücut'),
              Hareket(hareket: 'Jump Squat', set: 4, tekrar: '15', dinlenme: '20s', ipucu: 'Soft landing'),
            ],
          ),
        ],
      ),
      AntrenmanPlani(
        planAdi: 'PPL - İleri Seviye',
        aciklama: 'Push-Pull-Legs split. Haftalık 6 gün antrenman, maksimum kas hypertrophy.',
        zorlukSeviyesi: 'İleri',
        planSuresi: 7,
        haftalikStrateji: 'Push-Pull-Legs x2 haftada 6 gün',
        beslenmeEntegrasyonu: 'Yüksek kalori, yüksek protein, karbonhidrat zamanlamas1',
        motivasyonMesaji: 'Elite seviye iin elite aba gerekir! 🏆',
        olusturulmaTarihi: simdi,
        gunlukAntrenmanlar: [
          const GunlukAntrenman(
            gun: 'Pazartesi / Perşembe (Push)',
            odak: 'Göğüs & Omuz & Tricep',
            sure: '75 dk',
            ozelNotlar: 'Yük progressif arttır',
            hareketler: [
              Hareket(hareket: 'İnkline Bench Press', set: 4, tekrar: '8', dinlenme: '2dk', ipucu: '70-75% ıRM'),
              Hareket(hareket: 'Omuz Press', set: 4, tekrar: '10', dinlenme: '90s', ipucu: 'Tam hareket aıs1'),
              Hareket(hareket: 'Tricep Pushdown', set: 3, tekrar: '12', dinlenme: '60s', ipucu: 'Dirsek sabit'),
            ],
          ),
          const GunlukAntrenman(
            gun: 'Sal1 / Cuma (Pull)',
            odak: 'Sırt & Bicep',
            sure: '75 dk',
            ozelNotlar: '',
            hareketler: [
              Hareket(hareket: 'Lat Pulldown', set: 4, tekrar: '10', dinlenme: '90s', ipucu: 'Wide grip'),
              Hareket(hareket: 'Barbell Row', set: 4, tekrar: '8', dinlenme: '2dk', ipucu: 'Overhand grip'),
              Hareket(hareket: 'Barbell Curl', set: 3, tekrar: '12', dinlenme: '60s', ipucu: 'Supinate wrist'),
            ],
          ),
          const GunlukAntrenman(
            gun: 'Çarşamba / Cumartesi (Legs)',
            odak: 'Bacak & Core',
            sure: '75 dk',
            ozelNotlar: '',
            hareketler: [
              Hareket(hareket: 'Squat', set: 4, tekrar: '8', dinlenme: '2dk', ipucu: 'ATG depth'),
              Hareket(hareket: 'Leg Press', set: 4, tekrar: '10', dinlenme: '2dk', ipucu: 'Geniş a1'),
              Hareket(hareket: 'Romanian Deadlift', set: 3, tekrar: '10', dinlenme: '90s', ipucu: 'Hamstring stretch'),
            ],
          ),
        ],
      ),
    ];
  }
}

import 'package:equatable/equatable.dart';

enum EgzersizKategorisi {
  kardiyovaskuler,
  guc,
  esneklik,
  denge,
  hiit,
  yoga,
  pilates;

  String get displayName {
    switch (this) {
      case EgzersizKategorisi.kardiyovaskuler:
        return 'Kardiyovasküler';
      case EgzersizKategorisi.guc:
        return 'Gü';
      case EgzersizKategorisi.esneklik:
        return 'Esneklik';
      case EgzersizKategorisi.denge:
        return 'Denge';
      case EgzersizKategorisi.hiit:
        return 'HIIT';
      case EgzersizKategorisi.yoga:
        return 'Yoga';
      case EgzersizKategorisi.pilates:
        return 'Pilates';
    }
  }

  String get emoji {
    switch (this) {
      case EgzersizKategorisi.kardiyovaskuler:
        return '🏃';
      case EgzersizKategorisi.guc:
        return '💪';
      case EgzersizKategorisi.esneklik:
        return '🤸';
      case EgzersizKategorisi.denge:
        return '⚖️';
      case EgzersizKategorisi.hiit:
        return '🔥';
      case EgzersizKategorisi.yoga:
        return '🧘';
      case EgzersizKategorisi.pilates:
        return '🤸‍♀️';
    }
  }
}

enum Zorluk {
  baslangic,
  orta,
  ileri,
  profesyonel;

  String get displayName {
    switch (this) {
      case Zorluk.baslangic:
        return 'Başlang1';
      case Zorluk.orta:
        return 'Orta';
      case Zorluk.ileri:
        return 'İleri';
      case Zorluk.profesyonel:
        return 'Profesyonel';
    }
  }

  String get emoji {
    switch (this) {
      case Zorluk.baslangic:
        return '🟢';
      case Zorluk.orta:
        return '🟡';
      case Zorluk.ileri:
        return '🟠';
      case Zorluk.profesyonel:
        return '🔴';
    }
  }
}

enum KasGrubu {
  gogus,
  sirt,
  bacak,
  omuz,
  kol,
  karin,
  kardiyo,
  tumVucut;

  String get displayName {
    switch (this) {
      case KasGrubu.gogus:
        return 'Göğüs';
      case KasGrubu.sirt:
        return 'Sırt';
      case KasGrubu.bacak:
        return 'Bacak';
      case KasGrubu.omuz:
        return 'Omuz';
      case KasGrubu.kol:
        return 'Kol';
      case KasGrubu.karin:
        return 'Karın';
      case KasGrubu.kardiyo:
        return 'Kardiyo';
      case KasGrubu.tumVucut:
        return 'Tüm Vücut';
    }
  }

  String get emoji {
    switch (this) {
      case KasGrubu.gogus:
        return '💪';
      case KasGrubu.sirt:
        return '🏋️';
      case KasGrubu.bacak:
        return '🦵';
      case KasGrubu.omuz:
        return '🤸';
      case KasGrubu.kol:
        return '💪';
      case KasGrubu.karin:
        return '🎯';
      case KasGrubu.kardiyo:
        return '🏃';
      case KasGrubu.tumVucut:
        return '🔥';
    }
  }
}

class Egzersiz extends Equatable {
  final String id;
  final String ad;
  final String aciklama;
  final int sure; // saniye cinsinden
  final int kalori;
  final Zorluk zorluk;
  final KasGrubu kasGrubu;
  final EgzersizKategorisi kategori;
  final List<KasGrubu> hedefKaslar; // Birden fazla kas grubu alışabilir
  final List<String> talimatlar; // Adım adım talimatlar
  final int? tekrarSayisi; // Ka tekrar (opsiyonel)
  final int? setSayisi; // Ka set (opsiyonel)
  final String? videoUrl;
  final List<String> ekipmanlar;
  final String? gorselUrl;

  const Egzersiz({
    required this.id,
    required this.ad,
    required this.aciklama,
    required this.sure,
    required this.kalori,
    required this.zorluk,
    required this.kasGrubu,
    required this.kategori,
    this.hedefKaslar = const [],
    this.talimatlar = const [],
    this.tekrarSayisi,
    this.setSayisi,
    this.videoUrl,
    this.ekipmanlar = const [],
    this.gorselUrl,
  });

  String get formattedSure {
    final dakika = sure ~/ 60;
    final saniye = sure % 60;
    if (dakika > 0) {
      return saniye > 0 ? '${dakika}d ${saniye}s' : '${dakika}d';
    }
    return '${saniye}s';
  }

  String get formattedKalori => '$kalori kcal';

  /// Set/tekrar bilgisi özeti
  String? get setTekrarBilgisi {
    if (setSayisi != null && tekrarSayisi != null) {
      return '$setSayisi set x $tekrarSayisi tekrar';
    }
    return null;
  }

  /// Egzersiz özet bilgisi
  String get bilgiOzeti {
    return setTekrarBilgisi ?? formattedSure;
  }

  Egzersiz copyWith({
    String? id,
    String? ad,
    String? aciklama,
    int? sure,
    int? kalori,
    Zorluk? zorluk,
    KasGrubu? kasGrubu,
    EgzersizKategorisi? kategori,
    List<KasGrubu>? hedefKaslar,
    List<String>? talimatlar,
    int? tekrarSayisi,
    int? setSayisi,
    String? videoUrl,
    List<String>? ekipmanlar,
    String? gorselUrl,
  }) {
    return Egzersiz(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      aciklama: aciklama ?? this.aciklama,
      sure: sure ?? this.sure,
      kalori: kalori ?? this.kalori,
      zorluk: zorluk ?? this.zorluk,
      kasGrubu: kasGrubu ?? this.kasGrubu,
      kategori: kategori ?? this.kategori,
      hedefKaslar: hedefKaslar ?? this.hedefKaslar,
      talimatlar: talimatlar ?? this.talimatlar,
      tekrarSayisi: tekrarSayisi ?? this.tekrarSayisi,
      setSayisi: setSayisi ?? this.setSayisi,
      videoUrl: videoUrl ?? this.videoUrl,
      ekipmanlar: ekipmanlar ?? this.ekipmanlar,
      gorselUrl: gorselUrl ?? this.gorselUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ad,
        aciklama,
        sure,
        kalori,
        zorluk,
        kasGrubu,
        kategori,
        hedefKaslar,
        talimatlar,
        tekrarSayisi,
        setSayisi,
        videoUrl,
        ekipmanlar,
        gorselUrl,
      ];

  @override
  String toString() {
    return 'Egzersiz(id: $id, ad: $ad, zorluk: $zorluk, kasGrubu: $kasGrubu, sure: $sure, kalori: $kalori)';
  }
}

enum Hedef {
  cut('Kilo Vermek (Cut)'),
  bulk('Kilo Almak (Bulk)'),
  maintain('Formu Korumak (Maintain)');

  final String aciklama;
  const Hedef(this.aciklama);
}

enum AktiviteSeviyesi {
  hareketsiz('Hareketsiz (Ofis işi)'),
  hafifAktif('Hafif Aktif (Haftada 1-3 gün)'),
  ortaAktif('Orta Aktif (Haftada 3-5 gün)'),
  cokAktif('Çok Aktif (Haftada 6-7 gün)');

  final String aciklama;
  const AktiviteSeviyesi(this.aciklama);
}

enum Cinsiyet {
  erkek('Erkek'),
  kadin('Kadın');

  final String aciklama;
  const Cinsiyet(this.aciklama);
}

enum DiyetTipi {
  normal('Normal'),
  vejetaryen('Vejetaryen'),
  vegan('Vegan');

  final String aciklama;
  const DiyetTipi(this.aciklama);

  // ⭐ Her diyet tipinin varsayılan kısıtlamalar1
  List<String> get varsayilanKisitlamalar {
    switch (this) {
      case DiyetTipi.vejetaryen:
        return ['Et', 'Tavuk', 'Balık', 'Deniz Ürünleri'];
      case DiyetTipi.vegan:
        return [
          'Et',
          'Tavuk',
          'Balık',
          'Deniz Ürünleri',
          'Süt',
          'Peynir',
          'Yoğurt',
          'Yumurta',
          'Bal'
        ];
      case DiyetTipi.normal:
        return [];
    }
  }
}

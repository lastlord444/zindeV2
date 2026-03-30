// ============================================================================
// lib/presentation/pages/haftalik_rapor_page.dart
// HAFTALIK DETAYLI YEMEK UYUM RAPORU SAYFASI - AKTİF VERSİYON
// ============================================================================

import 'package:flutter/material.dart';
import '../../domain/entities/analytics/haftalik_rapor.dart';
import '../../domain/services/haftalik_rapor_servisi.dart';
import '../../core/di/injection_container.dart' as di;
import '../../domain/repositories/user_repository.dart';
import '../widgets/empty_state_widget.dart';

/// Haftalık Rapor Sayfası - AKTİF
///
/// Haftalık beslenme uyum raporunu gösterir.
/// ogunDurumlari içindeki 'yedi' ve 'onaylandi' durumlarına göre hesaplama yapar.
class HaftalikRaporPage extends StatefulWidget {
  final DateTime? baslangicTarihi;

  const HaftalikRaporPage({
    super.key,
    this.baslangicTarihi,
  });

  @override
  State<HaftalikRaporPage> createState() => _HaftalikRaporPageState();
}

class _HaftalikRaporPageState extends State<HaftalikRaporPage> {
  HaftalikRapor? _rapor;
  bool _yukleniyor = true;
  String? _hata;
  late DateTime _secilenTarih;

  final UserRepository _userRepo = di.sl<UserRepository>();
  final HaftalikRaporServisi _raporServisi = HaftalikRaporServisi();

  @override
  void initState() {
    super.initState();
    _secilenTarih =
        widget.baslangicTarihi ?? _haftaBaslangiciHesapla(DateTime.now());
    _raporuYukle();
  }

  DateTime _haftaBaslangiciHesapla(DateTime tarih) {
    final gunFarki = tarih.weekday - 1;
    return DateTime(tarih.year, tarih.month, tarih.day - gunFarki);
  }

  Future<void> _raporuYukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final kullanici = await _userRepo.onbellektenProfilGetir();
      if (kullanici == null) {
        throw Exception('Kullanıcı profili bulunamadı');
      }

      final haftaBaslangici = _haftaBaslangiciHesapla(_secilenTarih);
      final rapor = await _raporServisi.haftalikRaporOlustur(
        kullanici.id,
        haftaBaslangici,
      );

      setState(() {
        _rapor = rapor;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _hata = 'Rapor yüklenirken hata oluştu: $e';
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haftalık Detaylı Rapor'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _raporuYukle,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
              ? _hataWidget()
              : _rapor == null
                  ? const EmptyStateWidget(
                      type: EmptyStateType.noData,
                      title: 'Haftalık Rapor',
                      message:
                          'Bu hafta için henüz plan verisi yok.\n\n'
                          'Öğünlerinizi "Yedim" olarak işaretleyin.',
                      customIcon: Icons.analytics_outlined,
                      iconColor: Colors.teal,
                    )
                  : _raporWidget(),
    );
  }

  Widget _hataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _hata!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _raporuYukle,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _raporWidget() {
    final rapor = _rapor!;
    final haftaSonu = rapor.baslangicTarihi.add(const Duration(days: 6));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarih seçici
          _tarihSeciciWidget(rapor.baslangicTarihi, haftaSonu),
          const SizedBox(height: 20),

          // Ana özet kartı
          _anaOzetKarti(rapor),
          const SizedBox(height: 20),

          // Öğün sayısı özeti
          _ogunSayisiKarti(rapor),
          const SizedBox(height: 20),

          // Günlük detaylar
          _gunlukDetaylarBolumu(rapor),
          const SizedBox(height: 20),

          // Hedef analizi
          _hedefAnaliziKarti(rapor.hedefAnalizi),
          const SizedBox(height: 20),

          // Öneriler
          if (rapor.tavsiyeler.isNotEmpty) _onerilerKarti(rapor.tavsiyeler),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _tarihSeciciWidget(DateTime baslangic, DateTime bitis) {
    return InkWell(
      onTap: () async {
        final secilen = await showDatePicker(
          context: context,
          initialDate: _secilenTarih,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );

        if (secilen != null && mounted) {
          setState(() {
            _secilenTarih = secilen;
          });
          _raporuYukle();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.teal[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.teal[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.teal),
            const SizedBox(width: 8),
            Text(
              '${_tarihString(baslangic)} - ${_tarihString(bitis)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _anaOzetKarti(HaftalikRapor rapor) {
    // Uyum yüzdesine göre renk belirle
    final Color uyumRengi = rapor.ortalamaUyumYuzdesi >= 80
        ? Colors.green
        : rapor.ortalamaUyumYuzdesi >= 60
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.teal[700], size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rapor.basariDurumu,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Haftalık özet metni
            Text(
              rapor.haftalikOzet,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            // İlerleme çubuğu
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: rapor.ortalamaUyumYuzdesi / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(uyumRengi),
                minHeight: 14,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '%${rapor.ortalamaUyumYuzdesi.toStringAsFixed(1)} Genel Uyum',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: uyumRengi,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ogunSayisiKarti(HaftalikRapor rapor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _sayacWidget(
              '${rapor.toplamTamamlananOgun}',
              'Tamamlanan\nÖğün',
              Colors.green,
              Icons.check_circle,
            ),
            Container(width: 1, height: 50, color: Colors.grey[300]),
            _sayacWidget(
              '${rapor.toplamOgunSayisi}',
              'Toplam\nÖğün',
              Colors.blue,
              Icons.restaurant,
            ),
            Container(width: 1, height: 50, color: Colors.grey[300]),
            _sayacWidget(
              rapor.toplamOgunSayisi > 0
                  ? '%${((rapor.toplamTamamlananOgun / rapor.toplamOgunSayisi) * 100).toStringAsFixed(0)}'
                  : '%0',
              'Haftalık\nOran',
              Colors.teal,
              Icons.percent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sayacWidget(
      String deger, String etiket, Color renk, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: renk, size: 28),
        const SizedBox(height: 4),
        Text(
          deger,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: renk,
          ),
        ),
        Text(
          etiket,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _gunlukDetaylarBolumu(HaftalikRapor rapor) {
    if (rapor.gunlukVeriler.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Henüz günlük veri yok.\n'
            'Öğünlerinizi "Yedim" veya "Atladım" olarak işaretleyin.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Günlük Detaylar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rapor.gunlukVeriler.entries.map((entry) {
              return _gunlukSatiri(entry.value);
            }),
          ],
        ),
      ),
    );
  }

  Widget _gunlukSatiri(GunlukUyumVerisi veri) {
    final uyumRengi = veri.uyumYuzdesi >= 80
        ? Colors.green
        : veri.uyumYuzdesi >= 60
            ? Colors.orange
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '${veri.tarih.day}/${veri.tarih.month}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  veri.gunDurumu,
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  '${veri.tamamlananOgunSayisi}/${veri.toplamOgunSayisi} öğün'
                  ' • ${veri.tamamlananKalori.toStringAsFixed(0)}/'
                  '${veri.hedefKalori.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: uyumRengi,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '%${veri.uyumYuzdesi.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hedefAnaliziKarti(HedefAnalizi analiz) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hedef Analizi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (analiz.enIyiGun != null)
              _analizSatiri(
                  '🏆 En İyi Gün',
                  _tarihString(analiz.enIyiGun!.tarih)),
            if (analiz.enKotuGun != null)
              _analizSatiri(
                  '📉 En Kötü Gün',
                  _tarihString(analiz.enKotuGun!.tarih)),
            _analizSatiri(
                '📊 Ortalama Uyum',
                '%${analiz.ortalamaUyum.toStringAsFixed(1)}'),
            _analizSatiri('🎯 Tutarlılık', analiz.tutarlilikDurumu),
            _analizSatiri('📈 Trend', analiz.gelismeTrendi),
          ],
        ),
      ),
    );
  }

  Widget _analizSatiri(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(baslik, style: const TextStyle(fontSize: 14)),
          Text(
            deger,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _onerilerKarti(List<String> oneriler) {
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'Öneriler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...oneriler.map(
              (o) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(o)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tarihString(DateTime tarih) {
    return '${tarih.day}.${tarih.month}.${tarih.year}';
  }
}

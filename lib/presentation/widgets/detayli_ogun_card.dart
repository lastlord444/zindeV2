import 'package:flutter/material.dart';
import '../../domain/entities/nutrition/yemek.dart';
import '../../domain/entities/nutrition/yemek_onay_sistemi.dart';
import '../pages/meal_detail_page.dart';

class DetayliOgunCard extends StatefulWidget {
  final Yemek yemek;
  final YemekDurumu yemekDurumu;
  final VoidCallback? onYedimPressed;
  final VoidCallback? onYemedimPressed;
  final VoidCallback? onOnayPressed;
  final VoidCallback? onSifirlaPressed;
  final VoidCallback? onAlternatifPressed;
  final Function(Yemek yemek, String malzemeMetni, int malzemeIndex)?
      onMalzemeAlternatifiPressed;

  const DetayliOgunCard({
    super.key,
    required this.yemek,
    required this.yemekDurumu,
    this.onYedimPressed,
    this.onYemedimPressed,
    this.onOnayPressed,
    this.onSifirlaPressed,
    this.onAlternatifPressed,
    this.onMalzemeAlternatifiPressed,
  });

  @override
  State<DetayliOgunCard> createState() => _DetayliOgunCardState();
}

class _DetayliOgunCardState extends State<DetayliOgunCard> {
  Yemek? _secilenAlternatif;

  @override
  void didUpdateWidget(DetayliOgunCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.yemek.id != widget.yemek.id) {
      _secilenAlternatif = null;
    }
  }

  Yemek get _aktifYemek => _secilenAlternatif ?? widget.yemek;

  void _showAlternatiflerBottomSheet(BuildContext context) {
    final alternatifler = _aktifYemek.alternatifYemekler.take(2).toList();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alternatif Yemekler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (alternatifler.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Bu öğün için alternatif bulunamadı.'),
                )
              else
                ...alternatifler.map((altYemek) => ListTile(
                  title: Text(altYemek.ad, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${altYemek.kalori.toStringAsFixed(0)} kcal | P: ${altYemek.protein.toStringAsFixed(0)}g | K: ${altYemek.karbonhidrat.toStringAsFixed(0)}g | Y: ${altYemek.yag.toStringAsFixed(0)}g'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _secilenAlternatif = altYemek;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Seç'),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }

  void _showNedenBuDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neden bu?'),
        content: const Text('Bu öğün günlük hedeflerine yakın kaldığı, protein/kalori dengesini koruduğu ve aynı öğün türünde uygun alternatifler sunduğu için seçildi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MealDetailPage(yemek: _aktifYemek),
          ),
        );
      },
      child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getDurumRengi(),
                width: _getDurumRengi() == Colors.transparent ? 0 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getOgunRengi().withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getOgunRengi().withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            _aktifYemek.ogun.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _aktifYemek.ogun.ad,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getOgunRengi(),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _aktifYemek.ad,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getDurumRengi(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getDurumIcon(),
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getDurumMetni(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildMalzemeler(),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMakroBadge(
                        '🔥',
                        _aktifYemek.kalori.toStringAsFixed(0),
                        'kcal',
                        Colors.orange,
                      ),
                      _buildMakroBadge(
                        '🥩',
                        _aktifYemek.protein.toStringAsFixed(0),
                        'g P',
                        Colors.red,
                      ),
                      _buildMakroBadge(
                        '🥖',
                        _aktifYemek.karbonhidrat.toStringAsFixed(0),
                        'g K',
                        Colors.amber,
                      ),
                      _buildMakroBadge(
                        '🥑',
                        _aktifYemek.yag.toStringAsFixed(0),
                        'g Y',
                        Colors.green,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      if (widget.yemekDurumu == YemekDurumu.bekliyor) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: widget.onYedimPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Yedim',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: widget.onYemedimPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.thumb_down, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Yemedim',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (widget.yemekDurumu == YemekDurumu.yedi) ...[
                        Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: const Text(
                                'Yediğinizi belirttiniz. Onaylamak için "Onayla" butonuna basın.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: widget.onOnayPressed,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.verified, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Onayla & Kilitle',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: widget.onSifirlaPressed,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade400,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.undo, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Geri Al',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ] else if (widget.yemekDurumu == YemekDurumu.onaylandi) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: const Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock, color: Colors.green, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'KİLİTLENDİ',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Bu öğün onaylandı ve rapor için kaydedildi.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (widget.yemekDurumu == YemekDurumu.ataldi) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.thumb_down, color: Colors.orange, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'YEMEDİM',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Bu öğünü yemediniz olarak işaretlediniz.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: widget.onSifirlaPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Sıfırla',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showAlternatiflerBottomSheet(context),
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: const Text('Değiştir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showNedenBuDialog(context),
                              icon: const Icon(Icons.help_outline, size: 18),
                              label: const Text('Neden bu?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMalzemeler() {
    final bool hasTarifWithGrams = _aktifYemek.tarif != null &&
        _aktifYemek.tarif!.contains('(') &&
        _aktifYemek.tarif!.contains('g)');

    if (_aktifYemek.malzemeler.isNotEmpty) {
      return _buildMalzemelerListesi(_aktifYemek.malzemeler);
    } else if (hasTarifWithGrams) {
      final parseMalzemeler = _parseMalzemelerFromTarif(_aktifYemek.tarif!);
      return _buildMalzemelerListesi(parseMalzemeler);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildMalzemelerListesi(List<String> malzemeler) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Malzemeler:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...malzemeler.asMap().entries.map((entry) {
            final index = entry.key;
            final malzeme = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _getOgunRengi(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      malzeme,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (malzemeler.isNotEmpty && !_malzemeMiktarIceriyorMu(malzeme))
                    Text(
                      '~${(_aktifYemek.baseWeightG / malzemeler.length).toStringAsFixed(0)} g',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (widget.onMalzemeAlternatifiPressed != null)
                    InkWell(
                      onTap: () => widget.onMalzemeAlternatifiPressed!(
                        _aktifYemek,
                        malzeme,
                        index,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: _getOgunRengi().withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMakroBadge(
    String emoji,
    String deger,
    String birim,
    Color renk,
  ) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          deger,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: renk,
          ),
        ),
        Text(
          birim,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  List<String> _parseMalzemelerFromTarif(String tarif) {
    final malzemeler = tarif
        .split(',')
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList();
    return malzemeler;
  }

  Color _getOgunRengi() {
    switch (_aktifYemek.ogun) {
      case OgunTipi.kahvalti:
        return Colors.orange;
      case OgunTipi.araOgun1:
        return Colors.blue;
      case OgunTipi.ogle:
        return Colors.red;
      case OgunTipi.araOgun2:
        return Colors.green;
      case OgunTipi.aksam:
        return Colors.purple;
      case OgunTipi.geceAtistirma:
        return Colors.indigo;
      case OgunTipi.cheatMeal:
        return Colors.pink;
    }
  }

  Color _getDurumRengi() {
    switch (widget.yemekDurumu) {
      case YemekDurumu.bekliyor:
        return Colors.transparent;
      case YemekDurumu.yedi:
        return Colors.blue.shade300;
      case YemekDurumu.onaylandi:
        return Colors.green.shade300;
      case YemekDurumu.ataldi:
        return Colors.red.shade300;
    }
  }

  IconData _getDurumIcon() {
    switch (widget.yemekDurumu) {
      case YemekDurumu.bekliyor:
        return Icons.schedule;
      case YemekDurumu.yedi:
        return Icons.check_circle;
      case YemekDurumu.onaylandi:
        return Icons.verified;
      case YemekDurumu.ataldi:
        return Icons.block;
    }
  }

  String _getDurumMetni() {
    switch (widget.yemekDurumu) {
      case YemekDurumu.bekliyor:
        return 'Bekliyor';
      case YemekDurumu.yedi:
        return 'Yedi';
      case YemekDurumu.onaylandi:
        return 'Onaylandı';
      case YemekDurumu.ataldi:
        return 'Yemedim';
    }
  }

  bool _malzemeMiktarIceriyorMu(String malzeme) {
    final lower = malzeme.toLowerCase().trim();
    
    if (RegExp(r'^\d').hasMatch(lower)) return true;
    
    if (RegExp(r'\d+\s*g\b').hasMatch(lower)) return true;
    if (RegExp(r'\d+\s*gr\b').hasMatch(lower)) return true;
    
    final miktarKelimeleri = [
      'adet', 'dilim', 'porsiyon', 'bardak', 'kaşığı', 'kaşık',
      'kase', 'demet', 'tutam', 'çay kaşığı', 'yemek kaşığı',
      'su bardağı', 'çorba kaşığı', 'avuç', 'parça', 'yaprak',
      'dal', 'diş', 'boy', 'orta boy', 'küçük', 'büyük',
      'ml', 'lt', 'litre', 'kg', 'gram', 'miktar',
    ];
    
    for (final kelime in miktarKelimeleri) {
      if (lower.contains(kelime)) return true;
    }
    
    return false;
  }
}

import 'package:flutter/material.dart';
import '../../domain/entities/yemek.dart';
// HeroTags iin

class MealDetailPage extends StatelessWidget {
  final Yemek yemek;

  const MealDetailPage({super.key, required this.yemek});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          yemek.ad,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Yemek Resmi (Hero olmadan)
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.purple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        yemek.ogun.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        yemek.ogun.ad.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple,
                        ),
                      ),
                      if (yemek.etiketler.isNotEmpty) ...[
                        const Spacer(),
                        Wrap(
                          spacing: 6,
                          children: yemek.etiketler.take(2).map((etiket) {
                            return Chip(
                              label: Text(
                                etiket,
                                style: const TextStyle(fontSize: 11),
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Makro Besin Değerleri
                  _buildSectionTitle('Makro Besinler'),
                  const SizedBox(height: 12),
                  _buildMacroRow('Kalori', yemek.kalori, 'kcal', Colors.orange),
                  _buildMacroRow('Protein', yemek.protein, 'g', Colors.red),
                  _buildMacroRow(
                      'Karbonhidrat', yemek.karbonhidrat, 'g', Colors.amber),
                  _buildMacroRow('Yağ', yemek.yag, 'g', Colors.green),
                  const SizedBox(height: 24),

                  // Malzemeler
                  _buildSectionTitle('Malzemeler'),
                  const SizedBox(height: 12),
                  ...yemek.malzemeler.map((malzeme) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.fiber_manual_record,
                                size: 10, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                malzeme,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            if (yemek.malzemeler.isNotEmpty && !_malzemeMiktarIceriyorMu(malzeme))
                              Text(
                                '~${(yemek.baseWeightG / yemek.malzemeler.length).toStringAsFixed(0)} g',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),

                  // Tarif
                  if (yemek.tarif != null && yemek.tarif!.isNotEmpty) ...[
                    _buildSectionTitle('Tarif'),
                    const SizedBox(height: 12),
                    Text(
                      yemek.tarif!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Ek Bilgiler
                  _buildSectionTitle('Ek Bilgiler'),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                      'Hazırlama Süresi', '${yemek.hazirlamaSuresi} dakika'),
                  _buildInfoRow(
                      'Zorluk', '${yemek.zorluk.ad} ${yemek.zorluk.emoji}'),
                  if (yemek.etiketler.isNotEmpty)
                    _buildInfoRow('Etiketler', yemek.etiketler.join(', ')),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildMacroRow(String label, double value, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)} $unit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty || value == ' ') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
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

import 'package:flutter/material.dart';
import '../../domain/entities/alternatif_besin_legacy.dart';

// ============================================================================
// ALTERNAT0F BES0N BOTTOM SHEET
// ============================================================================

class AlternatifBesinBottomSheet extends StatelessWidget {
  final String orijinalBesinAdi;
  final double orijinalMiktar;
  final String orijinalBirim;
  final List<AlternatifBesinLegacy> alternatifler;
  final String alerjiNedeni; // "Ceviz alerjiniz var" veya "Bulamıyorum"
  final VoidCallback? onClose; // YEN0: Kapatma callback'i

  const AlternatifBesinBottomSheet({
    super.key,
    required this.orijinalBesinAdi,
    required this.orijinalMiktar,
    required this.orijinalBirim,
    required this.alternatifler,
    required this.alerjiNedeni,
    this.onClose, // CALLBACK EKLEND0
  });

  static Future<AlternatifBesinLegacy?> goster(
    BuildContext context, {
    required String orijinalBesinAdi,
    required double orijinalMiktar,
    required String orijinalBirim,
    required List<AlternatifBesinLegacy> alternatifler,
    required String alerjiNedeni,
    VoidCallback? onClose, // YEN0: Callback parametresi
  }) {
    return showModalBottomSheet<AlternatifBesinLegacy>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AlternatifBesinBottomSheet(
        orijinalBesinAdi: orijinalBesinAdi,
        orijinalMiktar: orijinalMiktar,
        orijinalBirim: orijinalBirim,
        alternatifler: alternatifler,
        alerjiNedeni: alerjiNedeni,
        onClose: onClose, // CALLBACK GE�0R0LD0
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Ba_lık
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bu besini yiyemezsiniz',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alerjiNedeni,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Geri/Kapat butonu
                    IconButton(
                      onPressed: () {
                        // FIX: Kapatmadan �nce callback'i �aır (BLoC event tetiklenir)
                        onClose?.call();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Kapat',
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Orijinal besin
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.close, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${orijinalMiktar.toStringAsFixed(0)} $orijinalBirim $orijinalBesinAdi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Alternatifler listesi
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Row(
                  children: [
                    Icon(Icons.autorenew, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Alternatif Besinler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // FIX: Alternatif bulunamadıysa mesaj g�ster
                if (alternatifler.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Alternatif Besin Bulunamad1',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bu besin i�in uygun alternatif bulunamad1. L�tfen farkl1 bir besin se�in veya beslenme uzmanınıza danışın.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...alternatifler
                      .map((alt) => _buildAlternatifCard(context, alt)),

                const SizedBox(height: 80), // Alt bo_luk
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternatifCard(
      BuildContext context, AlternatifBesinLegacy alternatif) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context, alternatif);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ' ${alternatif.ad} se�ildi (${alternatif.miktar.toStringAsFixed(0)} ${alternatif.birim})',
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // �st kısım
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${alternatif.miktar.toStringAsFixed(0)} ${alternatif.birim} ${alternatif.ad}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              alternatif.neden,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Besin deerleri - =% FIX: Row �  Wrap (responsive listeler i�in)
                Wrap(
                  spacing: 8, // Yatay bo_luk
                  runSpacing: 8, // Dikey bo_luk (alt satır i�in)
                  children: [
                    _buildNutrientBadge(
                      '🔥',
                      '${alternatif.kalori.toStringAsFixed(0)} kcal',
                      Colors.orange,
                    ),
                    _buildNutrientBadge(
                      '=�',
                      '${alternatif.protein.toStringAsFixed(1)}g',
                      Colors.red,
                    ),
                    _buildNutrientBadge(
                      'x�a',
                      '${alternatif.karbonhidrat.toStringAsFixed(1)}g',
                      Colors.amber,
                    ),
                    _buildNutrientBadge(
                      '🥑',
                      '${alternatif.yag.toStringAsFixed(1)}g',
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientBadge(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


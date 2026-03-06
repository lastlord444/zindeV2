import 'package:flutter/material.dart';
import '../../domain/entities/yemek.dart';

// ============================================================================
// ALTERNAT0F YEMEK BOTTOM SHEET (STATELESS)
// Kullanıc1 bir yemei beenmezse, HomeBloc'tan gelen alternatif yemekleri g?sterir
// ============================================================================

class AlternatifYemekBottomSheet extends StatelessWidget {
  final Yemek mevcutYemek;
  final List<Yemek> alternatifYemekler; // Dinamik olarak HomeBloc'tan gelecek
  final Function(Yemek) onYemekSecildi;
  final VoidCallback? onClose; // YEN0: Kapatma callback'i

  const AlternatifYemekBottomSheet({
    super.key,
    required this.mevcutYemek,
    required this.alternatifYemekler,
    required this.onYemekSecildi,
    this.onClose, // CALLBACK EKLEND0
  });

  static Future<Yemek?> goster(
    BuildContext context, {
    required Yemek mevcutYemek,
    required List<Yemek> alternatifYemekler, // Dinamik olarak HomeBloc'tan gelecek
    required Function(Yemek) onYemekSecildi,
    VoidCallback? onClose, // YEN0: Callback parametresi
  }) {
    return showModalBottomSheet<Yemek>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AlternatifYemekBottomSheet(
        mevcutYemek: mevcutYemek,
        alternatifYemekler: alternatifYemekler,
        onYemekSecildi: onYemekSecildi,
        onClose: onClose, // CALLBACK GE?0R0LD0
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
          _buildHandle(),
          _buildHeader(context),
          _buildAlternatifListesi(context),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getOgunRengi().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.swap_horiz,
                  color: _getOgunRengi(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alternatif ${mevcutYemek.ogun.ad}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Size başka se?enekler buldum',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // FIX: Kapatmadan ?nce callback'i ?aır (BLoC event tetiklenir)
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
          _buildMevcutYemekKarti(),
        ],
      ),
    );
  }

  Widget _buildMevcutYemekKarti() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant_menu, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mevcut: ${mevcutYemek.ad}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${mevcutYemek.kalori.toStringAsFixed(0)} kcal | '
                  '${mevcutYemek.protein.toStringAsFixed(0)}g P | '
                  '${mevcutYemek.karbonhidrat.toStringAsFixed(0)}g K | '
                  '${mevcutYemek.yag.toStringAsFixed(0)}g Y',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternatifListesi(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Alternatif ?neriler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (alternatifYemekler.isEmpty)
            _buildAlternatifYokKarti()
          else
            ...alternatifYemekler.asMap().entries.map((entry) {
              final index = entry.key;
              final yemek = entry.value;
              return _buildAlternatifCard(context, yemek, index + 1);
            }),
          const SizedBox(height: 80), // Alt bo_luk
        ],
      ),
    );
  }

  Widget _buildAlternatifYokKarti() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Şu an alternatif bulunamad1',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternatifCard(BuildContext context, Yemek yemek, int siraNo) {
    final kaloriFark = yemek.kalori - mevcutYemek.kalori;
    final kaloriFarkYuzde =
        (kaloriFark.abs() / (mevcutYemek.kalori > 0 ? mevcutYemek.kalori : 1)) * 100;

    String kaloriFarkText;
    Color kaloriFarkRenk;

    if (kaloriFarkYuzde < 5) {
      kaloriFarkText = 'Neredeyse ayn1 kalori';
      kaloriFarkRenk = Colors.green;
    } else if (kaloriFark > 0) {
      kaloriFarkText = '+${kaloriFark.toStringAsFixed(0)} kcal daha fazla';
      kaloriFarkRenk = Colors.orange;
    } else {
      kaloriFarkText = '${kaloriFark.abs().toStringAsFixed(0)} kcal daha az';
      kaloriFarkRenk = Colors.blue;
    }

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
            Navigator.pop(context);
            onYemekSecildi(yemek);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(' ${yemek.ad} se?ildi'),
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
                _buildCardHeader(yemek, siraNo, kaloriFarkText, kaloriFarkRenk),
                if (yemek.malzemeler.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildMalzemeler(yemek),
                ],
                const SizedBox(height: 12),
                _buildMakroBadges(yemek),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(Yemek yemek, int siraNo, String kaloriFarkText, Color kaloriFarkRenk) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$siraNo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                yemek.ad,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kaloriFarkRenk.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  kaloriFarkText,
                  style: TextStyle(
                    fontSize: 11,
                    color: kaloriFarkRenk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: Colors.grey.shade400),
      ],
    );
  }

  Widget _buildMalzemeler(Yemek yemek) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Malzemeler:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: yemek.malzemeler.take(4).map((malzeme) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                malzeme,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              ),
            );
          }).toList(),
        ),
        if (yemek.malzemeler.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${yemek.malzemeler.length - 4} malzeme daha',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMakroBadges(Yemek yemek) {
    return Row(
      children: [
        _buildMakroBadge('🔥', '${yemek.kalori.toStringAsFixed(0)} kcal', Colors.orange),
        const SizedBox(width: 8),
        _buildMakroBadge('=?', '${yemek.protein.toStringAsFixed(0)}g', Colors.red),
        const SizedBox(width: 8),
        _buildMakroBadge('x?a', '${yemek.karbonhidrat.toStringAsFixed(0)}g', Colors.amber),
        const SizedBox(width: 8),
        _buildMakroBadge('🥑', '${yemek.yag.toStringAsFixed(0)}g', Colors.green),
      ],
    );
  }

  Widget _buildMakroBadge(String emoji, String text, Color color) {
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

  Color _getOgunRengi() {
    switch (mevcutYemek.ogun) {
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
}


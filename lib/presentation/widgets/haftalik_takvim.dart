import 'package:flutter/material.dart';

class HaftalikTakvim extends StatelessWidget {
  final DateTime secilenTarih;
  final Function(DateTime) onTarihSecildi;

  const HaftalikTakvim({
    super.key,
    required this.secilenTarih,
    required this.onTarihSecildi,
  });

  @override
  Widget build(BuildContext context) {
    // Haftanın başlangıcın1 bul (Pazartesi)
    final haftaBaslangici = secilenTarih.subtract(
      Duration(days: (secilenTarih.weekday - 1)),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final gun = haftaBaslangici.add(Duration(days: index));
          final secili = gun.day == secilenTarih.day &&
              gun.month == secilenTarih.month &&
              gun.year == secilenTarih.year;
          final bugun = gun.day == DateTime.now().day &&
              gun.month == DateTime.now().month &&
              gun.year == DateTime.now().year;

          return _buildGunKutusu(
            gun: gun,
            secili: secili,
            bugun: bugun,
            onTap: () => onTarihSecildi(gun),
          );
        }),
      ),
    );
  }

  Widget _buildGunKutusu({
    required DateTime gun,
    required bool secili,
    required bool bugun,
    required VoidCallback onTap,
  }) {
    // Türke gün isimleri
    final gunIsimleri = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final gunAdi = gunIsimleri[gun.weekday - 1];
    final gunSayisi = gun.day.toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: secili
              ? Colors.purple
              : bugun
                  ? Colors.purple.shade50
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: bugun && !secili ? Colors.purple : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              gunAdi.substring(0, 3).toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: secili
                    ? Colors.white
                    : bugun
                        ? Colors.purple
                        : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              gunSayisi,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: secili
                    ? Colors.white
                    : bugun
                        ? Colors.purple
                        : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


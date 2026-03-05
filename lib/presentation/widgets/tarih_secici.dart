import 'package:flutter/material.dart';

class TarihSecici extends StatelessWidget {
  final DateTime secilenTarih;
  final VoidCallback onGeriGit;
  final VoidCallback onIleriGit;

  const TarihSecici({
    super.key,
    required this.secilenTarih,
    required this.onGeriGit,
    required this.onIleriGit,
  });

  @override
  Widget build(BuildContext context) {
    // T�rk�e locale kullanmadan basit format
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Austos', 'Eyl�l', 'Ekim', 'Kasım', 'Aralık'
    ];
    final tarihStr = '${secilenTarih.day} ${months[secilenTarih.month - 1]} ${secilenTarih.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Geri butonu
          IconButton(
            onPressed: onGeriGit,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: Colors.purple.shade50,
              foregroundColor: Colors.purple,
            ),
          ),

          // Tarih g�sterimi
          Expanded(
            child: Text(
              tarihStr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // 0leri butonu
          IconButton(
            onPressed: onIleriGit,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: Colors.purple.shade50,
              foregroundColor: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }
}


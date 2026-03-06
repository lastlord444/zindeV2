// ============================================================================
// lib/presentation/pages/haftalik_rapor_page.dart
// HAFTAL0K DETAYLI YEMEK UYUM RAPORU SAYFASI
// ============================================================================

import 'package:flutter/material.dart';
import '../widgets/empty_state_widget.dart';

/// x` Haftalık Rapor Sayfas1
///
/// NOT: Bu �zellik Supabase entegrasyonuyla yakında aktif olacak.
/// Şu an placeholder olarak g�steriliyor.
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haftalık Detaylı Rapor'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // Placeholder - yenile fonksiyonu
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rapor özelliği yakında aktif')),
              );
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: const EmptyStateWidget(
        type: EmptyStateType.noData,
        title: 'Haftalık Rapor',
        message: 'Haftalık beslenme uyum raporu Supabase entegrasyonuyla birlikte yakında aktif olacak.\n\n'
            'Bu sayfada:\n'
            '⬢ Haftalık uyum yüzdesi\n'
            '⬢ Günlük öğün detayları\n'
            '⬢ Makro analizi\n'
            '⬢ Öneriler ve tavsiyeler\n\n'
            'gibi bilgileri görebileceksiniz.',
        customIcon: Icons.analytics_outlined,
        iconColor: Colors.teal,
      ),
    );
  }
}

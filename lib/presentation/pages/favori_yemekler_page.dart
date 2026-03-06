// lib/presentation/pages/favori_yemekler_page.dart

import 'package:flutter/material.dart';
import '../widgets/empty_state_widget.dart';

/// xRx Favori Yemekler Sayfas1
///
/// NOT: Bu ?zellik Supabase entegrasyonuyla yakında aktif olacak.
/// Şu an placeholder olarak g?steriliyor.
class FavoriYemeklerPage extends StatelessWidget {
  const FavoriYemeklerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favori Yemeklerim'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: const EmptyStateWidget(
        type: EmptyStateType.noFavorites,
        title: 'Yakında Aktif',
        message: 'Favori yemekler ?zellii Supabase entegrasyonuyla birlikte yakında aktif olacak.\n\n'
            'Beendiiniz yemekleri favorilere ekleyerek kolayca eri_ebileceksiniz.',
        actionLabel: null,
        customIcon: Icons.upcoming,
        iconColor: Colors.purple,
      ),
    );
  }
}


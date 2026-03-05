// ============================================================================
// lib/presentation/pages/maintenance_page.dart
// BAKIM VE DEBUG SAYFASI
// ============================================================================

import 'package:flutter/material.dart';
import '../widgets/empty_state_widget.dart';

/// x� Maintenance & Debug Sayfas1
///
/// NOT: Bu sayfa PostgreSQL/Supabase ge�i_i nedeniyle yeniden tasarlanıyor.
/// Veritaban1 y�netimi artık admin panel �zerinden yapılıyor.
class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('x� Maintenance & Debug'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const EmptyStateWidget(
        type: EmptyStateType.noData,
        title: 'Bakım Sayfas1',
        message: 'Veritaban1 bakım ve y�netim i_lemleri artık admin panel �zerinden yapılıyor.\n\n'
            'PostgreSQL/Supabase modunda yerel veritaban1 sıfırlama ve '
            'migration i_lemleri kullanılmıyor.\n\n'
            'Veri y�netimi i�in l�tfen admin panelini kullanın.',
        customIcon: Icons.build_outlined,
        iconColor: Colors.deepPurple,
      ),
    );
  }
}


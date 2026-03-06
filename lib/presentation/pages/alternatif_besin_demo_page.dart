// ============================================================================
// ALTERNAT0F BES0N DEMO SAYFASI - V2 Placeholder
// ============================================================================

import 'package:flutter/material.dart';

/// Alternatif besin demo sayfas1
/// TODO: V2 API'sine g?re g?ncellenecek
class AlternatifBesinDemoPage extends StatelessWidget {
  const AlternatifBesinDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('x? Alternatif Besinler'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Alternatif Besin Sistemi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Bu ?zellik V2 API\'si ile g?ncelleniyor.\nYakında eklenecek.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


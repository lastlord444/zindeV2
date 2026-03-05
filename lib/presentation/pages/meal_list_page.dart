import 'package:flutter/material.dart';

// ============================================================================
// MEAL LIST PAGE (DEPRECATED IN V2)
// ============================================================================

class MealListPage extends StatelessWidget {
  const MealListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğün Listesi (Eski)'),
      ),
      body: const Center(
        child: Text('Bu sayfa V2 mimarisinde kullanılmamaktadır.'),
      ),
    );
  }
}


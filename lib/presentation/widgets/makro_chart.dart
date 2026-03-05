import 'package:flutter/material.dart';

class MakroChart extends StatelessWidget {
  const MakroChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text('Grafik Devre Dışı (Web Fix)', style: TextStyle(color: Colors.grey)),
    );
  }
}

class MiniMakroChart extends StatelessWidget {
  const MiniMakroChart({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}


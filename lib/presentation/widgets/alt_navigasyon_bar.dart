import 'package:flutter/material.dart';

enum NavigasyonSekme {
  profil,
  antrenman,
  beslenme,
  supplement,
}

class AltNavigasyonBar extends StatelessWidget {
  final NavigasyonSekme aktifSekme;
  final Function(NavigasyonSekme) onSekmeSecildi;

  const AltNavigasyonBar({
    super.key,
    required this.aktifSekme,
    required this.onSekmeSecildi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
                sekme: NavigasyonSekme.profil,
              ),
              _buildNavItem(
                icon: Icons.fitness_center_outlined,
                activeIcon: Icons.fitness_center,
                label: 'Antrenman',
                sekme: NavigasyonSekme.antrenman,
              ),
              _buildNavItem(
                icon: Icons.restaurant_menu_outlined,
                activeIcon: Icons.restaurant_menu,
                label: 'Beslenme',
                sekme: NavigasyonSekme.beslenme,
              ),
              _buildNavItem(
                icon: Icons.local_pharmacy_outlined,
                activeIcon: Icons.local_pharmacy,
                label: 'Supplement',
                sekme: NavigasyonSekme.supplement,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required NavigasyonSekme sekme,
  }) {
    final aktif = aktifSekme == sekme;

    return InkWell(
      onTap: () => onSekmeSecildi(sekme),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: aktif ? Colors.purple.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              aktif ? activeIcon : icon,
              color: aktif ? Colors.purple : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: aktif ? FontWeight.w600 : FontWeight.normal,
                color: aktif ? Colors.purple : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


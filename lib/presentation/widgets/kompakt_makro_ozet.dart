import 'package:flutter/material.dart';
import '../../domain/entities/gunluk_plan.dart';
import '../../core/config/nutrition_constraints.dart';
import 'animated_meal_card.dart'; // // Progress Ring Animation

class KompaktMakroOzet extends StatelessWidget {
  final double mevcutKalori;
  final double hedefKalori;
  final double mevcutProtein;
  final double hedefProtein;
  final double mevcutKarb;
  final double hedefKarb;
  final double mevcutYag;
  final double hedefYag;
  final GunlukPlan? plan; //  Tolerans kontrolü iin plan gerekli

  const KompaktMakroOzet({
    super.key,
    required this.mevcutKalori,
    required this.hedefKalori,
    required this.mevcutProtein,
    required this.hedefProtein,
    required this.mevcutKarb,
    required this.hedefKarb,
    required this.mevcutYag,
    required this.hedefYag,
    this.plan, // Optional - tolerans kontrolü iin
    this.onRegenerate, // Plan1 yeniden oluşturmak iin callback
  });

  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // // GENEL TOLERANS UYARISI (Varsa)
        if (plan != null && !plan!.tumMakrolarToleranstaMi)
          _buildToleranceWarningCard(),
        
        if (plan != null && !plan!.tumMakrolarToleranstaMi)
          const SizedBox(height: 12),

        // Ana makro ?zet kart1
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildMakroSatir(
                'Kalori',
                '🔥',
                mevcutKalori,
                hedefKalori,
                'kcal',
                Colors.deepOrange,
                isTolerant: plan?.kaloriToleranstaMi(0.1) ?? NutritionConstraints.isCalorieWithinTolerance(mevcutKalori, hedefKalori),
              ),
              const SizedBox(height: 12),
              _buildMakroSatir(
                'Protein',
                '🥩',
                mevcutProtein,
                hedefProtein,
                'g',
                Colors.redAccent.shade400,
                 isTolerant: plan?.proteinToleranstaMi(0.1) ?? NutritionConstraints.isProteinWithinTolerance(mevcutProtein, hedefProtein),
              ),
              const SizedBox(height: 12),
              _buildMakroSatir(
                'Karbonhidrat',
                '🥖',
                mevcutKarb,
                hedefKarb,
                'g',
                Colors.amber.shade700,
                 isTolerant: plan?.karbToleranstaMi(0.1) ?? NutritionConstraints.isCarbsWithinTolerance(mevcutKarb, hedefKarb),
              ),
              const SizedBox(height: 12),
              _buildMakroSatir(
                'Yağ',
                '🥑',
                mevcutYag,
                hedefYag,
                'g',
                Colors.green.shade700,
                 isTolerant: plan?.yagToleranstaMi(0.1) ?? NutritionConstraints.isFatWithinTolerance(mevcutYag, hedefYag),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// TOLERANS UYARI KARTI
  Widget _buildToleranceWarningCard() {
    if (plan == null || plan!.tumMakrolarToleranstaMi) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⚠️ TOLERANS AŞILDI!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Aıklama
          Text(
            'Günlük planınızda baz1 makrolar ±%${(NutritionConstraints.tolerancePct * 100).toInt()} tolerans sınırın1 aşt1.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // Aşan makroların listesi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tolerans aşan makrolar:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ...plan!.toleransAsanMakrolar.map((makro) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            makro,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Fitness skoru
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Colors.orange, size: 16),
              const SizedBox(width: 6),
              Text(
                'Plan Kalite Skoru: ${plan!.makroKaliteSkoru.toStringAsFixed(1)}/100',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          if (onRegenerate != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Bu G?n? Tekrar Planla (Re-optimize)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade900,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMakroSatir(
    String baslik,
    String emoji,
    double mevcut,
    double hedef,
    String birim,
    Color renk, {
    bool isTolerant = true,
  }) {
    final yuzde = (mevcut / hedef * 100).clamp(0, 100);
    final progress = (yuzde / 100).clamp(0.0, 1.0);
    
    // Tolerans dı_ındaysa rengi dei_tir veya uyar1 g?ster
    final displayColor = isTolerant ? renk : Colors.red;

    return Row(
      children: [
        //  Animated Progress Ring
        Stack(
          children: [
            ProgressRing(
              progress: progress,
              size: 50,
              strokeWidth: 5,
              startColor: displayColor,
              endColor: displayColor.withValues(alpha: 0.6),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            if (!isTolerant)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning, color: Colors.red, size: 12),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        
        // Başlık ve deerler
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    baslik,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isTolerant ? Colors.black : Colors.red.shade900,
                    ),
                  ),
                  if (!isTolerant) ...[
                    const SizedBox(width: 4),
                    const Text(
                      '(Limit Aşıldı)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Progress bar
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: displayColor.withValues(alpha: 0.25),
                        valueColor: AlwaysStoppedAnimation(displayColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Deerler
                  Text(
                    '${mevcut.toStringAsFixed(0)}/${hedef.toStringAsFixed(0)}$birim',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isTolerant ? Colors.black87 : Colors.red.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}


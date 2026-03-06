// ============================================================================
// ANALYTICS SAYFASI - FAZ 10 - D?ZELTILDI
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/analytics/analytics_bloc.dart';
import '../bloc/analytics/analytics_event.dart';
import '../bloc/analytics/analytics_state.dart';
import '../../domain/entities/nutrition/gunluk_plan.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/repositories/meal_plan_repository.dart';
import '../../core/di/injection_container.dart' as di;

class MacroValues {
  final double kalori;
  final double protein;
  final double karbonhidrat;
  final double yag;
  final DateTime tarih;

  MacroValues({
    required this.kalori,
    required this.protein,
    required this.karbonhidrat,
    required this.yag,
    required this.tarih,
  });
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnalyticsBloc(
        analyticsRepo: di.sl<AnalyticsRepository>(),
        planRepo: di.sl<MealPlanRepository>(),
      )..add(const LoadWeeklyAnalytics()),
      child: const AnalyticsPageContent(),
    );
  }
}

class AnalyticsPageContent extends StatelessWidget {
  const AnalyticsPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
          builder: (context, state) {
            if (state is AnalyticsLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Y?kleniyor...',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }

            if (state is AnalyticsError) {
              return _buildErrorState(context, state.mesaj);
            }

            if (state is WeeklyAnalyticsLoaded) {
              return _buildWeeklyAnalyticsContent(context, state);
            }
            
            if (state is MonthlyAnalyticsLoaded) {
              return _buildMonthlyAnalyticsContent(context, state);
            }

            return const Center(
              child: Text(
                '0statistikler hazırlanıyor...',
                style: TextStyle(fontSize: 16),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Hata durumu
  Widget _buildErrorState(BuildContext context, String mesaj) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '0statistik Bulunamad1',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              mesaj,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<AnalyticsBloc>().add(const LoadWeeklyAnalytics());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  /// Haftalık analytics i?erii
  Widget _buildWeeklyAnalyticsContent(BuildContext context, WeeklyAnalyticsLoaded state) {
    return Column(
      children: [
        // ?st bar
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'x` 0statistikler',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Zaman aral11 filtreleri
              Row(
                children: [
                  _buildTimeFilterChip(
                    context,
                    '7 G?n',
                    isSelected: true,
                    onTap: () {
                      context.read<AnalyticsBloc>().add(const LoadWeeklyAnalytics());
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip(
                    context,
                    '30 G?n',
                    isSelected: false,
                    onTap: () {
                      context.read<AnalyticsBloc>().add(const LoadMonthlyAnalytics());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // 0?erik
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ?zet kartlar1
              _buildSummaryCards(state),
              const SizedBox(height: 24),

              // Trend bilgisi
              _buildTrendCard(state.data.hedefAnalizi.gelismeTrendi),
              const SizedBox(height: 24),

              // En iyi/en k?t? g?nler
              _buildBestWorstDays(state.planlar),
              const SizedBox(height: 24),

              // Favori yemekler
              _buildFavoriteMeals(_getEnCokYenilenYemekler(state.planlar)),
            ],
          ),
        ),
      ],
    );
  }

  /// Aylık analytics i?erii
  Widget _buildMonthlyAnalyticsContent(BuildContext context, MonthlyAnalyticsLoaded state) {
    return Column(
      children: [
        // ?st bar
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'x` 0statistikler',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Zaman aral11 filtreleri
              Row(
                children: [
                  _buildTimeFilterChip(
                    context,
                    '7 G?n',
                    isSelected: false,
                    onTap: () {
                      context.read<AnalyticsBloc>().add(const LoadWeeklyAnalytics());
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip(
                    context,
                    '30 G?n',
                    isSelected: true,
                    onTap: () {
                      context.read<AnalyticsBloc>().add(const LoadMonthlyAnalytics());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // 0?erik
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ?zet kartlar1 (aylık)
              _buildMonthlySummaryCards(state),
              const SizedBox(height: 24),

              // Trend bilgisi
              _buildTrendCard('Veri Yeterli Deil'), // Aylık raporda hen?z hedefAnalizi yok
              const SizedBox(height: 24),

              // En iyi/en k?t? g?nler
              _buildBestWorstDays(state.planlar),
              const SizedBox(height: 24),

              // Favori yemekler
              _buildFavoriteMeals({}), // V2'de enCokYenilenYemekler Hen?z implementasyon yok
            ],
          ),
        ),
      ],
    );
  }

  /// Zaman filtresi chip
  Widget _buildTimeFilterChip(
    BuildContext context,
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Haftalık ?zet kartlar1
  Widget _buildSummaryCards(WeeklyAnalyticsLoaded state) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Ortalama Kalori',
            '${state.ortalamaKalori.toStringAsFixed(0)} kcal',
            Colors.orange,
            Icons.local_fire_department,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Ortalama Protein',
            '${state.ortalamaProtein.toStringAsFixed(0)} g',
            Colors.red,
            Icons.fitness_center,
          ),
        ),
      ],
    );
  }

  /// Aylık ?zet kartlar1
  Widget _buildMonthlySummaryCards(MonthlyAnalyticsLoaded state) {
    final gunlukMakrolar = _getGunlukMakrolar(state.planlar);
    final ortalama = _hesaplaOrtalamaMakrolar(gunlukMakrolar);
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Ortalama Kalori',
            '${ortalama.kalori.toStringAsFixed(0)} kcal',
            Colors.orange,
            Icons.local_fire_department,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Ortalama Protein',
            '${ortalama.protein.toStringAsFixed(0)} g',
            Colors.red,
            Icons.fitness_center,
          ),
        ),
      ],
    );
  }

  /// ?zet kart1
  Widget _buildSummaryCard(
    String baslik,
    String deger,
    Color renk,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: renk, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            baslik,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            deger,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }

  /// Trend kart1
  Widget _buildTrendCard(String trendMetni) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'x? 0lerleme Trendi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            trendMetni,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// En iyi/en k?t? g?nler
  Widget _buildBestWorstDays(List<GunlukPlan> planlar) {
    if (planlar.length < 2) {
      return const SizedBox.shrink();
    }

    // En y?ksek ve en d?_?k kalori g?nlerini bul
    final sortedPlanlar = List<GunlukPlan>.from(planlar)
      ..sort((a, b) => a.toplamKalori.compareTo(b.toplamKalori));
    
    final enDusukPlan = sortedPlanlar.first;
    final enYuksekPlan = sortedPlanlar.last;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'x?  En 0yi/En K?t? G?nler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // En y?ksek kalori
          _buildDayRow(
            '=% En Y?ksek Kalori',
            enYuksekPlan,
            Colors.orange,
          ),
          const SizedBox(height: 12),

          // En d?_?k kalori
          _buildDayRow(
            'xR? En D?_?k Kalori',
            enDusukPlan,
            Colors.green,
          ),
        ],
      ),
    );
  }

  /// G?n satır1
  Widget _buildDayRow(String baslik, GunlukPlan plan, Color renk) {
    final tarih = plan.tarih;
    final kalori = plan.toplamKalori;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              baslik,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTarih(tarih),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: renk.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${kalori.toStringAsFixed(0)} kcal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
        ),
      ],
    );
  }

  /// Favori yemekler
  Widget _buildFavoriteMeals(Map<String, int> yemekSayilari) {
    if (yemekSayilari.isEmpty) return const SizedBox.shrink();

    final sortedYemekler = yemekSayilari.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topYemekler = sortedYemekler.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '❤️ En Sevilen Yemekler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...topYemekler.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${entry.value}x',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Map<DateTime, MacroValues> _getGunlukMakrolar(List<GunlukPlan> planlar) {
    return {
      for (var plan in planlar)
        plan.tarih: MacroValues(
          kalori: plan.toplamKalori,
          protein: plan.toplamProtein,
          karbonhidrat: plan.toplamKarbonhidrat,
          yag: plan.toplamYag,
          tarih: plan.tarih,
        )
    };
  }

  Map<String, int> _getEnCokYenilenYemekler(List<GunlukPlan> planlar) {
    final yemekSayilari = <String, int>{};
    for (var plan in planlar) {
      for (var yemek in plan.ogunler) {
        final key = yemek.ad;
        yemekSayilari[key] = (yemekSayilari[key] ?? 0) + 1;
      }
    }
    return yemekSayilari;
  }

  /// Ortalama makrolar1 hesapla
  MacroValues _hesaplaOrtalamaMakrolar(Map<DateTime, MacroValues> gunlukMakrolar) {
    if (gunlukMakrolar.isEmpty) {
      return MacroValues(
        kalori: 0,
        protein: 0,
        karbonhidrat: 0,
        yag: 0,
        tarih: DateTime.now(),
      );
    }

    final toplamKalori = gunlukMakrolar.values.fold<double>(0, (sum, makro) => sum + makro.kalori);
    final toplamProtein = gunlukMakrolar.values.fold<double>(0, (sum, makro) => sum + makro.protein);
    final toplamKarb = gunlukMakrolar.values.fold<double>(0, (sum, makro) => sum + makro.karbonhidrat);
    final toplamYag = gunlukMakrolar.values.fold<double>(0, (sum, makro) => sum + makro.yag);

    return MacroValues(
      kalori: toplamKalori / gunlukMakrolar.length,
      protein: toplamProtein / gunlukMakrolar.length,
      karbonhidrat: toplamKarb / gunlukMakrolar.length,
      yag: toplamYag / gunlukMakrolar.length,
      tarih: DateTime.now(),
    );
  }

  /// Tarih formatlama
  String _formatTarih(DateTime tarih) {
    final aylar = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Austos',
      'Eyl?l',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return '${tarih.day} ${aylar[tarih.month - 1]} ${tarih.year}';
  }
}

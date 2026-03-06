// ============================================================================
// ANTRENMAN SAYFASI - FAZ 9
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/workout/antrenman_plani.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../bloc/workout/workout_bloc.dart';
import '../bloc/workout/workout_state.dart';
import '../bloc/workout/workout_event.dart';

class AntrenmanPage extends StatelessWidget {
  const AntrenmanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WorkoutBloc(
        workoutRepo: WorkoutRepositoryImpl(),
      )..add(const LoadAntrenmanProgramlari()),
      child: const AntrenmanPageContent(),
    );
  }
}

class AntrenmanPageContent extends StatelessWidget {
  const AntrenmanPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: BlocBuilder<WorkoutBloc, WorkoutState>(
          builder: (context, state) {
            if (state is AntrenmanLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AntrenmanError) {
              return _buildErrorState(context, state.mesaj);
            }

            if (state is AntrenmanActive) {
              return _buildActiveAntrenman(context, state);
            }

            if (state is AntrenmanProgramlariLoaded) {
              return _buildProgramList(context, state);
            }

            if (state is AntrenmanGecmisiLoaded) {
              return _buildGecmis(context, state);
            }

            return const Center(child: Text('Antrenman programlar1 y?kleniyor...'));
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
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Bir hata oluştu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              mesaj,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<WorkoutBloc>().add(const LoadAntrenmanProgramlari());
            },
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  /// Program listesi
  Widget _buildProgramList(BuildContext context, AntrenmanProgramlariLoaded state) {
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
              Row(
                children: [
                  const Text(
                    'x?9️ Antrenman Programlar1',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () {
                      context.read<WorkoutBloc>().add(const LoadAntrenmanGecmisi());
                    },
                    tooltip: 'Ge?mi_',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Zorluk filtreleri
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      context,
                      'T?m?',
                      isSelected: state.filtreZorluk == null || state.filtreZorluk!.isEmpty,
                      onTap: () {
                        context.read<WorkoutBloc>().add(const LoadAntrenmanProgramlari());
                      },
                    ),
                    ...['Kolay', 'Orta', 'Zor'].map((zorluk) {
                      return _buildFilterChip(
                        context,
                        zorluk,
                        isSelected: state.filtreZorluk?.toLowerCase() == zorluk.toLowerCase(),
                        onTap: () {
                          context.read<WorkoutBloc>().add(FilterByZorluk(zorluk.toLowerCase()));
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Program kartlar1
        Expanded(
          child: state.programlar.isEmpty
              ? const Center(
                  child: Text('Hen?z antrenman program1 yok'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.programlar.length,
                  itemBuilder: (context, index) {
                    final program = state.programlar[index];
                    return _buildProgramCard(context, program);
                  },
                ),
        ),
      ],
    );
  }

  /// Filtre chip
  Widget _buildFilterChip(
    BuildContext context,
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.purple : Colors.transparent,
              style: isSelected ? BorderStyle.solid : BorderStyle.none,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.purple.shade900 : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// Program kart1
  Widget _buildProgramCard(BuildContext context, AntrenmanProgrami program) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showProgramDetay(context, program);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        program.kasGruplariOzet,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.ad,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            program.aciklama,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoBadge(
                      '⭐',
                      program.zorluk,
                      Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoBadge(
                      '⏱️',
                      '${program.toplamSureDakika} dk',
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoBadge(
                      '🔥',
                      '${program.toplamKalori} kcal',
                      Colors.red,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoBadge(
                      '=?',
                      '${program.egzersizSayisi} egzersiz',
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Info badge
  Widget _buildInfoBadge(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Program detay bottom sheet
  void _showProgramDetay(BuildContext context, AntrenmanProgrami program) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Ba_lık
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.ad,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    program.aciklama,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    program.ozet,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Egzersiz listesi
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: program.egzersizler.length,
                itemBuilder: (context, index) {
                  final egzersiz = program.egzersizler[index];
                  return _buildEgzersizCard(egzersiz, index + 1);
                },
              ),
            ),

            // Ba_lat butonu
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.read<WorkoutBloc>().add(StartAntrenman(program));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Antrenman1 Ba_lat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Egzersiz kart1
  Widget _buildEgzersizCard(Hareket hareket, int sira) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$sira',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hareket.hareket,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hareket.ipucu,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${hareket.set} set x ${hareket.tekrar} tekrar',
            style: TextStyle(
              fontSize: 13,
              color: Colors.purple.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Aktif antrenman ekran1
  Widget _buildActiveAntrenman(BuildContext context, AntrenmanActive state) {
    final program = state.aktifProgram;
    final illemeYuzdesi = program.egzersizSayisi > 0 ? (state.tamamlananEgzersizler.length / program.egzersizSayisi) * 100 : 0.0;
    final kalanEgzersiz = program.egzersizSayisi - state.tamamlananEgzersizler.length;

    return Column(
      children: [
        // ?st bilgi
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade600, Colors.purple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Text(
                program.ad,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    '0lerleme',
                    '${illemeYuzdesi.toStringAsFixed(0)}%',
                  ),
                  _buildStatColumn(
                    'Tamamlanan',
                    '${state.tamamlananEgzersizler.length}/${program.egzersizSayisi}',
                  ),
                  _buildStatColumn(
                    'Kalan',
                    '$kalanEgzersiz egzersiz',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: illemeYuzdesi / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                minHeight: 8,
              ),
            ],
          ),
        ),

        // Egzersiz listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: program.egzersizler.length,
            itemBuilder: (context, index) {
              final hareket = program.egzersizler[index];
              final tamamlandi = state.tamamlananEgzersizler.contains(hareket.hareket);

              return _buildActiveEgzersizCard(
                context,
                hareket,
                index + 1,
                tamamlandi,
              );
            },
          ),
        ),

        // Alt butonlar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: state.tamamlananEgzersizler.length == state.aktifProgram.egzersizSayisi
                ? () {
                    _showTamamlaDialog(context, state);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              state.tamamlananEgzersizler.length == state.aktifProgram.egzersizSayisi
                  ? ' Antrenman1 Tamamla'
                  : '⏳ Egzersizleri Tamamlayın',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Stat s?tunu
  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Aktif egzersiz kart1
  Widget _buildActiveEgzersizCard(
    BuildContext context,
    Hareket hareket,
    int sira,
    bool tamamlandi,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tamamlandi ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tamamlandi ? Colors.green.shade300 : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tamamlandi ? Colors.green : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: tamamlandi
                    ? const Icon(Icons.check, color: Colors.white)
                    : Text(
                        '$sira',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hareket.hareket,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: tamamlandi ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${hareket.set} set x ${hareket.tekrar} tekrar',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Dinlenme: ${hareket.dinlenme}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (!tamamlandi)
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                color: Colors.purple,
                onPressed: () {
                  context
                      .read<WorkoutBloc>()
                      .add(CompleteEgzersiz(hareket.hareket));
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Tamamla dialog
  void _showTamamlaDialog(BuildContext context, AntrenmanActive state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('x?0 Tebrikler!'),
        content: const Text(
          'Antrenman1 tamamladınız! Ger?ekle_tirdiiniz performans1 kaydetmek ister misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('0ptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<WorkoutBloc>().add(
                    CompleteAntrenman(
                      programId: state.aktifProgram.planAdi, 
                      programAdi: state.aktifProgram.ad,
                      sureDakika: state.aktifProgram.toplamSureDakika,
                    ),
                  );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  /// Ge?mi_ ekran1
  Widget _buildGecmis(BuildContext context, AntrenmanGecmisiLoaded state) {
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
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.read<WorkoutBloc>().add(const LoadAntrenmanProgramlari());
                },
              ),
              const Text(
                'Antrenman Ge?mi_i',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // 0statistikler
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade600, Colors.purple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                'Son 7 G?n',
                '${state.son7GunAntrenmanSayisi} antrenman',
              ),
              _buildStatColumn(
                'Yakılan Kalori',
                '${state.toplamKalori} kcal',
              ),
            ],
          ),
        ),

        // Ge?mi_ listesi
        Expanded(
          child: state.gecmis.isEmpty
              ? const Center(child: Text('Hen?z antrenman ge?mi_i yok'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.gecmis.length,
                  itemBuilder: (context, index) {
                    final antrenman = state.gecmis[index];
                    return _buildGecmisCard(antrenman);
                  },
                ),
        ),
      ],
    );
  }

  /// Ge?mi_ kart1
  Widget _buildGecmisCard(TamamlananAntrenman antrenman) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.check_circle, color: Colors.green.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      antrenman['programAdi']?.toString() ?? 'Antrenman',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTarih(
                        DateTime.tryParse(antrenman['tarih']?.toString() ?? '') ?? DateTime.now()
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoBadge(
                '⏱️',
                '${antrenman['sure_dakika'] ?? 45} dk',
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildInfoBadge(
                '🔥',
                '${((antrenman['sure_dakika'] as int? ?? 45) * 6)} kcal',
                Colors.red,
              ),
              const SizedBox(width: 8),
              _buildInfoBadge(
                '=?',
                '${antrenman['tamamlanan_egzersizler'] == null ? 0 : (antrenman['tamamlanan_egzersizler'] as List).length} egzersiz',
                Colors.green,
              ),
            ],
          ),
        ],
      ),
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


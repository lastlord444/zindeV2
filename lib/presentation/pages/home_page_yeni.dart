import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// KR0T0K: Logger import'u eklendi.
// �R yemek_hive_data_source kaldırıld1 - MealRepositoryV2 kullan
// import '../../domain/services/ai_beslenme_servisi.dart'; // > AI SERV0S0 (REMOVED)
import '../../domain/services/malzeme_parser_servisi.dart'; // PARSE SERV0S0
import '../bloc/home/home_bloc.dart';
import '../bloc/home/home_event.dart';
import '../bloc/home/home_state.dart';
import '../../core/di/injection_container.dart';
import '../../domain/entities/yemek_onay_sistemi.dart';
import '../widgets/tarih_secici.dart';
import '../widgets/haftalik_takvim.dart';
import '../widgets/kompakt_makro_ozet.dart';
import '../widgets/detayli_ogun_card.dart';
import '../widgets/alt_navigasyon_bar.dart';
import '../widgets/alternatif_yemek_bottom_sheet.dart';
import '../widgets/alternatif_besin_bottom_sheet.dart';
// x�� Shimmer loading
import '../widgets/animated_meal_card.dart'; // x�� Animations
import '../widgets/empty_state_widget.dart'; // x�� Empty states
import 'profil_page.dart';
import 'antrenman_page.dart';
import 'maintenance_page.dart';
import 'ai_chatbot_page.dart';
import 'haftalik_rapor_page.dart';
import 'alisveris_listesi_page.dart';

class YeniHomePage extends StatelessWidget {
  const YeniHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        // Web g�venlii: AppLogger.init() �arıs1 kaldırıld1
        // main.dart'ta zaten initialize ediliyor, burada tekrar �aırmaya gerek yok
        
        return sl<HomeBloc>()..add(const LoadHomePage()); //  F5 yapınca mevcut plan1 otomatik y�kle
      },
      child: const YeniHomePageView(),
    );
  }
}

class YeniHomePageView extends StatefulWidget {
  const YeniHomePageView({super.key});

  @override
  State<YeniHomePageView> createState() => _YeniHomePageViewState();
}

class _YeniHomePageViewState extends State<YeniHomePageView>
    with TickerProviderStateMixin {
  NavigasyonSekme _aktifSekme = NavigasyonSekme.beslenme;
  bool _isFABExtended = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        // Android geri tu_u i�in �ıkı_ onay1
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Uygulamadan �ık'),
            content:
                const Text('Uygulamadan �ıkmak istediinize emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hayır'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Evet, �ık'),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('ZindeAI'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MaintenancePage(),
                  ),
                );
              },
              tooltip: 'Maintenance & Debug',
            ),
          ],
        ),
        body: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {
            // Alternatif yemekler y�klendiinde bottom sheet a�
            if (state is AlternativeMealsLoaded) {
              AlternatifYemekBottomSheet.goster(
                context,
                mevcutYemek: state.mevcutYemek,
                alternatifYemekler: state.alternatifYemekler ?? [],
                onYemekSecildi: (yeniYemek) {
                      context.read<HomeBloc>().add(
                            ReplaceMealWith(
                              state.mevcutYemek, // positional arg�man
                              yeniYemek, // positional arg�man
                            ),
                          );
                    },
                    onClose: () {
                      context
                          .read<HomeBloc>()
                          .add(const CancelAlternativeMealSelection());
                    },
              );
            }

            // Alternatif malzemeler y�klendiinde bottom sheet a�
            if (state is AlternativeIngredientsLoaded) {
              // FIX: Malzemeyi parse et - miktar ve birim bilgilerini al
              final parsedList = MalzemeParserServisi.parse(state.orijinalMalzemeMetni);
              final parsedMalzeme = parsedList.isNotEmpty ? parsedList.first : null;
              
              AlternatifBesinBottomSheet.goster(
                context,
                orijinalBesinAdi: parsedMalzeme?['besin_adi'] ?? state.orijinalMalzemeMetni,
                orijinalMiktar: (parsedMalzeme?['miktar'] as num?)?.toDouble() ?? 0.0,
                orijinalBirim: parsedMalzeme?['birim'] ?? '',
                alternatifler: state.alternatifBesinler,
                alerjiNedeni: 'Malzeme dei_iklii',
                onClose: () {
                  // FIX: X butonu ile kapatıldıında ana sayfaya geri d�n (hi�bir _ey sıfırlanmasın)
                  context
                      .read<HomeBloc>()
                      .add(const CancelAlternativeSelection());
                },
              ).then((secilenAlternatif) {
                if (secilenAlternatif != null && state.yemek != null) {
                  // Yeni malzeme metnini oluştur
                  final yeniMalzemeMetni =
                      '${secilenAlternatif.miktar.toStringAsFixed(0)} ${secilenAlternatif.birim} ${secilenAlternatif.ad}';

                  if (!context.mounted) return;
                  context.read<HomeBloc>().add(
                        ReplaceIngredientWith(
                          yemek: state.yemek!,
                          malzemeIndex: state.malzemeIndex,
                          yeniMalzemeMetni: yeniMalzemeMetni,
                        ),
                      );
                } else {
                  // FIX: Bottom sheet dı_ar1 tıklama/geri tu_u ile kapatıldıysa da ana sayfaya d�n
                  if (!context.mounted) return;
                  context
                      .read<HomeBloc>()
                      .add(const CancelAlternativeSelection());
                }
              });
            }
          },
          builder: (context, state) {
            // Profil sekmesi se�iliyse ProfilPage'i g�ster
            if (_aktifSekme == NavigasyonSekme.profil) {
              return Column(
                children: [
                  Expanded(
                    child: ProfilPage(
                      //  Profil kaydedilince sekmeyi dei_tir ve plan1 oluştur
                      onProfilKaydedildi: () {
                        setState(() {
                          _aktifSekme = NavigasyonSekme.beslenme;
                        });
                        // YEN0 KULLANICI 0�0N: Plan oluşturmay1 ba_lat
                        context.read<HomeBloc>().add(const LoadHomePage());
                      },
                    ),
                  ),
                  AltNavigasyonBar(
                    aktifSekme: _aktifSekme,
                    onSekmeSecildi: (sekme) {
                      setState(() {
                        _aktifSekme = sekme;
                      });
                    },
                  ),
                ],
              );
            }

            // Antrenman sekmesi - ENTEGRE ED0LD0! =�
            if (_aktifSekme == NavigasyonSekme.antrenman) {
              return Column(
                children: [
                  const Expanded(child: AntrenmanPage()),
                  AltNavigasyonBar(
                    aktifSekme: _aktifSekme,
                    onSekmeSecildi: (sekme) {
                      setState(() {
                        _aktifSekme = sekme;
                      });
                    },
                  ),
                ],
              );
            }

            // Supplement sekmesi - AI Chatbot >
            if (_aktifSekme == NavigasyonSekme.supplement) {
              return Column(
                children: [
                  const Expanded(child: AIChatbotPage()),
                  AltNavigasyonBar(
                    aktifSekme: _aktifSekme,
                    onSekmeSecildi: (sekme) {
                      setState(() {
                        _aktifSekme = sekme;
                      });
                    },
                  ),
                ],
              );
            }

            // Beslenme sekmesi (varsayılan)
            // AlternativeIngredientsLoaded da HomeLoaded gibi render edilmeli
            if (state is AlternativeIngredientsLoaded) {
              return Column(
                children: [
                  // Ana i�erik
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        // CRITICAL FIX: AlternativeIngredientsLoaded i�in de RefreshDailyPlan kullan
                        context
                            .read<HomeBloc>()
                            .add(const RefreshDailyPlan(forceRegenerate: false));
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Tarih se�ici (ok butonlar1 ile)
                          TarihSecici(
                            secilenTarih: state.currentDate,
                            onGeriGit: () {
                              final yeniTarih = state.currentDate
                                  .subtract(const Duration(days: 1));
                              context
                                  .read<HomeBloc>()
                                  .add(LoadPlanByDate(yeniTarih));
                            },
                            onIleriGit: () {
                              final yeniTarih = state.currentDate
                                  .add(const Duration(days: 1));
                              context
                                  .read<HomeBloc>()
                                  .add(LoadPlanByDate(yeniTarih));
                            },
                          ),

                          const SizedBox(height: 16),

                          // Haftalık takvim
                          HaftalikTakvim(
                            secilenTarih: state.currentDate,
                            onTarihSecildi: (tarih) {
                              context
                                  .read<HomeBloc>()
                                  .add(LoadPlanByDate(tarih));
                            },
                          ),

                          const SizedBox(height: 16),

                          // x: HAFTAL0K RAPOR VE ALIŞVER0Ş (TAKV0MDEN HEMEN SONRA)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HaftalikRaporPage(
                                          baslangicTarihi: state.currentDate,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.analytics_outlined, size: 20),
                                  label: const Text('Haftalik Rapor'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AlisverisListesiPage(
                                          baslangicTarihi: state.currentDate,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                                  label: const Text('Alışveriş Listesi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Kompakt makro �zeti
                          KompaktMakroOzet(
                            mevcutKalori: _calculateTamamlananKalori(
                                state.plan, state.tamamlananOgunler),
                            hedefKalori: state.hedefler.gunlukKalori,
                            mevcutProtein: _calculateTamamlananProtein(
                                state.plan, state.tamamlananOgunler),
                            hedefProtein: state.hedefler.gunlukProtein,
                            mevcutKarb: _calculateTamamlananKarb(
                                state.plan, state.tamamlananOgunler),
                            hedefKarb: state.hedefler.gunlukKarbonhidrat,
                            mevcutYag: _calculateTamamlananYag(
                                state.plan, state.tamamlananOgunler),
                            hedefYag: state.hedefler.gunlukYag,
                            plan: state.plan, // x�� Tolerans kontrol� i�in
                          ),

                          const SizedBox(height: 24),

                          // Günlük Öğünler
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Günlük Öğünler',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) => AlertDialog(
                                          title: const Text(
                                              '7 Günlük Plan Oluştur'),
                                          content: const Text(
                                            'Pazartesi\'den Pazar\'a kadar 7 günlük besin plan1 oluşturulsun mu? '
                                            'Her gün 5 öğün (Kahvalt1, Ara Öğün 1, Öğle, Ara Öğün 2, Akşam) ierecek.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(dialogContext),
                                              child: const Text('İptal'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(dialogContext);
                                                context.read<HomeBloc>().add(
                                                      const GenerateWeeklyPlan(
                                                          forceRegenerate:
                                                              true),
                                                    );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Oluştur'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.calendar_month,
                                        size: 18),
                                    label: const Text('7 Gün'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: () {
                                      context.read<HomeBloc>().add(
                                          const RefreshDailyPlan(
                                              forceRegenerate: true));
                                    },
                                    tooltip: 'Bugn Yenile',
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Detayl1 n kartlar1 -  YEN0 ONAY S0STEM0
                          ...state.plan.ogunler.map((yemek) {
                            
                            final onayliMi = state.gunlukOnayDurumu[yemek.id.toString()];
                            final yemekDurumu = onayliMi == true 
                                ? YemekDurumu.yedi 
                                : YemekDurumu.bekliyor;
                            return DetayliOgunCard(
                              yemek: yemek,
                              yemekDurumu: yemekDurumu,
                              onYedimPressed: () {
                                // Onay dialog'u gster
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Yemek Onay1'),
                                      content: Text(
                                          '${yemek.ad} yemeini yediinizi onaylıyor musunuz?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('İptal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            context.read<HomeBloc>().add(
                                                MarkMealAsEaten(yemek.id.toString()));
                                          },
                                          child: const Text('Evet, Yedim'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              onSifirlaPressed: () {
                                context
                                    .read<HomeBloc>()
                                    .add(ResetMealStatus(yemek.id.toString()));
                              },
                              onAlternatifPressed: () {
                                // Alternatif yemekler oluştur
                                context.read<HomeBloc>().add(
                                      GenerateAlternativeMeals(yemek),
                                    );
                              },
                              onMalzemeAlternatifiPressed:
                                  (yemek, malzemeMetni, malzemeIndex) {
                                // Malzeme iin alternatif besi nler oluştur
                                context.read<HomeBloc>().add(
                                      GenerateIngredientAlternatives(
                                        yemek: yemek,
                                        malzemeMetni: malzemeMetni,
                                        malzemeIndex: malzemeIndex,
                                      ),
                                    );
                              },
                            );
                          }),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),

                  // Alt navigasyon bar1
                  AltNavigasyonBar(
                    aktifSekme: _aktifSekme,
                    onSekmeSecildi: (sekme) {
                      setState(() {
                        _aktifSekme = sekme;
                      });
                    },
                  ),
                ],
              );
            }

            if (state is HomeLoading) {
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // = Yuvarlak loading indicator veya progress bar
                          ...[
                          // = Progress bar (haftalık plan iin)
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    value: state.progress,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                                  ),
                                ),
                                Text(
                                  '%${(state.progress * 100).toInt()}',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                          const SizedBox(height: 32),
                          // x Loading mesaj1
                          ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              state.message,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${(state.progress * 100).toInt()}% tamamland1',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        ],
                      ),
                    ),
                  ),
                  AltNavigasyonBar(
                    aktifSekme: _aktifSekme,
                    onSekmeSecildi: (sekme) {
                      setState(() {
                        _aktifSekme = sekme;
                      });
                    },
                  ),
                ],
              );
            }

            if (state is HomeError) {
              // x Professional empty state
              return Column(
                children: [
                  Expanded(
                    child: EmptyStateWidget(
                      type: EmptyStateType.error,
                      message: state.message,
                      onActionPressed: () {
                        context.read<HomeBloc>().add(const LoadHomePage());
                      },
                    ),
                  ),
                  AltNavigasyonBar(
                    aktifSekme: _aktifSekme,
                    onSekmeSecildi: (sekme) {
                      setState(() {
                        _aktifSekme = sekme;
                      });
                    },
                  ),
                ],
              );
            }

            if (state is HomeLoaded) {
              return Column(
                children: [
                  // Ana ierik
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        // FAB extend/collapse on scroll
                        if (scrollInfo is ScrollUpdateNotification) {
                          setState(() {
                            _isFABExtended = scrollInfo.metrics.pixels < 100;
                          });
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        onRefresh: () async {
                          // CRITICAL FIX: Doru event'i tetikle - RefreshDailyPlan deil LoadPlanByDate
                          context
                              .read<HomeBloc>()
                              .add(const RefreshDailyPlan(forceRegenerate: false));
                        },
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Tarih seici (ok butonlar1 ile)
                            TarihSecici(
                              secilenTarih: state.currentDate,
                              onGeriGit: () {
                                final yeniTarih = state.currentDate
                                    .subtract(const Duration(days: 1));
                                context
                                    .read<HomeBloc>()
                                    .add(LoadPlanByDate(yeniTarih));
                              },
                              onIleriGit: () {
                                final yeniTarih = state.currentDate
                                    .add(const Duration(days: 1));
                                context
                                    .read<HomeBloc>()
                                    .add(LoadPlanByDate(yeniTarih));
                              },
                            ),

                            const SizedBox(height: 16),

                            // Haftalık takvim
                            HaftalikTakvim(
                              secilenTarih: state.currentDate,
                              onTarihSecildi: (tarih) {
                                context
                                    .read<HomeBloc>()
                                    .add(LoadPlanByDate(tarih));
                              },
                            ),

                            const SizedBox(height: 16),

                            // x: HAFTAL0K RAPOR VE ALIŞVER0Ş L0STES0 (TAKV0MDEN HEMEN SONRA)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              HaftalikRaporPage(
                                            baslangicTarihi: state.currentDate,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.analytics_outlined,
                                        size: 20),
                                    label: const Text('Haftalik Rapor'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AlisverisListesiPage(
                                            baslangicTarihi: state.currentDate,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 20),
                                    label: const Text('Alışveriş Listesi'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Kompakt makro zeti
                            KompaktMakroOzet(
                              mevcutKalori: state.plan.toplamKalori,
                              hedefKalori: state.hedefler.gunlukKalori,
                              mevcutProtein: state.plan.toplamProtein,
                              hedefProtein: state.hedefler.gunlukProtein,
                              mevcutKarb: state.plan.toplamKarbonhidrat,
                              hedefKarb: state.hedefler.gunlukKarbonhidrat,
                              mevcutYag: state.plan.toplamYag,
                              hedefYag: state.hedefler.gunlukYag,
                              plan: state.plan, // x Tolerans kontrol iin
                              onRegenerate: () {
                                context.read<HomeBloc>().add(
                                      const RefreshDailyPlan(forceRegenerate: true),
                                    );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Günlük Öğünler
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Günlük Öğünler',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) =>
                                              AlertDialog(
                                            title: const Text(
                                                '7 Günlük Plan Oluştur'),
                                            content: const Text(
                                              'Pazartesi\'den Pazar\'a kadar 7 günlük besin plan1 oluşturulsun mu? '
                                              'Her gün 5 öğün (Kahvalt1, Ara Öğün 1, Öğle, Ara Öğün 2, Akşam) ierecek.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    dialogContext),
                                                child: const Text('İptal'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(dialogContext);
                                                  context.read<HomeBloc>().add(
                                                        const GenerateWeeklyPlan(
                                                            forceRegenerate:
                                                                true),
                                                      );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text('Oluştur'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.calendar_month,
                                          size: 18),
                                      label: const Text('7 Gün'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.refresh),
                                      onPressed: () {
                                        context.read<HomeBloc>().add(
                                            const RefreshDailyPlan(
                                                forceRegenerate: true));
                                      },
                                      tooltip: 'Bug�n� Yenile',
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Detayl1 ��n kartlar1 - x�� Animated
                            ...state.plan.ogunler.asMap().entries.map((entry) {
                              final index = entry.key;
                              final yemek = entry.value;
                              
                              final onayliMi = state.gunlukOnayDurumu[yemek.id.toString()];
                              final yemekDurumu = onayliMi == true 
                                  ? YemekDurumu.yedi 
                                  : YemekDurumu.bekliyor;
                              return AnimatedMealCard(
                                index: index,
                                child: DetayliOgunCard(
                                  yemek: yemek,
                                  yemekDurumu: yemekDurumu,
                                  onYedimPressed: () {
                                    //  YEN0 S0STEM: Onay dialog'u g�ster
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext dialogContext) {
                                        return AlertDialog(
                                          title: const Text('Yemek Onay1'),
                                          content: Text(
                                              '${yemek.ad} yemeini yediinizi onaylıyor musunuz?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(dialogContext).pop();
                                              },
                                              child: const Text('İptal'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(dialogContext).pop();
                                                context.read<HomeBloc>().add(
                                                    MarkMealAsEaten(yemek.id.toString()));
                                              },
                                              child: const Text('Evet, Yedim'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  onYemedimPressed: () {
                                    //  YEN0 S0STEM: Yemedim dialog'u g�ster
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext dialogContext) {
                                        return AlertDialog(
                                          title: const Text('Yemek Atlama'),
                                          content: Text(
                                              '${yemek.ad} yemeini yemedim olarak i_aretlemek istiyor musunuz?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(dialogContext).pop();
                                              },
                                              child: const Text('İptal'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(dialogContext).pop();
                                                context.read<HomeBloc>().add(
                                                    SkipMeal(yemek.id.toString()));
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                              ),
                                              child: const Text('Evet, Yemedim'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  onOnayPressed: () {
                                    //  YEN0 S0STEM: Onayla ve kilitle
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext dialogContext) {
                                        return AlertDialog(
                                          title: const Text('= Yemek Onaylama'),
                                          content: Text(
                                              '${yemek.ad} yemeini onaylıyor musunuz?\n\nOnaylandıktan sonra dei_tirilemez ve rapor i�in kaydedilir.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(dialogContext).pop();
                                              },
                                              child: const Text('İptal'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(dialogContext).pop();
                                                context.read<HomeBloc>().add(
                                                    ConfirmMealEaten(yemek.id.toString()));
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                              ),
                                              child: const Text('Onayla & Kilitle'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  onSifirlaPressed: () {
                                    //  YEN0 S0STEM: Sıfırla
                                    context.read<HomeBloc>().add(
                                        ResetMealStatus(yemek.id.toString()));
                                  },
                                  onAlternatifPressed: () {
                                    // Alternatif yemekler oluştur
                                    context.read<HomeBloc>().add(
                                          GenerateAlternativeMeals(
                                            yemek,
                                            sayi: 3,
                                          ),
                                        );
                                  },
                                  onMalzemeAlternatifiPressed:
                                      (yemek, malzemeMetni, malzemeIndex) {
                                    // Malzeme i�in alternatif besi nler oluştur
                                    context.read<HomeBloc>().add(
                                          GenerateIngredientAlternatives(
                                            yemek: yemek,
                                            malzemeMetni: malzemeMetni,
                                            malzemeIndex: malzemeIndex,
                                          ),
                                        );
                                  },
                                ),
                              );
                            }),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Alt navigasyon bar1
                  AltNavigasyonBar(
                    aktifSekme: _aktifSekme,
                    onSekmeSecildi: (sekme) {
                      setState(() {
                        _aktifSekme = sekme;
                      });
                    },
                  ),
                ],
              );
            }

            // x�� BAŞLANG0� DURUMU: Professional empty state
            return Column(
              children: [
                Expanded(
                  child: EmptyStateWidget(
                    type: EmptyStateType.noPlan,
                    onActionPressed: () {
                      context.read<HomeBloc>().add(const LoadHomePage());
                    },
                  ),
                ),
                AltNavigasyonBar(
                  aktifSekme: _aktifSekme,
                  onSekmeSecildi: (sekme) {
                    setState(() {
                      _aktifSekme = sekme;
                    });
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper metodlar - tamamlanan makro hesaplamalar1
  double _calculateTamamlananKalori(
      dynamic plan, Map<String, bool> tamamlananogunler) {
    return plan.ogunler
        .where((y) => tamamlananogunler[y.id] == true)
        .fold(0.0, (sum, y) => sum + y.kalori);
  }

  double _calculateTamamlananProtein(
      dynamic plan, Map<String, bool> tamamlananogunler) {
    return plan.ogunler
        .where((y) => tamamlananogunler[y.id] == true)
        .fold(0.0, (sum, y) => sum + y.protein);
  }

  double _calculateTamamlananKarb(
      dynamic plan, Map<String, bool> tamamlananogunler) {
    return plan.ogunler
        .where((y) => tamamlananogunler[y.id] == true)
        .fold(0.0, (sum, y) => sum + y.karbonhidrat);
  }

  double _calculateTamamlananYag(
      dynamic plan, Map<String, bool> tamamlananogunler) {
    return plan.ogunler
        .where((y) => tamamlananogunler[y.id] == true)
        .fold(0.0, (sum, y) => sum + y.yag);
  }
}


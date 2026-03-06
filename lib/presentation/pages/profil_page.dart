import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart' as di;
import '../../domain/services/meal_plan_service.dart';
import '../../domain/entities/nutrition/makro_hedefleri.dart';
import '../../domain/entities/user/hedef.dart';
import '../../domain/entities/user/kullanici_profili.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/user/update_user_profile.dart';
import '../../core/utils/app_logger.dart';

class ProfilPage extends StatefulWidget {
  final VoidCallback? onProfilKaydedildi; // Profil kaydedilince callback
  
  const ProfilPage({
    super.key,
    this.onProfilKaydedildi,
  });

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final UserRepository _userRepo = di.sl<UserRepository>();
  final UpdateUserProfile _updateProfile = di.sl<UpdateUserProfile>();

  final _adController = TextEditingController(text: 'Ahmet');
  final _soyadController = TextEditingController(text: 'Yılmaz');
  final _yasController = TextEditingController(text: '25');
  final _boyController = TextEditingController(text: '180');
  final _kiloController = TextEditingController(text: '73');
  final _hedefKiloController = TextEditingController(text: '80');
  final _alerjiController = TextEditingController();

  Cinsiyet _cinsiyet = Cinsiyet.erkek;
  Hedef _hedef = Hedef.bulk;
  AktiviteSeviyesi _aktivite = AktiviteSeviyesi.ortaAktif;
  DiyetTipi _diyetTipi = DiyetTipi.normal;
  List<String> _manuelAlerjiler = [];

  MakroHedefleri? _sonuc;
  bool _profilKaydedildi = false;

  @override
  void initState() {
    super.initState();
    _yukle();
    _hesapla();

    _yasController.addListener(_hesapla);
    _boyController.addListener(_hesapla);
    _kiloController.addListener(_hesapla);
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _yasController.dispose();
    _boyController.dispose();
    _kiloController.dispose();
    _hedefKiloController.dispose();
    _alerjiController.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    final kullanici = await _userRepo.onbellektenProfilGetir();
    if (kullanici != null) {
      setState(() {
        _adController.text = kullanici.ad;
        _soyadController.text = kullanici.soyad;
        _yasController.text = kullanici.yas.toString();
        _boyController.text = kullanici.boy.toString();
        _kiloController.text = kullanici.mevcutKilo.toString();
        _hedefKiloController.text = kullanici.hedefKilo?.toString() ?? '';
        _cinsiyet = kullanici.cinsiyet;
        _hedef = kullanici.hedef;
        _aktivite = kullanici.aktiviteSeviyesi;
        _diyetTipi = kullanici.diyetTipi;
        _manuelAlerjiler = kullanici.manuelAlerjiler;
        _profilKaydedildi = true;
      });
      _hesapla();
    }
  }

  void _hesapla() {
    final yas = int.tryParse(_yasController.text) ?? 25;
    final boy = double.tryParse(_boyController.text) ?? 180;
    final kilo = double.tryParse(_kiloController.text) ?? 73;

    if (yas > 0 && boy > 0 && kilo > 0) {
      final tempProfil = KullaniciProfili(
        id: 'temp',
        ad: _adController.text.isEmpty ? 'Kullanıcı' : _adController.text,
        soyad: _soyadController.text.isEmpty ? 'Kullanıcı' : _soyadController.text,
        yas: yas,
        cinsiyet: _cinsiyet,
        boy: boy,
        mevcutKilo: kilo,
        hedef: _hedef,
        aktiviteSeviyesi: _aktivite,
        diyetTipi: _diyetTipi,
        manuelAlerjiler: _manuelAlerjiler,
        kayitTarihi: DateTime.now(),
      );

      setState(() {
        _sonuc = MealPlanService.calculateTargets(tempProfil);
      });
    }
  }

  Future<void> _profiliKaydet() async {
    AppLogger.info('--- _profiliKaydet metodu tetiklendi ---'); // DEBUG LOG
    final ad = _adController.text.trim();
    final soyad = _soyadController.text.trim();
    final yas = int.tryParse(_yasController.text);
    final boy = double.tryParse(_boyController.text);
    final kilo = double.tryParse(_kiloController.text);
    final hedefKilo = double.tryParse(_hedefKiloController.text);

    if (ad.isEmpty || soyad.isEmpty || yas == null || boy == null || kilo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm gerekli alanları doldurun'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final profil = KullaniciProfili(
      id: '00000000-0000-0000-0000-000000000000',
      ad: ad,
      soyad: soyad,
      yas: yas,
      cinsiyet: _cinsiyet,
      boy: boy,
      mevcutKilo: kilo,
      hedefKilo: hedefKilo,
      hedef: _hedef,
      aktiviteSeviyesi: _aktivite,
      diyetTipi: _diyetTipi,
      manuelAlerjiler: _manuelAlerjiler,
      kayitTarihi: DateTime.now(),
    );

    // Profili Supabase'e kaydet (UpdateUserProfile use case)
    final sonuc = await _updateProfile(profil);

    sonuc.fold(
      (hata) {
        // Kaydetme ba_arısız
        debugPrint('?❌ Profil kaydedilemedi: ${hata.mesaj}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('?❌ Profil kaydedilemedi: ${hata.mesaj}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      (kaydedilenProfil) {
        debugPrint(' Profil kaydedildi: ${kaydedilenProfil.ad}');

        if (mounted) {
          setState(() {
            _profilKaydedildi = true;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Profil kaydedildi! Beslenme planınız oluşturuluyor...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Profil kaydedilince otomatik olarak beslenme sekmesine ge?
          widget.onProfilKaydedildi?.call();
        }
      },
    );
  }

  void _alerjiEkle() {
    final alerji = _alerjiController.text.trim();
    if (alerji.isNotEmpty && !_manuelAlerjiler.contains(alerji)) {
      setState(() {
        _manuelAlerjiler.add(alerji);
        _alerjiController.clear();
      });
    }
  }

  void _alerjiSil(String alerji) {
    setState(() {
      _manuelAlerjiler.remove(alerji);
    });
  }

  List<String> get _tumKisitlamalar {
    final Set<String> kisitlamalar = {};
    kisitlamalar.addAll(_diyetTipi.varsayilanKisitlamalar);
    kisitlamalar.addAll(_manuelAlerjiler);
    return kisitlamalar.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            
            // Ba_lık
            Row(
              children: [
                Icon(Icons.person, color: Colors.purple.shade700, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Profil & Makro Hesaplama',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // K0Ş0SEL B0LG0LER
            _buildCard(
              title: 'Kişisel Bilgiler',
              icon: Icons.person_outline,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _adController,
                        label: 'Ad',
                        suffix: '',
                        keyboardType: TextInputType.text,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _soyadController,
                        label: 'Soyad',
                        suffix: '',
                        keyboardType: TextInputType.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Cinsiyet',
                  value: _cinsiyet,
                  items: Cinsiyet.values,
                  onChanged: (val) {
                    setState(() => _cinsiyet = val!);
                    _hesapla();
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _yasController,
                  label: 'Yaş',
                  suffix: 'yıl',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _boyController,
                  label: 'Boy',
                  suffix: 'cm',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _kiloController,
                  label: 'Mevcut Kilo',
                  suffix: 'kg',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _hedefKiloController,
                  label: 'Hedef Kilo (Opsiyonel)',
                  suffix: 'kg',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // HEDEF VE AKT0V0TE
            _buildCard(
              title: 'Hedef ve Aktivite',
              icon: Icons.flag_outlined,
              children: [
                _buildDropdown(
                  label: 'Hedefiniz',
                  value: _hedef,
                  items: Hedef.values,
                  onChanged: (Hedef? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _hedef = newValue;
                          // Kilo hedefi ile senkronize et
                          if (_hedef == Hedef.bulk) {
                            if ((double.tryParse(_hedefKiloController.text) ?? 0) <= (double.tryParse(_kiloController.text) ?? 0)) {
                              _hedefKiloController.text = ((double.tryParse(_kiloController.text) ?? 0) + 5).toString();
                            }
                          } else if (_hedef == Hedef.cut) {
                            if ((double.tryParse(_hedefKiloController.text) ?? 0) >= (double.tryParse(_kiloController.text) ?? 0)) {
                              _hedefKiloController.text = ((double.tryParse(_kiloController.text) ?? 0) - 5).toString();
                            }
                          } else { // Maintain
                            _hedefKiloController.text = _kiloController.text;
                          }
                        });
                        _hesapla();
                      }
                    },
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Aktivite Seviyesi',
                  value: _aktivite,
                  items: AktiviteSeviyesi.values,
                  onChanged: (val) {
                    setState(() => _aktivite = val!);
                    _hesapla();
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // D0YET VE ALERJ0LER
            _buildCard(
              title: 'Diyet ve Alerjiler',
              icon: Icons.restaurant_menu,
              children: [
                _buildDropdown(
                  label: 'Diyet Tipi',
                  value: _diyetTipi,
                  items: DiyetTipi.values,
                  onChanged: (val) {
                    setState(() => _diyetTipi = val!);
                  },
                ),

                const SizedBox(height: 16),

                if (_diyetTipi.varsayilanKisitlamalar.isNotEmpty) ...[
                  Text(
                    '=? Otomatik Kısıtlamalar (${_diyetTipi.aciklama}):',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _diyetTipi.varsayilanKisitlamalar
                        .map((k) => Chip(
                              label: Text(k),
                              backgroundColor: Colors.orange.shade100,
                              avatar: const Icon(Icons.block, size: 16),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _alerjiController,
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Manuel Alerji/Kısıtlama Ekle',
                          hintText: '?Ö🥜 Örn: Ceviz, Fındık, Soya',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: (_) => _alerjiEkle(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _alerjiEkle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),

                if (_manuelAlerjiler.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '?⚠️ Manuel Alerjiler:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _manuelAlerjiler
                        .map((a) => Chip(
                              label: Text(a),
                              backgroundColor: Colors.red.shade100,
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => _alerjiSil(a),
                            ))
                        .toList(),
                  ),
                ],

                if (_tumKisitlamalar.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Toplam ${_tumKisitlamalar.length} Kısıtlama',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _tumKisitlamalar.join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // SONU?LAR
            if (_sonuc != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade100, Colors.green.shade50],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Makrolar Hesaplandı!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildMakroCard(
                      '🔥 Günlük Kalori',
                      '${_sonuc!.gunlukKalori.toStringAsFixed(0)} kcal',
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildMakroCard(
                      '🥩 Protein',
                      '${_sonuc!.gunlukProtein.toStringAsFixed(0)} g',
                      Colors.red,
                    ),
                    const SizedBox(height: 12),
                    _buildMakroCard(
                      '🥖 Karbonhidrat',
                      '${_sonuc!.gunlukKarbonhidrat.toStringAsFixed(0)} g',
                      Colors.amber,
                    ),
                    const SizedBox(height: 12),
                    _buildMakroCard(
                      '🥑 Yağ',
                      '${_sonuc!.gunlukYag.toStringAsFixed(0)} g',
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // KAYDET BUTONU
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _profiliKaydet,
                icon: const Icon(Icons.save),
                label: Text(
                  _profilKaydedildi ? 'Profili Güncelle' : 'Profili Kaydet',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // YENİ YEMEK VERİTABANI YENİLEME BUTONU
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Yemek Veritabanını Yenile'),
                      content: const Text(
                        '''Eski yemekler silinip yeni yemekler yüklenecek.

 120 farklı ara öğün
  Yeni akşam yemekleri
 Tüm kategorilerde çeşitlilik

Planlar yeniden oluşturulacak. Devam edilsin mi?''',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('İptal'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Yenile'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && mounted) {
                    // Progress dialog g?ster
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Yeni yemekler yükleniyor...'),
                          ],
                        ),
                      ),
                    );

                    try {
                      // ?a?️ PostgreSQL modunda yemek yenileme özelliği devre dışıı
                      // Yemek verileri bulutta saklanıyor ve admin panel ?zerinden y?netilir
                      await Future.delayed(const Duration(seconds: 1));
                      
                      bool success = false; // Devre dı_ı

                      if (mounted) {
                        Navigator.pop(context); // Progress dialog kapat

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(' Yeni yemekler y?klendi! Şimdi "Plan Oluştur" butonuna basın!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('?R Y?kleme ba_arısız!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); // Progress dialog kapat
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('?❌ Hata: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Yemek Veritabanın1 Yenile (120 Ara ??n Ekle)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    TextInputType keyboardType = TextInputType.number,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix.isNotEmpty ? suffix : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      dropdownColor: Colors.white, // FIX: dropdown arka plan siyah geliyordu
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white, // FIX: Arka plan uyumu için beyaz yaptık
      ),
      items: items.map((item) {
        String text = '';
        if (item is Cinsiyet) text = item.aciklama;
        if (item is Hedef) text = item.aciklama;
        if (item is AktiviteSeviyesi) text = item.aciklama;
        if (item is DiyetTipi) text = item.aciklama;

        return DropdownMenuItem<T>(
          value: item,
          child: Text(text),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildMakroCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


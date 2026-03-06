import 'package:flutter/material.dart';
import '../../domain/usecases/user/calculate_macros.dart';
import '../../domain/entities/nutrition/makro_hedefleri.dart';
import '../../domain/entities/user/hedef.dart';
import '../../domain/entities/user/kullanici_profili.dart';

// ============================================================================
// MAKRO HESAPLAMA EKRANI - D0NAM0K G?NCELLEME + ALERJ0 S0STEM0
// ============================================================================

class MacroCalculatorPage extends StatefulWidget {
  const MacroCalculatorPage({super.key});

  @override
  State<MacroCalculatorPage> createState() => _MacroCalculatorPageState();
}

class _MacroCalculatorPageState extends State<MacroCalculatorPage> {
  final _hesaplama = CalculateMacros();
  final _yasController = TextEditingController(text: '25');
  final _boyController = TextEditingController(text: '180');
  final _kiloController = TextEditingController(text: '73');
  final _hedefKiloController = TextEditingController(text: '80');
  final _alerjiController = TextEditingController();

  Cinsiyet _cinsiyet = Cinsiyet.erkek;
  Hedef _hedef = Hedef.cut;
  AktiviteSeviyesi _aktivite = AktiviteSeviyesi.ortaAktif;
  DiyetTipi _diyetTipi = DiyetTipi.normal;
  final List<String> _manuelAlerjiler = [];

  MakroHedefleri? _sonuc;

  @override
  void initState() {
    super.initState();
    _hesapla(); // ⭐ 0lk y?klemede hesapla

    // ⭐ D0NAM0K G?NCELLEME: Her dei_iklikte yeniden hesapla
    _yasController.addListener(_hesapla);
    _boyController.addListener(_hesapla);
    _kiloController.addListener(_hesapla);
  }

  @override
  void dispose() {
    _yasController.dispose();
    _boyController.dispose();
    _kiloController.dispose();
    _hedefKiloController.dispose();
    _alerjiController.dispose();
    super.dispose();
  }

  // ⭐ D0NAM0K HESAPLAMA
  void _hesapla() {
    final yas = int.tryParse(_yasController.text) ?? 25;
    final boy = double.tryParse(_boyController.text) ?? 180;
    final kilo = double.tryParse(_kiloController.text) ?? 73;

    if (yas > 0 && boy > 0 && kilo > 0) {
      // Ge?ici profil oluştur (hesaplama i?in)
      final tempProfil = KullaniciProfili(
        id: 'temp',
        ad: 'Temp',
        soyad: 'User',
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
        _sonuc = _hesaplama(tempProfil);
      });

      // Debug log
      debugPrint(
          '✅ Yeniden hesaplandı: ${_sonuc?.gunlukKalori.toStringAsFixed(0)} kcal');
    }
  }

  // ⭐ ALERJ0 EKLEME
  void _alerjiEkle() {
    final alerji = _alerjiController.text.trim();
    if (alerji.isNotEmpty && !_manuelAlerjiler.contains(alerji)) {
      setState(() {
        _manuelAlerjiler.add(alerji);
        _alerjiController.clear();
      });
    }
  }

  // ⭐ ALERJ0 S0LME
  void _alerjiSil(String alerji) {
    setState(() {
      _manuelAlerjiler.remove(alerji);
    });
  }

  // ⭐ T?M KISITLAMALAR
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
      appBar: AppBar(
        title: const Text('ZindeAI - Makro Hesaplama'),
        backgroundColor: Colors.purple.shade200,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // K0Ş0SEL B0LG0LER
            _buildCard(
              title: 'Ki_isel Bilgiler',
              icon: Icons.person,
              children: [
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
                  label: 'Ya_',
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
              icon: Icons.flag,
              children: [
                _buildDropdown(
                  label: 'Hedefiniz',
                  value: _hedef,
                  items: Hedef.values,
                  onChanged: (val) {
                    setState(() => _hedef = val!);
                    _hesapla();
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

            // ⭐ D0YET VE ALERJ0LER
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

                // Otomatik kısıtlamalar
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

                // Manuel alerji ekleme
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _alerjiController,
                        decoration: InputDecoration(
                          labelText: 'Manuel Alerji/Kısıtlama Ekle',
                          hintText: '?rn: Ceviz, Fındık, Soya',
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

                // Eklenen alerjiler
                if (_manuelAlerjiler.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '?a?️ Manuel Alerjiler:',
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

                // T?m kısıtlamalar ?zeti
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
                          'Makrolar Hesapland1!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildMakroCard(
                      '=% G?nl?k Kalori',
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
                      'x?a Karbonhidrat',
                      '${_sonuc!.gunlukKarbonhidrat.toStringAsFixed(0)} g',
                      Colors.amber,
                    ),
                    const SizedBox(height: 12),
                    _buildMakroCard(
                      '>Q Ya',
                      '${_sonuc!.gunlukYag.toStringAsFixed(0)} g',
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ],
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
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
    // x? Explicit type casting for items map to avoid generic type issues
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items.map<DropdownMenuItem<T>>((item) {
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


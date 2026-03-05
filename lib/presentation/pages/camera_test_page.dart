// ============================================================================
// CAMERA TEST PAGE - AI Foto Analiz Testi
// ============================================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/utils/app_logger.dart';

class CameraTestPage extends StatefulWidget {
  const CameraTestPage({super.key});

  @override
  State<CameraTestPage> createState() => _CameraTestPageState();
}

class _CameraTestPageState extends State<CameraTestPage> {
  Map<String, dynamic>? _sonAnaliz;
  bool _yukleniyor = false;

  /// Mock camera g�r�nt�s� oluştur ve analiz et
  Future<void> _mockCameraAnaliziYap() async {
    setState(() {
      _yukleniyor = true;
      _sonAnaliz = null;
    });

    try {
      // Mock kamera byte'lar1 (ger�ek uygulamada camera plugin'den gelecek)
      
      
      AppLogger.info('x� Camera Test: Mock analiz ba_latılıyor...');
      
      // TODO: canliYemekTanima metodu hen�z implement edilmedi
      // final sonuc = await _aiServisi.canliYemekTanima(cameraBytes: mockCameraBytes);
      final sonuc = <String, dynamic>{
        'yemek': 'Test Yemei',
        'kalori': 500.0,
        'message': 'Mock sonuc - AI servisi yakında eklenecek',
      };
      
      setState(() {
        _sonAnaliz = sonuc;
        _yukleniyor = false;
      });
      
      AppLogger.success(' Camera Test: Analiz tamamland1 (Mock)');
    } catch (e) {
      setState(() {
        _yukleniyor = false;
        _sonAnaliz = {
          'hata': true,
          'mesaj': e.toString(),
        };
      });
      
      AppLogger.error('�R Camera Test Hatas1: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('x� Camera AI Test'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Butonu
            ElevatedButton.icon(
              onPressed: _yukleniyor ? null : _mockCameraAnaliziYap,
              icon: const Icon(Icons.camera_alt),
              label: _yukleniyor
                  ? const Text('Analiz Ediliyor...')
                  : const Text('Mock Camera Analizi Ba_lat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Loading Indicator
            if (_yukleniyor)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('AI analiz yapıyor...'),
                  ],
                ),
              ),
            
            // Analiz Sonucu
            if (_sonAnaliz != null && !_yukleniyor)
              Expanded(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'x` Analiz Sonucu',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const Divider(height: 24),
                          
                          if (_sonAnaliz!.containsKey('hata'))
                            _buildErrorCard()
                          else
                            _buildSuccessCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            
            // Info Card
            if (_sonAnaliz == null && !_yukleniyor)
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Camera AI Test Bilgileri',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'x�� Bu sayfa AI Foto Analiz servisini test eder.\n\n'
                          'x� Mock kamera verisi ile canl1 yemek tanıma �zelliini test eder.\n\n'
                          'x� Ger�ek uygulamada:\n'
                          '  ⬢ Camera plugin kullanılır\n'
                          '  ⬢ Ger�ek zamanl1 g�r�nt� analizi yapılır\n'
                          '  ⬢ AI sonu�lar1 g�sterilir\n\n'
                          ' Sistemi test etmek i�in yukarıdaki butona tıklayın.',
                          style: TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Hata Oluştu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _sonAnaliz!['mesaj'] ?? 'Bilinmeyen hata',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tanınma Durumu
          _buildInfoRow(
            icon: Icons.check_circle_outline,
            label: 'Tanınd1',
            value: _sonAnaliz!['tanindi'] == true ? 'Evet ' : 'Hayır �R',
            color: Colors.green.shade700,
          ),
          const Divider(height: 24),
          
          // Hızl1 Tanım
          if (_sonAnaliz!.containsKey('hizli_tanim'))
            _buildInfoRow(
              icon: Icons.flash_on,
              label: 'Hızl1 Tanım',
              value: _sonAnaliz!['hizli_tanim'],
              color: Colors.orange.shade700,
            ),
          const SizedBox(height: 12),
          
          // G�venilirlik
          if (_sonAnaliz!.containsKey('guvenlilk'))
            _buildInfoRow(
              icon: Icons.analytics_outlined,
              label: 'G�venilirlik',
              value: '${(_sonAnaliz!['guvenlilk'] * 100).toStringAsFixed(1)}%',
              color: Colors.blue.shade700,
            ),
          const SizedBox(height: 12),
          
          // �neri
          if (_sonAnaliz!.containsKey('oneri'))
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _sonAnaliz!['oneri'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Raw Data (Debug)
          ExpansionTile(
            title: const Text('x� Raw Debug Data'),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _sonAnaliz.toString(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

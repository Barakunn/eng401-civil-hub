import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/contracts/calculation_strategy.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/formatters.dart';
import '../../calculations/domain/calculation_record.dart';
import '../data/remote_algorithm_service.dart';
import '../domain/remote_calculation_result.dart';

class RemoteAlgorithmScreen extends StatefulWidget {
  const RemoteAlgorithmScreen({super.key});

  @override
  State<RemoteAlgorithmScreen> createState() => _RemoteAlgorithmScreenState();
}

class _RemoteAlgorithmScreenState extends State<RemoteAlgorithmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _projectController = TextEditingController(text: '7-Girdili Algoritma Şantiye Testi');
  final RemoteAlgorithmService _apiService = RemoteAlgorithmService();

  // 7 Adet Textbox Controller'ı
  final List<TextEditingController> _inputControllers = List.generate(
    7,
    (index) => TextEditingController(
      text: [10, 20, 30, 40, 5, 10, 15][index].toString(),
    ),
  );

  RemoteCalculationResult? _latestResult;
  bool _isLoading = false;
  bool _isSaving = false;

  final List<String> _paramHints = [
    'x1: Toplama Grubu 1. Parametre',
    'x2: Toplama Grubu 2. Parametre',
    'x3: Toplama Grubu 3. Parametre',
    'x4: Toplama Grubu 4. Parametre',
    'x5: Çıkarma Grubu 1. Parametre',
    'x6: Çıkarma Grubu 2. Parametre',
    'x7: Çıkarma Grubu 3. Parametre',
  ];

  @override
  void initState() {
    super.initState();
    _urlController.text = _apiService.serverUrl;
    _apiService.checkServerHealth();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _projectController.dispose();
    for (final c in _inputControllers) {
      c.dispose();
    }
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _executeRemoteCalculation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final inputs = <String, double>{};
    for (int i = 0; i < 7; i++) {
      final val = double.tryParse(_inputControllers[i].text.trim()) ?? 0.0;
      inputs['x${i + 1}'] = val;
    }

    try {
      _apiService.updateServerUrl(_urlController.text.trim());
      final result = await _apiService.calculate(
        inputs: inputs,
        allowSimulationFallback: true,
      );

      setState(() {
        _latestResult = result;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isMock
                ? 'ℹ️ Web servisine ulaşılamadı, yerel simülasyonla hesaplandı (${result.responseTimeMs} ms)'
                : '✅ Web servisinden 1 çıktı başarıyla alındı! (${result.responseTimeMs} ms)',
          ),
          backgroundColor: result.isMock ? const Color(0xFFD97706) : const Color(0xFF0F766E),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _saveToLocalHistory() async {
    if (_latestResult == null) return;
    setState(() => _isSaving = true);

    final container = AppScope.of(context);
    final record = CalculationRecord(
      id: 'remote-${DateTime.now().millisecondsSinceEpoch}',
      formulaId: 'remote_7_inputs',
      title: '7-Girdili Algoritma Web Servisi',
      category: 'Web Servis & Algoritma',
      projectName: _projectController.text.trim().isEmpty
          ? '7-Girdi Algoritması'
          : _projectController.text.trim(),
      timestamp: _latestResult!.timestamp,
      inputs: _latestResult!.inputs,
      result: CalculationExecutionResult(
        outputs: {
          'Hesaplanan Çıktı': _latestResult!.output,
        },
        outputUnits: {
          'Hesaplanan Çıktı': 'Birim',
        },
        summary: '${_latestResult!.formula} = ${_latestResult!.output} (${_latestResult!.details})',
        isSafe: _latestResult!.isSafe,
        warnings: _latestResult!.isSafe ? [] : ['Uyarı: Çıktı değeri negatif veya güvenlik sınırı altında!'],
      ),
    );

    await container.historyRepository.saveRecord(record);
    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Hesaplama geçmiş kayıtlarına eklendi.'),
        backgroundColor: Color(0xFF1E3A8A),
      ),
    );
  }

  void _copyResultToClipboard() {
    if (_latestResult == null) return;
    final sb = StringBuffer();
    sb.writeln('📋 7-GİRDİLİ WEB SERVİS HESAP RAPORU');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('Proje: ${_projectController.text}');
    sb.writeln('Tarih: ${Formatters.formatDate(_latestResult!.timestamp)}');
    sb.writeln('Kaynak: ${_latestResult!.isMock ? "Yedek Simülasyon" : "Canlı Web Servisi (${_apiService.serverUrl})"}');
    sb.writeln('');
    sb.writeln('📥 7 GİRDİ:');
    _latestResult!.inputs.forEach((k, v) => sb.writeln(' • $k = $v'));
    sb.writeln('');
    sb.writeln('📤 1 ÇIKTI (OUTPUT): ${_latestResult!.output}');
    sb.writeln('Formül: ${_latestResult!.formula}');
    sb.writeln('Detay: ${_latestResult!.details}');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mühendislik raporu panoya kopyalandı!'),
        backgroundColor: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('7-Girdili Algoritma Servisi'),
        actions: [
          if (_latestResult != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Raporu Kopyala',
              onPressed: _copyResultToClipboard,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bilgi Banner'ı
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hub_rounded, color: Color(0xFF1E40AF), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mobil cihazdan 7 textbox ile parametreler toplanır, HTTP POST ile Web Servise iletilir ve sunucuda hesaplanan 1 çıktı ekranda gösterilir.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Web Servis Bağlantı Çubuğu
            AnimatedBuilder(
              animation: _apiService,
              builder: (context, _) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _apiService.isOnline ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _apiService.isOnline
                                  ? 'Web Servisi Çevrimiçi (Bağlı)'
                                  : 'Web Servisine Ulaşılamadı (Simülasyon Modu Aktif)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _apiService.isOnline ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                              ),
                            ),
                            const Spacer(),
                            if (_apiService.isChecking)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              TextButton(
                                onPressed: () {
                                  _apiService.updateServerUrl(_urlController.text.trim());
                                  _apiService.checkServerHealth();
                                },
                                child: const Text('Test Et', style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'Web Servis Endpoint (POST)',
                            prefixIcon: Icon(Icons.link_rounded),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // Şantiye / Proje Adı
            TextFormField(
              controller: _projectController,
              decoration: const InputDecoration(
                labelText: 'Şantiye / Hesaplama Başlığı',
                prefixIcon: Icon(Icons.apartment_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // 7 Adet Textbox Girdisi
            Row(
              children: [
                const Icon(Icons.format_list_numbered_rounded, color: Color(0xFF1E3A8A), size: 20),
                const SizedBox(width: 8),
                const Text(
                  '7 Girdi Parametresi (Inputs)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    final defaults = [10, 20, 30, 40, 5, 10, 15];
                    for (int i = 0; i < 7; i++) {
                      _inputControllers[i].text = defaults[i].toString();
                    }
                  },
                  child: const Text('Sıfırla', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...List.generate(7, (index) {
              final isSumGroup = index < 4;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _inputControllers[index],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: 'Girdi ${index + 1} (x${index + 1})',
                    helperText: _paramHints[index],
                    prefixIcon: Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        isSumGroup ? '+x${index + 1}' : '-x${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSumGroup ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Lütfen bir sayı girin';
                    if (double.tryParse(v.trim()) == null) return 'Geçerli bir sayı olmalı';
                    return null;
                  },
                ),
              );
            }),

            const SizedBox(height: 12),

            // AKSİYON DÜĞMESİ (HESAPLAT)
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _executeRemoteCalculation,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(
                _isLoading ? 'Web Servise Gönderiliyor...' : 'Web Serviste Hesaplat (HTTP POST)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 20),

            // 1 OUTPUT SONUÇ KARTI
            if (_latestResult != null) ...[
              const Row(
                children: [
                  Icon(Icons.output_rounded, color: Color(0xFF0F766E), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Web Servis Çıktısı (1 Output)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSingleOutputCard(_latestResult!),
              const SizedBox(height: 14),

              // Cihaza Kaydet Butonu
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _saveToLocalHistory,
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_alt_rounded),
                      label: const Text('Sonucu Cihaza Kaydet'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _copyResultToClipboard,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Raporu Paylaş'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSingleOutputCard(RemoteCalculationResult res) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: res.isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: res.isMock ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    res.isMock ? '🟡 Simülasyon' : '🟢 Canlı Web Servis',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: res.isMock ? const Color(0xFFB45309) : const Color(0xFF15803D),
                    ),
                  ),
                ),
                Text(
                  '${res.responseTimeMs} ms',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Büyük 1 Output Değeri
            const Text(
              'HESAPLANAN ÇIKTI',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1),
            ),
            const SizedBox(height: 4),
            Text(
              res.output.toString(),
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: res.isSafe ? const Color(0xFF0F172A) : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 8),

            // Formül Açıklaması
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formül: ${res.formula}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    res.details,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


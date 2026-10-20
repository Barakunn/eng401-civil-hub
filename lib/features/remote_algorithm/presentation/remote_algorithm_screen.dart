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
  final _projectController = TextEditingController(text: 'Algoritma Saha Hesabı');
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
                ? 'ℹ️ Simülasyon modu ile hesaplandı (${result.responseTimeMs} ms)'
                : '✅ Web servisinden çıktı alındı! (${result.responseTimeMs} ms)',
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
      title: '7-Girdili Algoritma Servisi',
      category: 'Web Servis',
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
          'Hesaplanan Çıktı': '',
        },
        summary: '${_latestResult!.formula} = ${_latestResult!.output}',
        isSafe: _latestResult!.isSafe,
        warnings: _latestResult!.isSafe ? [] : ['Uyarı: Çıktı değeri negatif!'],
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
    sb.writeln('📋 7-GİRDİLİ HESAP RAPORU');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('Proje: ${_projectController.text}');
    sb.writeln('Tarih: ${Formatters.formatDate(_latestResult!.timestamp)}');
    sb.writeln('Kaynak: ${_latestResult!.isMock ? "Yedek Simülasyon" : "Web Servisi"}');
    sb.writeln('');
    sb.writeln('📥 Girdiler:');
    _latestResult!.inputs.forEach((k, v) => sb.writeln(' • $k = $v'));
    sb.writeln('');
    sb.writeln('📤 ÇIKTI (OUTPUT): ${_latestResult!.output}');
    sb.writeln('Formül: ${_latestResult!.formula}');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rapor panoya kopyalandı!'),
        backgroundColor: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('7-Girdili Algoritma'),
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
            // Web Servis Bağlantı Çubuğu
            AnimatedBuilder(
              animation: _apiService,
              builder: (context, _) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _apiService.isOnline ? Colors.green : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _apiService.isOnline ? 'Servis Çevrimiçi' : 'Servis Çevrimdışı (Simülasyon Aktif)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _apiService.isOnline ? const Color(0xFF15803D) : const Color(0xFF64748B),
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
                              InkWell(
                                onTap: () {
                                  _apiService.updateServerUrl(_urlController.text.trim());
                                  _apiService.checkServerHealth();
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Text('Test Et', style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'Web Servis Adresi (Endpoint)',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Şantiye / Proje Adı
            TextFormField(
              controller: _projectController,
              decoration: const InputDecoration(
                labelText: 'Proje / Başlık',
                prefixIcon: Icon(Icons.edit_note_rounded),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),

            // 7 Adet Textbox Girdisi Başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Girdi Parametreleri (7 Input)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                TextButton(
                  onPressed: () {
                    final defaults = [10, 20, 30, 40, 5, 10, 15];
                    for (int i = 0; i < 7; i++) {
                      _inputControllers[i].text = defaults[i].toString();
                    }
                  },
                  child: const Text('Varsayılana Sıfırla', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // 7 Girdi Kutucuğu (Sade, Kompakt)
            ...List.generate(7, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  controller: _inputControllers[index],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: 'Girdi ${index + 1} (x${index + 1})',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    prefixIcon: Container(
                      width: 36,
                      alignment: Alignment.center,
                      child: Text(
                        'x${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13),
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Sayı girin';
                    if (double.tryParse(v.trim()) == null) return 'Geçersiz';
                    return null;
                  },
                ),
              );
            }),

            const SizedBox(height: 14),

            // HESAPLA BUTONU
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _executeRemoteCalculation,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate_rounded),
              label: Text(
                _isLoading ? 'Hesaplanıyor...' : 'Hesapla (Web Servis)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 16),

            // 1 OUTPUT SONUÇ KARTI
            if (_latestResult != null) ...[
              _buildSingleOutputCard(_latestResult!),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _saveToLocalHistory,
                      icon: _isSaving
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_alt_rounded),
                      label: const Text('Cihaza Kaydet'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _copyResultToClipboard,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Paylaş'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
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
      elevation: 1,
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
                    res.isMock ? 'Simülasyon' : 'Canlı Web Servis',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: res.isMock ? const Color(0xFFB45309) : const Color(0xFF15803D),
                    ),
                  ),
                ),
                Text(
                  '${res.responseTimeMs} ms',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            const Text(
              'SONUÇ (OUTPUT)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
            ),
            const SizedBox(height: 2),
            Text(
              res.output.toString(),
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: res.isSafe ? const Color(0xFF0F172A) : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Formül: ${res.formula}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

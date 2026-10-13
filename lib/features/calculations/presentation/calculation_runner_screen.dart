import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/contracts/calculation_strategy.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/formatters.dart';
import '../domain/calculation_record.dart';

class CalculationRunnerScreen extends StatefulWidget {
  final CalculationStrategy strategy;
  final CalculationRecord? initialRecord;

  const CalculationRunnerScreen({
    super.key,
    required this.strategy,
    this.initialRecord,
  });

  @override
  State<CalculationRunnerScreen> createState() =>
      _CalculationRunnerScreenState();
}

class _CalculationRunnerScreenState extends State<CalculationRunnerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _projectController;
  final Map<String, TextEditingController> _inputControllers = {};
  CalculationExecutionResult? _currentResult;
  bool _isSaving = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _projectController = TextEditingController(
      text: widget.initialRecord?.projectName ?? 'Şantiye Blok 1',
    );

    for (final param in widget.strategy.parameters) {
      final initialVal = widget.initialRecord?.inputs[param.key] ??
          param.defaultValue;
      _inputControllers[param.key] = TextEditingController(
        text: param.stepDecimals == 0
            ? initialVal.toInt().toString()
            : initialVal.toString(),
      );
    }

    if (widget.initialRecord != null) {
      _currentResult = widget.initialRecord!.result;
    } else {
      _executeCalculation();
    }
  }

  @override
  void dispose() {
    _projectController.dispose();
    for (final c in _inputControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _executeCalculation() {
    final inputs = <String, double>{};
    for (final entry in _inputControllers.entries) {
      final val = double.tryParse(entry.value.text) ?? 0.0;
      inputs[entry.key] = val;
    }
    setState(() {
      _currentResult = widget.strategy.calculate(inputs);
    });
  }

  Future<void> _saveToLocal() async {
    if (_currentResult == null) return;
    setState(() => _isSaving = true);

    final container = AppScope.of(context);
    final inputs = <String, double>{};
    for (final entry in _inputControllers.entries) {
      inputs[entry.key] = double.tryParse(entry.value.text) ?? 0.0;
    }

    final record = CalculationRecord(
      id: widget.initialRecord?.id ??
          'calc-${DateTime.now().millisecondsSinceEpoch}',
      formulaId: widget.strategy.id,
      title: widget.strategy.title,
      category: widget.strategy.category,
      projectName: _projectController.text.trim().isEmpty
          ? 'İsimsiz Proje'
          : _projectController.text.trim(),
      timestamp: DateTime.now(),
      inputs: inputs,
      result: _currentResult!,
    );

    await container.historyRepository.saveRecord(record);

    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Hesaplama başarıyla telefona kaydedildi.'),
        backgroundColor: Color(0xFF0F766E),
      ),
    );
  }

  Future<void> _pushToServer() async {
    if (_currentResult == null) return;
    setState(() => _isSyncing = true);

    final container = AppScope.of(context);
    final inputs = <String, double>{};
    for (final entry in _inputControllers.entries) {
      inputs[entry.key] = double.tryParse(entry.value.text) ?? 0.0;
    }

    final record = CalculationRecord(
      id: widget.initialRecord?.id ??
          'calc-${DateTime.now().millisecondsSinceEpoch}',
      formulaId: widget.strategy.id,
      title: widget.strategy.title,
      category: widget.strategy.category,
      projectName: _projectController.text.trim().isEmpty
          ? 'İsimsiz Proje'
          : _projectController.text.trim(),
      timestamp: DateTime.now(),
      inputs: inputs,
      result: _currentResult!,
    );

    final success = await container.syncService.pushRecord(record);

    setState(() => _isSyncing = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🌐 Hesaplama bulut sunucuya yüklendi (POST 200 OK)'),
          backgroundColor: Color(0xFF1E3A8A),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Sunucuya yüklenemedi. Çevrimdışı durumdasınız.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _copyReportToClipboard() {
    if (_currentResult == null) return;
    final inputs = <String, double>{};
    for (final entry in _inputControllers.entries) {
      inputs[entry.key] = double.tryParse(entry.value.text) ?? 0.0;
    }

    final record = CalculationRecord(
      id: 'temp',
      formulaId: widget.strategy.id,
      title: widget.strategy.title,
      category: widget.strategy.category,
      projectName: _projectController.text.trim(),
      timestamp: DateTime.now(),
      inputs: inputs,
      result: _currentResult!,
    );

    final reportText = Formatters.generateReportText(record);
    Clipboard.setData(ClipboardData(text: reportText));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Mühendislik raporu panoya kopyalandı!'),
        backgroundColor: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.strategy.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Raporu Kopyala',
            onPressed: _copyReportToClipboard,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Proje / Şantiye Başlığı
            TextFormField(
              controller: _projectController,
              decoration: const InputDecoration(
                labelText: 'Şantiye / Proje Adı',
                prefixIcon: Icon(Icons.apartment_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // Açıklama Kutusu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF475569), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.strategy.description,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Girdi Parametreleri',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),

            // Dinamik Parametre Girdileri
            ...widget.strategy.parameters.map((param) {
              final controller = _inputControllers[param.key]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: param.label,
                    suffixText: param.unit.isNotEmpty ? param.unit : null,
                    helperText: param.hint.isNotEmpty ? param.hint : null,
                  ),
                  onChanged: (_) => _executeCalculation(),
                ),
              );
            }),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _executeCalculation,
              icon: const Icon(Icons.calculate_rounded),
              label: const Text('Yeniden Hesapla'),
            ),

            const SizedBox(height: 20),

            // Çıktı ve Sonuç Kartı
            if (_currentResult != null) ...[
              const Text(
                'Mühendislik Sonuçları',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              _buildResultCard(_currentResult!),
              const SizedBox(height: 16),

              // Aksiyon Butonları (Kaydet & Sunucuya Gönder)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _saveToLocal,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_alt_rounded),
                      label: const Text('Cihaza Kaydet'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _pushToServer,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_rounded),
                      label: const Text('Sunucuya Yükle'),
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

  Widget _buildResultCard(CalculationExecutionResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Güvenlik & Standart Rozeti
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: result.isSafe
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: result.isSafe
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        result.isSafe ? Icons.check_circle : Icons.warning_rounded,
                        color: result.isSafe
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        result.isSafe ? 'STANDARDA UYGUN' : 'UYARI / RİSK',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: result.isSafe
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  widget.strategy.category,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const Divider(height: 24),

            // Çıktı Tablosu
            ...result.outputs.entries.map((entry) {
              final unit = result.outputUnits[entry.key] ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF334155),
                      ),
                    ),
                    Text(
                      '${entry.value} $unit',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                result.summary,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),

            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...result.warnings.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    w,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/contracts/sync_service.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/formatters.dart';
import '../../calculations/domain/calculation_record.dart';
import '../data/mock_remote_sync_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  late final TextEditingController _endpointController;
  List<CalculationRecord> _remoteRecords = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _endpointController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final container = AppScope.of(context);
    _endpointController.text = container.syncService.serverEndpoint;
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  Future<void> _fetchRemoteData() async {
    setState(() => _isLoading = true);
    final container = AppScope.of(context);
    final results = await container.syncService.fetchRemoteRecords();
    setState(() {
      _remoteRecords = results;
      _isLoading = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🌐 Sunucudan ${_remoteRecords.length} adet kayıt başarıyla çekildi (GET 200 OK).'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
    );
  }

  Future<void> _pushLocalData() async {
    final container = AppScope.of(context);
    final locals = container.historyRepository.records;
    if (locals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yerelde senkronize edilecek hesaplama yok.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final count = await container.syncService.batchSync(locals);
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚀 $count adet yeni şantiye hesabı sunucuya aktarıldı (POST).'),
        backgroundColor: const Color(0xFF0F766E),
      ),
    );
  }

  void _showJsonViewer(CalculationRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'JSON Veri Paketi (REST API Payload)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(record.toJson()),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final syncService = container.syncService;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulut Servis & Senkronizasyon'),
      ),
      body: AnimatedBuilder(
        animation: syncService,
        builder: (context, _) {
          final isOnline = syncService.connectionState != SyncConnectionState.offline;
          final isSyncing = syncService.connectionState == SyncConnectionState.syncing;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Durum Kartı
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSyncing
                                      ? Colors.amber
                                      : (isOnline ? Colors.green : Colors.red),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isSyncing
                                    ? 'Veri Aktarılıyor...'
                                    : (isOnline ? 'Servis Çevrimiçi (Online)' : 'Çevrimdışı (Offline)'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: isOnline,
                            onChanged: (val) {
                              if (syncService is MockRemoteSyncService) {
                                syncService.toggleOnlineStatus(val);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mansur Hoca ve inşaat ekibi ile ortak bulut API entegrasyonu.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),

                      // API Endpoint Input
                      TextField(
                        controller: _endpointController,
                        decoration: InputDecoration(
                          labelText: 'Sunucu API Adresi (REST Endpoint)',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check),
                            tooltip: 'Adresi Güncelle',
                            onPressed: () {
                              syncService.updateEndpoint(_endpointController.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Endpoint adresi güncellendi.')),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // İki Ana İşlem Butonu: POST (Yükle) ve GET (Çek)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_isLoading || !isOnline) ? null : _pushLocalData,
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: const Text('Sunucuya Yükle\n(POST Sync)', textAlign: TextAlign.center),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_isLoading || !isOnline) ? null : _fetchRemoteData,
                      icon: const Icon(Icons.cloud_download_rounded),
                      label: const Text('Sunucudan Çek\n(GET Fetch)', textAlign: TextAlign.center),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sunucudan Çekilen Veriler Başlığı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bulut Sunucudaki Kayıtlar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (_remoteRecords.isEmpty && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Sunucudan kayıtları listelemek için yukarıdaki "Sunucudan Çek" butonuna basınız.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ),

              ..._remoteRecords.map((rec) => Card(
                    child: ListTile(
                      title: Text(
                        rec.projectName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${rec.title}\n${Formatters.formatDate(rec.timestamp)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.code_rounded, color: Color(0xFF1E3A8A)),
                            tooltip: 'JSON Önizle',
                            onPressed: () => _showJsonViewer(rec),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download_rounded, color: Color(0xFF0F766E)),
                            tooltip: 'Telefona Aktar',
                            onPressed: () async {
                              await container.historyRepository.saveRecord(rec);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kayıt telefona aktarıldı!'),
                                  backgroundColor: Color(0xFF0F766E),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/formatters.dart';
import '../../calculations/presentation/calculation_runner_screen.dart';
import '../../remote_algorithm/presentation/remote_algorithm_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onTabChange;

  const DashboardScreen({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final historyRepo = container.historyRepository;
    final strategies = container.calculationStrategies;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ENG401 • İnşaat Servis Portalı'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ENG401 PROJE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.cloud_done_rounded, color: Colors.white70, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'İnşaat Mühendisliği Hesap & Veri Servisi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Saha hesaplamaları, yerel kayıt ve bulut API senkronizasyon iskeleti.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // İstatistik Kartları
          AnimatedBuilder(
            animation: historyRepo,
            builder: (context, _) {
              return Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Aktif Modül',
                      value: '${strategies.length}',
                      subtitle: 'Formül Motoru',
                      icon: Icons.functions_rounded,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Kayıtlı Hesap',
                      value: '${historyRepo.records.length}',
                      subtitle: 'Cihaz Hafızası',
                      icon: Icons.sd_card_rounded,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // 7-GİRDİLİ WEB SERVİS ALGORİTMASI KARTI
          Card(
            color: const Color(0xFF1E3A8A),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RemoteAlgorithmScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '7-Girdili Algoritma Servisi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '7 Girdi (Input) → Web Servis → 1 Çıktı (Output)',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Hızlı Hesaplama Araçları Başlığı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hızlı Hesaplama Modülleri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: () => onTabChange(1), // Hesaplama tabına geç
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Strateji Kartları
          ...strategies.map(
            (s) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1E3A8A).withAlpha(25),
                  child: Icon(
                    Formatters.getFormulaIcon(s.id),
                    color: const Color(0xFF1E3A8A),
                    size: 20,
                  ),
                ),
                title: Text(
                  s.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  s.category,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CalculationRunnerScreen(strategy: s),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Son Yapılan Hesaplamalar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Son Şantiye Kayıtları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: () => onTabChange(2), // Geçmiş tabına geç
                child: const Text('Geçmiş'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          AnimatedBuilder(
            animation: historyRepo,
            builder: (context, _) {
              final recent = historyRepo.records.take(2).toList();
              if (recent.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Henüz kayıt bulunmuyor.'),
                  ),
                );
              }
              return Column(
                children: recent.map((r) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        r.projectName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${r.title} • ${Formatters.formatDate(r.timestamp)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: r.result.isSafe
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          r.result.isSafe ? 'UYGUN' : 'UYARI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: r.result.isSafe
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                      onTap: () {
                        final strategy = container.findStrategy(r.formulaId);
                        if (strategy != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CalculationRunnerScreen(
                                strategy: strategy,
                                initialRecord: r,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

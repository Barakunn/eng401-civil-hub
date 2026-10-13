import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/formatters.dart';
import 'calculation_runner_screen.dart';

class CalculationsListScreen extends StatelessWidget {
  const CalculationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final strategies = container.calculationStrategies;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İnşaat Hesaplama Araçları'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: strategies.length,
        itemBuilder: (context, index) {
          final strategy = strategies[index];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CalculationRunnerScreen(strategy: strategy),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Formatters.getFormulaIcon(strategy.id),
                        color: const Color(0xFF1E3A8A),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                strategy.category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strategy.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strategy.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


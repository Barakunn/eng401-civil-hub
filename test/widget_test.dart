import 'package:flutter_test/flutter_test.dart';
import 'package:eng401_civil_hub/bootstrap.dart';
import 'package:eng401_civil_hub/core/di/app_scope.dart';
import 'package:eng401_civil_hub/main.dart';
import 'package:eng401_civil_hub/features/remote_algorithm/data/remote_algorithm_service.dart';

void main() {
  test('AppContainer Composition Root boots successfully', () async {
    final container = await AppContainer.initialize();
    expect(container.calculationStrategies.length, equals(3));
    expect(container.historyRepository.records.isNotEmpty, isTrue);
  });

  test('ConcreteStrengthStrategy calculates valid fck', () async {
    final container = await AppContainer.initialize();
    final concreteStrategy = container.findStrategy('concrete_strength');
    expect(concreteStrategy, isNotNull);

    final result = concreteStrategy!.calculate({
      'wc_ratio': 0.45,
      'cement': 360.0,
      'air_content': 2.0,
    });

    expect(result.outputs['Karakteristik Silindir (fck)'], greaterThan(25.0));
    expect(result.isSafe, isTrue);
  });

  test('RemoteAlgorithmService calculates 7 inputs to 1 output', () async {
    final service = RemoteAlgorithmService();
    // Test 7 inputs: (10 + 20 + 30 + 40) - (5 + 10 + 15) = 100 - 30 = 70.0
    final result = await service.calculate(
      inputs: {
        'x1': 10.0,
        'x2': 20.0,
        'x3': 30.0,
        'x4': 40.0,
        'x5': 5.0,
        'x6': 10.0,
        'x7': 15.0,
      },
      allowSimulationFallback: true,
    );

    expect(result.output, equals(70.0));
    expect(result.isSafe, isTrue);
    expect(result.formula, contains('10'));
  });

  testWidgets('App renders dashboard smoke test', (WidgetTester tester) async {
    final container = await AppContainer.initialize();
    await tester.pumpWidget(
      AppScope(
        container: container,
        child: const Eng401CivilApp(),
      ),
    );

    expect(find.text('ENG401 PROJE'), findsOneWidget);
    expect(find.text('Panel'), findsOneWidget);
    expect(find.text('Hesaplar'), findsOneWidget);
    expect(find.text('7-Girdili Algoritma Web Servisi'), findsOneWidget);
  });
}

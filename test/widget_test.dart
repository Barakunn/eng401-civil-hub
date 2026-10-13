import 'package:flutter_test/flutter_test.dart';
import 'package:eng401_civil_hub/bootstrap.dart';
import 'package:eng401_civil_hub/core/di/app_scope.dart';
import 'package:eng401_civil_hub/main.dart';

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
  });
}

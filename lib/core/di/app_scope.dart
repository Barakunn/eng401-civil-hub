import 'package:flutter/widgets.dart';
import '../../bootstrap.dart';

/// Composition Root bağımlılıklarını widget ağacına sağlayan
/// sıfır ek kütüphane gerektiren saf Flutter InheritedWidget'ı.
class AppScope extends InheritedWidget {
  final AppContainer container;

  const AppScope({
    super.key,
    required this.container,
    required super.child,
  });

  static AppContainer of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'HATA: AppScope ağaçta bulunamadı!');
    return scope!.container;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) =>
      container != oldWidget.container;
}


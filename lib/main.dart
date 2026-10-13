import 'package:flutter/material.dart';
import 'app.dart';
import 'bootstrap.dart';
import 'core/di/app_scope.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🎯 COMPOSITION ROOT ÇAĞRISI:
  // Tüm bağımlılıklar tek noktadan üretilir ve enjekte edilir.
  final container = await AppContainer.initialize();

  runApp(
    AppScope(
      container: container,
      child: const Eng401CivilApp(),
    ),
  );
}

class Eng401CivilApp extends StatelessWidget {
  const Eng401CivilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ENG401 İnşaat Mühendisliği Servisi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainShellApp(),
    );
  }
}

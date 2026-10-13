import 'package:flutter/material.dart';
import '../../features/calculations/domain/calculation_record.dart';

class Formatters {
  static String formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$min';
  }

  /// Formül türüne göre sabit (tree-shakeable) ikon döner
  static IconData getFormulaIcon(String formulaId) {
    switch (formulaId) {
      case 'concrete_strength':
        return Icons.apartment_rounded;
      case 'rebar_weight':
        return Icons.grid_4x4_rounded;
      case 'soil_bearing':
        return Icons.landscape_rounded;
      default:
        return Icons.calculate_rounded;
    }
  }

  /// Mühendisin şantiye şefine veya hocaya atacağı teknik metin raporu
  static String generateReportText(CalculationRecord record) {
    final sb = StringBuffer();
    sb.writeln('📋 ŞANTİYE TEKNİK HESAP RAPORU');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('Proje: ${record.projectName}');
    sb.writeln('Hesaplama: ${record.title}');
    sb.writeln('Tarih: ${formatDate(record.timestamp)}');
    sb.writeln('');
    sb.writeln('📥 GİRDİLER:');
    record.inputs.forEach((key, val) {
      sb.writeln(' • $key: $val');
    });
    sb.writeln('');
    sb.writeln('📤 ÇIKTILAR:');
    record.result.outputs.forEach((key, val) {
      final unit = record.result.outputUnits[key] ?? '';
      sb.writeln(' • $key: $val $unit');
    });
    sb.writeln('');
    sb.writeln('📌 ÖZET: ${record.result.summary}');
    sb.writeln('Durum: ${record.result.isSafe ? "✅ UYGUN" : "❌ GÜVENLİK SINIRI ALTINDA"}');
    if (record.result.warnings.isNotEmpty) {
      sb.writeln('U Y A R I L A R:');
      for (final w in record.result.warnings) {
        sb.writeln(' $w');
      }
    }
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('ENG401 İnşaat Mühendisliği Servis Uygulaması ile üretildi.');
    return sb.toString();
  }
}

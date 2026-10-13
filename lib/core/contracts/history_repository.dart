import 'package:flutter/foundation.dart';
import '../../features/calculations/domain/calculation_record.dart';

/// Yerel depolama arayüzü
abstract class HistoryRepository extends ChangeNotifier {
  List<CalculationRecord> get records;
  Future<void> saveRecord(CalculationRecord record);
  Future<void> deleteRecord(String id);
  Future<void> clearAll();
}


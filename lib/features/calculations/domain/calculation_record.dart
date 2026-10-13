import '../../../core/contracts/calculation_strategy.dart';

/// Yapılan bir hesaplamanın kaydedilebilir domain modeli
class CalculationRecord {
  final String id;
  final String formulaId;
  final String title;
  final String category;
  final String projectName;
  final DateTime timestamp;
  final Map<String, double> inputs;
  final CalculationExecutionResult result;

  const CalculationRecord({
    required this.id,
    required this.formulaId,
    required this.title,
    required this.category,
    required this.projectName,
    required this.timestamp,
    required this.inputs,
    required this.result,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'formulaId': formulaId,
        'title': title,
        'category': category,
        'projectName': projectName,
        'timestamp': timestamp.toIso8601String(),
        'inputs': inputs,
        'outputs': result.outputs,
        'outputUnits': result.outputUnits,
        'summary': result.summary,
        'isSafe': result.isSafe,
        'warnings': result.warnings,
      };

  factory CalculationRecord.fromJson(Map<String, dynamic> json) {
    final rawOutputs = (json['outputs'] as Map<String, dynamic>?) ?? {};
    final outputs = rawOutputs.map((k, v) => MapEntry(k, (v as num).toDouble()));

    final rawOutputUnits = (json['outputUnits'] as Map<String, dynamic>?) ?? {};
    final outputUnits = rawOutputUnits.map((k, v) => MapEntry(k, v.toString()));

    final rawInputs = (json['inputs'] as Map<String, dynamic>?) ?? {};
    final inputs = rawInputs.map((k, v) => MapEntry(k, (v as num).toDouble()));

    final warnings = (json['warnings'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return CalculationRecord(
      id: json['id'] as String,
      formulaId: json['formulaId'] as String,
      title: json['title'] as String,
      category: json['category'] as String? ?? 'Genel',
      projectName: json['projectName'] as String? ?? 'Şantiye',
      timestamp: DateTime.parse(json['timestamp'] as String),
      inputs: inputs,
      result: CalculationExecutionResult(
        outputs: outputs,
        outputUnits: outputUnits,
        summary: json['summary'] as String? ?? '',
        isSafe: json['isSafe'] as bool? ?? true,
        warnings: warnings,
      ),
    );
  }
}


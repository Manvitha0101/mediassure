import '../models/adherence_log_model.dart';

class AdherenceResult {
  final int total;
  final int taken;
  final int missed;
  final double percentage;

  const AdherenceResult({
    required this.total,
    required this.taken,
    required this.missed,
    required this.percentage,
  });
}

class AdherenceCalculator {
  static AdherenceResult calculate(List<AdherenceLogModel> logs) {
    if (logs.isEmpty) {
      return const AdherenceResult(
        total: 0,
        taken: 0,
        missed: 0,
        percentage: 0.0,
      );
    }

    final total = logs.length;
    final taken = logs.where((log) => log.taken).length;
    final missed = total - taken;
    final percentage = (taken / total) * 100;

    return AdherenceResult(
      total: total,
      taken: taken,
      missed: missed,
      percentage: percentage,
    );
  }
}

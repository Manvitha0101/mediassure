// models/adherence_log_model.dart

enum AdherenceStatus { taken, missed }

class AdherenceLogModel {
  final String logId;
  final String medicineId;
  final AdherenceStatus status;
  final DateTime timestamp;
  final String? imageUrl;

  AdherenceLogModel({
    required this.logId,
    required this.medicineId,
    required this.status,
    required this.timestamp,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  factory AdherenceLogModel.fromMap(Map<String, dynamic> map, String id) {
    return AdherenceLogModel(
      logId: id,
      medicineId: map['medicineId'] ?? '',
      status: AdherenceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AdherenceStatus.missed,
      ),
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
      imageUrl: map['imageUrl'],
    );
  }
}

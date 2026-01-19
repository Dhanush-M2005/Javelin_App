import 'javelin_throw.dart';

enum DatasetStatus {
  downloaded,
  skipped,
  error,
  noThrows,
}

class Dataset {
  final String id;
  final String deviceSsid;
  final String? deviceIp;
  final String filename;
  final DateTime downloadedAt;
  final DatasetStatus status;
  final String? skipReason;
  final List<JavelinThrow> throws;

  Dataset({
    required this.id,
    required this.deviceSsid,
    this.deviceIp,
    required this.filename,
    required this.downloadedAt,
    required this.status,
    this.skipReason,
    this.throws = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceSsid': deviceSsid,
    'deviceIp': deviceIp,
    'filename': filename,
    'downloadedAt': downloadedAt.toIso8601String(),
    'status': status.toString().split('.').last,
    'skipReason': skipReason,
    'throws': throws.map((e) => e.toJson()).toList(),
  };

  factory Dataset.fromJson(Map<String, dynamic> json) => Dataset(
    id: json['id'] as String,
    deviceSsid: json['deviceSsid'] as String,
    deviceIp: json['deviceIp'] as String?,
    filename: json['filename'] as String,
    downloadedAt: DateTime.parse(json['downloadedAt'] as String),
    status: DatasetStatus.values.firstWhere(
      (e) => e.toString().split('.').last == json['status'],
      orElse: () => DatasetStatus.error,
    ),
    skipReason: json['skipReason'] as String?,
    throws: (json['throws'] as List<dynamic>?)
        ?.map((e) => JavelinThrow.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );
}

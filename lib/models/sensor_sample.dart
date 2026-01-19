class SensorSample {
  final int timestampMs;
  final double accXFilt;
  final double accYFilt;
  final double accZFilt;
  final double gyrXFilt;
  final double gyrYFilt;
  final double gyrZFilt;
  final double magXFilt;
  final double magYFilt;
  final double magZFilt;

  SensorSample({
    required this.timestampMs,
    required this.accXFilt,
    required this.accYFilt,
    required this.accZFilt,
    required this.gyrXFilt,
    required this.gyrYFilt,
    required this.gyrZFilt,
    required this.magXFilt,
    required this.magYFilt,
    required this.magZFilt,
  });

  Map<String, dynamic> toJson() => {
    'timestampMs': timestampMs,
    'accXFilt': accXFilt,
    'accYFilt': accYFilt,
    'accZFilt': accZFilt,
    'gyrXFilt': gyrXFilt,
    'gyrYFilt': gyrYFilt,
    'gyrZFilt': gyrZFilt,
    'magXFilt': magXFilt,
    'magYFilt': magYFilt,
    'magZFilt': magZFilt,
  };

  factory SensorSample.fromJson(Map<String, dynamic> json) => SensorSample(
    timestampMs: json['timestampMs'] as int,
    accXFilt: (json['accXFilt'] as num).toDouble(),
    accYFilt: (json['accYFilt'] as num).toDouble(),
    accZFilt: (json['accZFilt'] as num).toDouble(),
    gyrXFilt: (json['gyrXFilt'] as num).toDouble(),
    gyrYFilt: (json['gyrYFilt'] as num).toDouble(),
    gyrZFilt: (json['gyrZFilt'] as num).toDouble(),
    magXFilt: (json['magXFilt'] as num).toDouble(),
    magYFilt: (json['magYFilt'] as num).toDouble(),
    magZFilt: (json['magZFilt'] as num).toDouble(),
  );
}

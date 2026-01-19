import 'sensor_sample.dart';

class TrajectoryPoint {
  final double x;  // East (m)
  final double y;  // North (m)
  final double z;  // Up (m)
  final double t;  // Time (s)

  const TrajectoryPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.t,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'z': z,
    't': t,
  };

  factory TrajectoryPoint.fromJson(Map<String, dynamic> json) => TrajectoryPoint(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    z: (json['z'] as num).toDouble(),
    t: (json['t'] as num).toDouble(),
  );
}

class ThrowStatistics {
  final double releaseSpeed;  // m/s
  final double range;         // m
  final double flightTime;    // s
  final double peakHeight;    // m
  final double releaseAngle;  // degrees
  final double releaseHeight; // m

  const ThrowStatistics({
    required this.releaseSpeed,
    required this.range,
    required this.flightTime,
    required this.peakHeight,
    required this.releaseAngle,
    required this.releaseHeight,
  });

  Map<String, dynamic> toJson() => {
    'releaseSpeed': releaseSpeed,
    'range': range,
    'flightTime': flightTime,
    'peakHeight': peakHeight,
    'releaseAngle': releaseAngle,
    'releaseHeight': releaseHeight,
  };

  factory ThrowStatistics.fromJson(Map<String, dynamic> json) => ThrowStatistics(
    releaseSpeed: (json['releaseSpeed'] as num).toDouble(),
    range: (json['range'] as num).toDouble(),
    flightTime: (json['flightTime'] as num).toDouble(),
    peakHeight: (json['peakHeight'] as num).toDouble(),
    releaseAngle: (json['releaseAngle'] as num).toDouble(),
    releaseHeight: (json['releaseHeight'] as num).toDouble(),
  );
}

class JavelinThrow {
  final String id;
  final String date;
  final String time;
  final double distance;
  final double releaseSpeed;
  final double angle;
  final double spin;
  final double flightTime;
  final List<SensorSample> sensorData; // Renamed from SensorData to SensorSample
  final List<TrajectoryPoint>? trajectoryPoints;
  final ThrowStatistics? throwStatistics;

  JavelinThrow({
    required this.id,
    required this.date,
    required this.time,
    required this.distance,
    required this.releaseSpeed,
    required this.angle,
    required this.spin,
    required this.flightTime,
    this.sensorData = const [],
    this.trajectoryPoints,
    this.throwStatistics,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'time': time,
    'distance': distance,
    'releaseSpeed': releaseSpeed,
    'angle': angle,
    'spin': spin,
    'flightTime': flightTime,
    // 'sensorData': sensorData.map((e) => e.toJson()).toList(), // Optional: might be too large
    'trajectoryPoints': trajectoryPoints?.map((e) => e.toJson()).toList(),
    'throwStatistics': throwStatistics?.toJson(),
  };

  factory JavelinThrow.fromJson(Map<String, dynamic> json) => JavelinThrow(
    id: json['id'] as String,
    date: json['date'] as String,
    time: json['time'] as String,
    distance: (json['distance'] as num).toDouble(),
    releaseSpeed: (json['releaseSpeed'] as num).toDouble(),
    angle: (json['angle'] as num).toDouble(),
    spin: (json['spin'] as num).toDouble(),
    flightTime: (json['flightTime'] as num).toDouble(),
    // sensorData: ... (load separately if needed)
    trajectoryPoints: (json['trajectoryPoints'] as List<dynamic>?)
        ?.map((e) => TrajectoryPoint.fromJson(e as Map<String, dynamic>))
        .toList(),
    throwStatistics: json['throwStatistics'] != null
        ? ThrowStatistics.fromJson(json['throwStatistics'] as Map<String, dynamic>)
        : null,
  );

  // Factory constructor for mock data
  factory JavelinThrow.mock({
    required String id,
    required String date,
    required String time,
    required double distance,
    List<SensorSample> sensorData = const [],
  }) {
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    return JavelinThrow(
      id: id,
      date: date,
      time: time,
      distance: distance,
      releaseSpeed: 25.0 + (random % 10) / 10,
      angle: 30.0 + (random % 5) / 10,
      spin: 400.0 + (random % 100),
      flightTime: 3.5 + (random % 10) / 100,
      sensorData: sensorData,
    );
  }
}
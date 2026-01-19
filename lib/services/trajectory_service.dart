import '../models/javelin_throw.dart';

/// Service for processing javelin throw trajectories
/// Note: This is a simple wrapper around TrajectoryAnalyzer
class TrajectoryService {
  /// Processes a throw with sensor data and returns updated throw with trajectory
  Future<JavelinThrow> processThrow(JavelinThrow throw_) async {
    if (throw_.sensorData.isEmpty) {
      return throw_;
    }

    try {
      // The TrajectoryAnalyzer.detectThrows already does the processing
      // This service can be used if you need additional processing
      // For now, it's a pass-through since TrajectoryAnalyzer is called directly
      return throw_;
    } catch (e) {
      return throw_;
    }
  }
}

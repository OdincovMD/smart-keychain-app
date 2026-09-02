abstract interface class SimulatorControls {
  Duration get latency;

  List<Duration> get latencyPresets;

  Stream<Duration> watchLatency();

  void setLatency(Duration latency);
}

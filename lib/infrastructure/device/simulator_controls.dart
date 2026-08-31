abstract interface class SimulatorControls {
  Duration get latency;

  Stream<Duration> watchLatency();

  void setLatency(Duration latency);
}

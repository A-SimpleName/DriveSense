class TrackingService {
  bool _tracking = false;

  void start() {
    _tracking = true;
    print("Tracking gestartet");
    // Hier GPS starten, Timer starten etc.
  }

  void stop() {
    _tracking = false;
    print("Tracking gestoppt");
  }

  bool get isTracking => _tracking;
}

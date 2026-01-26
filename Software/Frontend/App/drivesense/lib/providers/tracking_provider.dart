import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/tracking_service.dart';

class TrackingProvider with ChangeNotifier {
  final TrackingService _service = TrackingService();
  bool get tracking => _service.isTracking;

  void startTracking() {
    _service.start();
    notifyListeners();
  }

  void stopTracking() {
    _service.stop();
    notifyListeners();
  }
}
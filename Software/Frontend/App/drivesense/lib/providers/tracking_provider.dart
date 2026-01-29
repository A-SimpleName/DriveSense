import 'package:flutter/material.dart';
import '../services/location_service.dart';

class TrackingProvider extends ChangeNotifier {
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  Future<void> startTracking() async {
    await LocationService.startTracking();
    _isTracking = true;
    notifyListeners(); // UI informiert
  }

  Future<void> stopTracking() async {
    await LocationService.stopTracking();
    _isTracking = false;
    notifyListeners(); // UI informiert
  }
}

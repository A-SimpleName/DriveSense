import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

class LocationService {
  static bool _initialized = false;

  static Future<void> startTracking() async {
    if (_initialized) return;

    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      final coords = location.coords;
      print('${coords.latitude}, ${coords.longitude}');
    });

    final state = await bg.BackgroundGeolocation.ready(bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 10,
      stopOnTerminate: false,
      startOnBoot: true,
      foregroundService: true,
      notification: bg.Notification(
        title: 'Tracking aktiv',
        text: 'GPS läuft im Hintergrund',
      ),
    ));

    if (!state.enabled) {
      await bg.BackgroundGeolocation.start();
    }

    _initialized = true;
  }

  static Future<void> stopTracking() async {
    await bg.BackgroundGeolocation.stop();
    _initialized = false;
  }
}
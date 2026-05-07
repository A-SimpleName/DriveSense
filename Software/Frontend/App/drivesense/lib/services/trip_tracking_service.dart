import 'dart:async';
import 'dart:convert';
import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/active_trip.dart';
import 'package:drivesense/repository/active_trip_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

typedef TrackingUpdateCallback =
    void Function(
      Trackingpoint point,
      double distanceAdded,
      bool alreadyPersisted,
    );

class TripTrackingException implements Exception {
  final String message;

  const TripTrackingException(this.message);

  @override
  String toString() => message;
}

const Duration _minPointInterval = Duration(seconds: 3);
const double _minPointDistanceMeters = 25;
const int _foregroundServiceId = 4201;
const String _messageTypeKey = 'type';
const String _trackingPointMessage = 'trackingPoint';
const String _trackingErrorMessage = 'trackingError';
const String _emitCurrentPointCompleteMessage = 'emitCurrentPointComplete';
const String _commandKey = 'command';
const String _emitCurrentPointCommand = 'emitCurrentPoint';
const String _resyncCommand = 'resync';

bool get _supportsForegroundServiceTracking =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

@pragma('vm:entry-point')
void startTripTrackingForegroundTask() {
  FlutterForegroundTask.setTaskHandler(_TripTrackingTaskHandler());
}

/// GPS tracking service while a trip is active.
class TripTrackingService {
  StreamSubscription<Position>? _positionSubscription;
  Trackingpoint? _lastAcceptedPoint;
  bool _foregroundTrackingRequested = false;
  bool _foregroundCallbackRegistered = false;
  Completer<void>? _pendingEmitCurrentPoint;

  TrackingUpdateCallback? onTrackingUpdate;
  Function(String error)? onError;

  TripTrackingService() {
    if (_supportsForegroundServiceTracking) {
      FlutterForegroundTask.addTaskDataCallback(_handleForegroundTaskData);
      _foregroundCallbackRegistered = true;
    }
  }

  static void initializeForegroundTask() {
    if (!_supportsForegroundServiceTracking) {
      return;
    }

    FlutterForegroundTask.initCommunicationPort();
    _initForegroundTask();
  }

  static void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'drivesense_trip_tracking',
        channelName: 'DriveSense Trip Tracking',
        channelDescription:
            'Keeps DriveSense recording location points during active trips.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
        allowAutoRestart: true,
        stopWithTask: false,
      ),
    );
  }

  bool get isTracking =>
      _positionSubscription != null || _foregroundTrackingRequested;

  void seedLastAcceptedPoint(Trackingpoint? point) {
    _lastAcceptedPoint = point;
  }

  Future<void> startTracking() async {
    await _ensureTrackingPermissions();

    if (_supportsForegroundServiceTracking) {
      await _startForegroundTaskTracking();
      return;
    }

    if (_positionSubscription != null) {
      debugPrint('Tracking is already running');
      return;
    }

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: _trackingLocationSettings(),
        ).listen(
          _handlePositionUpdate,
          onError: (e) {
            debugPrint('GPS STREAM ERROR: $e');
            onError?.call(e.toString());
          },
          onDone: () {
            debugPrint('GPS STREAM DONE');
          },
        );

    unawaited(emitCurrentPoint());
  }

  Future<void> _startForegroundTaskTracking() async {
    _initForegroundTask();

    if (await FlutterForegroundTask.isRunningService) {
      _foregroundTrackingRequested = true;
      FlutterForegroundTask.sendDataToTask({_commandKey: _resyncCommand});
      return;
    }

    final ServiceRequestResult result = await FlutterForegroundTask.startService(
      serviceId: _foregroundServiceId,
      serviceTypes: const [ForegroundServiceTypes.location],
      notificationTitle: 'DriveSense zeichnet eine Fahrt auf',
      notificationText: 'Standorttracking ist aktiv.',
      notificationInitialRoute: 'MainPage',
      callback: startTripTrackingForegroundTask,
    );

    if (result is ServiceRequestFailure) {
      _foregroundTrackingRequested = false;
      final String message =
          'Tracking-Dienst konnte nicht gestartet werden: ${result.error}';
      debugPrint(message);
      onError?.call(message);
      throw TripTrackingException(message);
    }

    _foregroundTrackingRequested = true;
  }

  Future<void> stopTracking() async {
    if (_supportsForegroundServiceTracking) {
      _foregroundTrackingRequested = false;
      _lastAcceptedPoint = null;
      _completePendingEmitCurrentPoint();

      if (await FlutterForegroundTask.isRunningService) {
        final ServiceRequestResult result =
            await FlutterForegroundTask.stopService();
        if (result is ServiceRequestFailure) {
          debugPrint('Foreground tracking stop failed: ${result.error}');
        }
      }
      return;
    }

    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastAcceptedPoint = null;
  }

  Future<void> emitCurrentPoint() async {
    if (_supportsForegroundServiceTracking) {
      if (!await FlutterForegroundTask.isRunningService) {
        return;
      }

      _completePendingEmitCurrentPoint();
      final Completer<void> completer = Completer<void>();
      _pendingEmitCurrentPoint = completer;
      FlutterForegroundTask.sendDataToTask({
        _commandKey: _emitCurrentPointCommand,
      });

      try {
        await completer.future.timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('Foreground current GPS point failed: $e');
      } finally {
        if (identical(_pendingEmitCurrentPoint, completer)) {
          _pendingEmitCurrentPoint = null;
        }
      }
      return;
    }

    try {
      final Position currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: _trackingLocationSettings(),
      ).timeout(const Duration(seconds: 5));
      _handlePositionUpdate(currentPosition);
    } catch (e) {
      debugPrint('Current GPS point failed: $e');
    }
  }

  void _handlePositionUpdate(Position position) {
    final Trackingpoint trackingpoint = _positionToTrackingPoint(position);

    if (!_shouldAcceptPoint(trackingpoint)) {
      debugPrint(
        'Point rejected: acc=${trackingpoint.accuracy}, spd=${trackingpoint.speed}',
      );
      return;
    }

    double distanceAdded = 0;
    if (_lastAcceptedPoint != null) {
      distanceAdded = Geolocator.distanceBetween(
        _lastAcceptedPoint!.latitude,
        _lastAcceptedPoint!.longitude,
        trackingpoint.latitude,
        trackingpoint.longitude,
      );
    }

    _lastAcceptedPoint = trackingpoint;
    onTrackingUpdate?.call(trackingpoint, distanceAdded, false);
  }

  bool _shouldAcceptPoint(Trackingpoint trackingpoint) {
    return _shouldAcceptTrackingPoint(trackingpoint, _lastAcceptedPoint);
  }

  void _handleForegroundTaskData(Object data) {
    final Map<String, dynamic>? message = _stringKeyedMap(data);
    if (message == null) {
      return;
    }

    switch (message[_messageTypeKey]) {
      case _trackingPointMessage:
        final Map<String, dynamic>? pointJson = _stringKeyedMap(
          message['point'],
        );
        if (pointJson == null) {
          return;
        }

        final Trackingpoint point = Trackingpoint.fromJson(pointJson);
        final double distanceAdded = _asDouble(message['distanceAdded']);
        _lastAcceptedPoint = point;
        onTrackingUpdate?.call(point, distanceAdded, true);
      case _trackingErrorMessage:
        final String error = message['error']?.toString() ?? 'Unknown error';
        debugPrint('Foreground GPS error: $error');
        onError?.call(error);
      case _emitCurrentPointCompleteMessage:
        _completePendingEmitCurrentPoint();
    }
  }

  void _completePendingEmitCurrentPoint() {
    final Completer<void>? completer = _pendingEmitCurrentPoint;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _pendingEmitCurrentPoint = null;
  }

  Future<void> _ensureTrackingPermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const TripTrackingException(
        'Standortdienste sind deaktiviert. Bitte GPS aktivieren.',
      );
    }

    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    if (locationPermission == LocationPermission.denied) {
      throw const TripTrackingException(
        'Standortberechtigung wurde abgelehnt.',
      );
    }

    if (locationPermission == LocationPermission.deniedForever) {
      throw const TripTrackingException(
        'Standortberechtigung ist dauerhaft abgelehnt. Bitte in den App-Einstellungen erlauben.',
      );
    }

    if (_supportsForegroundServiceTracking) {
      await _requestNotificationPermission();
      await _requestBackgroundLocationPermission();
      await _requestBatteryOptimizationExemption();
    }
  }

  Future<void> _requestNotificationPermission() async {
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  Future<void> _requestBackgroundLocationPermission() async {
    final permissions.PermissionStatus status =
        await permissions.Permission.locationAlways.status;
    if (status.isGranted) {
      return;
    }

    final permissions.PermissionStatus requested =
        await permissions.Permission.locationAlways.request();
    if (!requested.isGranted) {
      throw const TripTrackingException(
        'Bitte Standortzugriff "Immer erlauben", damit Fahrten auch bei geschlossener App aufgezeichnet werden.',
      );
    }
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    } catch (e) {
      debugPrint('Battery optimization exemption request failed: $e');
    }
  }

  void dispose() {
    if (_foregroundCallbackRegistered) {
      FlutterForegroundTask.removeTaskDataCallback(_handleForegroundTaskData);
      _foregroundCallbackRegistered = false;
    }
    _positionSubscription?.cancel();
  }
}

class _TripTrackingTaskHandler extends TaskHandler {
  final ActiveTripRepository _activeTripRepository = ActiveTripRepository();
  StreamSubscription<Position>? _positionSubscription;
  Trackingpoint? _lastAcceptedPoint;
  Future<void> _pendingPositionWrite = Future<void>.value();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _seedLastAcceptedPoint();
    await _startLocationStream();
    await _emitCurrentPoint();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_verifyActiveTripStillExists());
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void onReceiveData(Object data) {
    final Map<String, dynamic>? command = _stringKeyedMap(data);
    if (command == null) {
      return;
    }

    switch (command[_commandKey]) {
      case _emitCurrentPointCommand:
        unawaited(_emitCurrentPoint(sendCompletion: true));
      case _resyncCommand:
        unawaited(_seedLastAcceptedPoint());
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('MainPage');
  }

  Future<void> _startLocationStream() async {
    if (_positionSubscription != null) {
      return;
    }

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: _trackingLocationSettings(),
        ).listen(
          (Position position) {
            unawaited(_queuePosition(position));
          },
          onError: (Object e) {
            _sendError('GPS STREAM ERROR: $e');
          },
          onDone: () {
            _sendError('GPS STREAM DONE');
          },
        );
  }

  Future<void> _emitCurrentPoint({bool sendCompletion = false}) async {
    try {
      final Position currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: _trackingLocationSettings(),
      ).timeout(const Duration(seconds: 8));
      await _queuePosition(currentPosition);
    } catch (e) {
      _sendError('Current GPS point failed: $e');
    } finally {
      if (sendCompletion) {
        FlutterForegroundTask.sendDataToMain({
          _messageTypeKey: _emitCurrentPointCompleteMessage,
        });
      }
    }
  }

  Future<void> _queuePosition(Position position) {
    _pendingPositionWrite = _pendingPositionWrite
        .catchError((Object e) {
          _sendError('Previous tracking update failed: $e');
        })
        .then((_) {
          return _persistPosition(position);
        });
    return _pendingPositionWrite;
  }

  Future<void> _persistPosition(Position position) async {
    final ActiveTrip? activeTrip = await _activeTripRepository.getActive();
    if (activeTrip == null) {
      await _stopService();
      return;
    }

    final List<Trackingpoint> trackingPoints = _decodeTrackingPoints(
      activeTrip.trackingPointsJson,
    );
    _lastAcceptedPoint ??=
        _decodeTrackingPoint(activeTrip.lastAcceptedPointJson) ??
        (trackingPoints.isNotEmpty ? trackingPoints.last : null);

    final Trackingpoint trackingpoint = _positionToTrackingPoint(position);
    if (!_shouldAcceptTrackingPoint(trackingpoint, _lastAcceptedPoint)) {
      return;
    }

    if (_containsTrackingPoint(trackingPoints, trackingpoint)) {
      return;
    }

    double distanceAdded = 0;
    if (_lastAcceptedPoint != null) {
      distanceAdded = Geolocator.distanceBetween(
        _lastAcceptedPoint!.latitude,
        _lastAcceptedPoint!.longitude,
        trackingpoint.latitude,
        trackingpoint.longitude,
      );
    }

    trackingPoints.add(trackingpoint);
    activeTrip.distanceMeters += distanceAdded;
    activeTrip.trackingPointsJson = jsonEncode(
      trackingPoints.map((Trackingpoint tp) => tp.toJson()).toList(),
    );
    activeTrip.lastAcceptedPointJson = jsonEncode(trackingpoint.toJson());
    activeTrip.updatedAt = DateTime.now();
    await _activeTripRepository.update(activeTrip);

    _lastAcceptedPoint = trackingpoint;
    _sendTrackingUpdate(trackingpoint, distanceAdded);
    _updateNotification(activeTrip);
  }

  Future<void> _seedLastAcceptedPoint() async {
    final ActiveTrip? activeTrip = await _activeTripRepository.getActive();
    if (activeTrip == null) {
      return;
    }

    final List<Trackingpoint> trackingPoints = _decodeTrackingPoints(
      activeTrip.trackingPointsJson,
    );
    _lastAcceptedPoint =
        _decodeTrackingPoint(activeTrip.lastAcceptedPointJson) ??
        (trackingPoints.isNotEmpty ? trackingPoints.last : null);
    _updateNotification(activeTrip);
  }

  Future<void> _verifyActiveTripStillExists() async {
    final ActiveTrip? activeTrip = await _activeTripRepository.getActive();
    if (activeTrip == null) {
      await _stopService();
      return;
    }

    _updateNotification(activeTrip);
  }

  Future<void> _stopService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  void _sendTrackingUpdate(Trackingpoint point, double distanceAdded) {
    FlutterForegroundTask.sendDataToMain({
      _messageTypeKey: _trackingPointMessage,
      'point': point.toJson(),
      'distanceAdded': distanceAdded,
    });
  }

  void _sendError(String error) {
    debugPrint(error);
    FlutterForegroundTask.sendDataToMain({
      _messageTypeKey: _trackingErrorMessage,
      'error': error,
    });
  }

  void _updateNotification(ActiveTrip activeTrip) {
    final double distanceKm = activeTrip.distanceMeters / 1000;
    unawaited(
      FlutterForegroundTask.updateService(
        notificationTitle: 'DriveSense zeichnet eine Fahrt auf',
        notificationText:
            '${distanceKm.toStringAsFixed(2)} km, ${_decodeTrackingPoints(activeTrip.trackingPointsJson).length} Punkte',
      ),
    );
  }
}

LocationSettings _trackingLocationSettings() {
  if (_supportsForegroundServiceTracking) {
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      intervalDuration: _minPointInterval,
    );
  }

  return const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0,
  );
}

bool _shouldAcceptTrackingPoint(
  Trackingpoint trackingpoint,
  Trackingpoint? lastAcceptedPoint,
) {
  final double accuracy = trackingpoint.accuracy;
  if (accuracy > 25) {
    return false;
  }

  if (lastAcceptedPoint == null) {
    return true;
  }

  final double distance = Geolocator.distanceBetween(
    lastAcceptedPoint.latitude,
    lastAcceptedPoint.longitude,
    trackingpoint.latitude,
    trackingpoint.longitude,
  );

  final Duration elapsed = trackingpoint.timestamp.difference(
    lastAcceptedPoint.timestamp,
  );

  return distance >= _minPointDistanceMeters || elapsed >= _minPointInterval;
}

Trackingpoint _positionToTrackingPoint(Position position) {
  return Trackingpoint(
    id: 0,
    tripId: 0,
    latitude: position.latitude,
    longitude: position.longitude,
    accuracy: position.accuracy,
    speed: position.speed,
    bearing: position.heading,
    timestamp: position.timestamp,
  );
}

List<Trackingpoint> _decodeTrackingPoints(String value) {
  try {
    final List<dynamic> raw = jsonDecode(value) as List<dynamic>;
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Trackingpoint.fromJson)
        .toList();
  } catch (_) {
    return <Trackingpoint>[];
  }
}

Trackingpoint? _decodeTrackingPoint(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  try {
    return Trackingpoint.fromJson(jsonDecode(value) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

bool _containsTrackingPoint(
  List<Trackingpoint> trackingPoints,
  Trackingpoint point,
) {
  return trackingPoints.any((Trackingpoint existing) {
    return existing.timestamp == point.timestamp &&
        existing.latitude == point.latitude &&
        existing.longitude == point.longitude;
  });
}

Map<String, dynamic>? _stringKeyedMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map<String, dynamic>(
      (dynamic key, dynamic value) => MapEntry<String, dynamic>(
        key.toString(),
        value,
      ),
    );
  }

  return null;
}

double _asDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

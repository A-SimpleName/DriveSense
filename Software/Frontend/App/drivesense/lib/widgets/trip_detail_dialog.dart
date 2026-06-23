import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/trip_detailed.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/trip_service.dart';
import 'package:drivesense/widgets/protocol_trip_fields.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

Future<void> showTripDetailDialog(
  BuildContext context,
  TripSummary trip, {
  TripDetailed? initialDetail,
  Future<TripDetailed>? refreshDetail,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return _TripDetailDialog(
        trip: trip,
        initialDetail: initialDetail,
        refreshDetail: refreshDetail,
      );
    },
  );
}

class _TripDetailDialog extends StatefulWidget {
  final TripSummary trip;
  final TripDetailed? initialDetail;
  final Future<TripDetailed>? refreshDetail;

  const _TripDetailDialog({
    required this.trip,
    required this.initialDetail,
    required this.refreshDetail,
  });

  @override
  State<_TripDetailDialog> createState() => _TripDetailDialogState();
}

class _TripDetailDialogState extends State<_TripDetailDialog> {
  late TripDetailed _detail;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _detail =
        widget.initialDetail ??
        TripDetailed(
          summary: widget.trip,
          trackingpoints: const <Trackingpoint>[],
        );
    _loadDetail();
  }

  void _loadDetail() {
    final Future<TripDetailed> detailFuture =
        widget.refreshDetail ??
        TripService().fetchTripDetail(
          widget.trip.id,
          fallbackSummary: widget.trip,
        );

    unawaited(
      detailFuture
          .then<void>((TripDetailed detail) {
            if (!mounted) {
              return;
            }

            setState(() {
              _detail = detail;
              _isLoading = false;
              _loadError = null;
            });
          })
          .catchError((Object error) {
            if (!mounted) {
              return;
            }

            setState(() {
              _isLoading = false;
              _loadError =
                  'Serverdaten konnten nicht aktualisiert werden. Lokale Daten werden angezeigt.';
            });
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double dialogWidth = math.min(
      math.max(screenSize.width - 48, 280.0),
      680.0,
    );
    final double dialogHeight = math.min(
      math.max(screenSize.height * 0.78, 360.0),
      740.0,
    );

    return AlertDialog(
      title: const Text('Fahrtdetails'),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            if (_loadError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _loadError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ..._detailRows(_detail.summary),
                    const SizedBox(height: 16),
                    Text(
                      'Karte',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _TripMapPreview(points: _detail.trackingpoints),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schliessen'),
        ),
      ],
    );
  }

  List<Widget> _detailRows(TripSummary summary) {
    final List<ProtocolTripField> fields = protocolTripFieldsForRole(
      RuntimeStore.getActiveProfileRole(),
    );

    return fields
        .map(
          (ProtocolTripField field) =>
              _DetailRow(label: field.detailLabel, value: field.value(summary)),
        )
        .toList();
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _TripMapPreview extends StatefulWidget {
  final List<Trackingpoint> points;

  const _TripMapPreview({required this.points});

  @override
  State<_TripMapPreview> createState() => _TripMapPreviewState();
}

class _TripMapPreviewState extends State<_TripMapPreview> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  late Future<List<LatLng>> _routeFuture;

  @override
  void initState() {
    super.initState();
    _routeFuture = _loadRoutePoints(widget.points);
  }

  @override
  void didUpdateWidget(_TripMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.points, widget.points)) {
      _routeFuture = _loadRoutePoints(widget.points);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String apiKey = _googleMapsApiKey();
    if (apiKey.isEmpty) {
      return const _MapMessage(
        message: 'GOOGLE_MAPS_API_KEY fehlt in der .env Datei.',
      );
    }

    final List<Trackingpoint> validPoints = widget.points
        .where(_isValidPoint)
        .toList();
    if (validPoints.isEmpty) {
      return const _MapMessage(
        message: 'Keine Positionsdaten fuer diese Fahrt vorhanden.',
      );
    }
    if (!_supportsEmbeddedGoogleMap) {
      return _InteractiveStaticMapPreview(points: validPoints, apiKey: apiKey);
    }

    return FutureBuilder<List<LatLng>>(
      future: _routeFuture,
      initialData: _sampleRoutePoints(validPoints).map(_latLng).toList(),
      builder: (BuildContext context, AsyncSnapshot<List<LatLng>> snapshot) {
        final List<LatLng> routePoints =
            snapshot.data ??
            _sampleRoutePoints(validPoints).map(_latLng).toList();
        final CameraPosition initialCameraPosition = CameraPosition(
          target: routePoints.first,
          zoom: routePoints.length == 1 ? 15 : 12,
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: <Widget>[
                SizedBox(
                  height: 260,
                  child: GoogleMap(
                    initialCameraPosition: initialCameraPosition,
                    markers: _markersFor(routePoints),
                    polylines: _polylinesFor(routePoints),
                    compassEnabled: true,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<EagerGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                      _fitRoute(routePoints, controller);
                    },
                  ),
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Positioned(top: 8, right: 8, child: _MapLoadingBadge()),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<LatLng>> _loadRoutePoints(List<Trackingpoint> points) async {
    final List<Trackingpoint> validPoints = points
        .where(_isValidPoint)
        .toList();
    final List<LatLng> fallbackPoints = _sampleRoutePoints(
      validPoints,
    ).map(_latLng).toList();
    if (fallbackPoints.length < 2) {
      return fallbackPoints;
    }

    final String apiKey = _googleMapsApiKey();
    if (apiKey.isEmpty) {
      return fallbackPoints;
    }

    final List<LatLng> snappedPoints = await _snapToRoads(
      _sampleSnapInputPoints(validPoints),
      apiKey,
    );
    return snappedPoints.length >= 2 ? snappedPoints : fallbackPoints;
  }

  Future<List<LatLng>> _snapToRoads(
    List<Trackingpoint> points,
    String apiKey,
  ) async {
    const int maxBatchSize = 100;
    final List<LatLng> snappedPoints = <LatLng>[];

    for (int start = 0; start < points.length; start += maxBatchSize - 1) {
      final int end = math.min(start + maxBatchSize, points.length);
      final List<Trackingpoint> batch = points.sublist(start, end);
      if (batch.length < 2) {
        break;
      }

      final Uri uri =
          Uri.https('roads.googleapis.com', '/v1/snapToRoads', <String, String>{
            'path': batch.map(_trackingpointLatLng).join('|'),
            'interpolate': 'true',
            'key': apiKey,
          });

      try {
        final http.Response response = await http
            .get(uri, headers: _roadsApiHeaders())
            .timeout(const Duration(seconds: 8));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return snappedPoints;
        }

        final dynamic decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          return snappedPoints;
        }

        final dynamic rawPoints = decoded['snappedPoints'];
        if (rawPoints is! List) {
          return snappedPoints;
        }

        final List<LatLng> batchPoints = rawPoints
            .whereType<Map<String, dynamic>>()
            .map(_snappedPointLatLng)
            .whereType<LatLng>()
            .toList();
        if (batchPoints.isEmpty) {
          return snappedPoints;
        }

        if (snappedPoints.isNotEmpty &&
            _samePosition(snappedPoints.last, batchPoints.first)) {
          snappedPoints.addAll(batchPoints.skip(1));
        } else {
          snappedPoints.addAll(batchPoints);
        }
      } catch (_) {
        return snappedPoints;
      }

      if (end == points.length) {
        break;
      }
    }

    return snappedPoints;
  }

  LatLng? _snappedPointLatLng(Map<String, dynamic> point) {
    final dynamic location = point['location'];
    if (location is! Map<String, dynamic>) {
      return null;
    }

    final double? latitude = _asDouble(location['latitude']);
    final double? longitude = _asDouble(location['longitude']);
    if (latitude == null || longitude == null) {
      return null;
    }

    return LatLng(latitude, longitude);
  }

  double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value == null) {
      return null;
    }
    return double.tryParse(value.toString());
  }

  bool _samePosition(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.000001 &&
        (a.longitude - b.longitude).abs() < 0.000001;
  }

  List<Trackingpoint> _sampleSnapInputPoints(List<Trackingpoint> points) {
    const int maxSnapInputPoints = 500;
    if (points.length <= maxSnapInputPoints) {
      return points;
    }

    final double step = (points.length - 1) / (maxSnapInputPoints - 1);
    final List<Trackingpoint> sampled = <Trackingpoint>[];
    int? previousIndex;

    for (int i = 0; i < maxSnapInputPoints; i++) {
      final int index = (i * step).round().clamp(0, points.length - 1).toInt();
      if (index == previousIndex) {
        continue;
      }
      sampled.add(points[index]);
      previousIndex = index;
    }

    return sampled;
  }

  String _trackingpointLatLng(Trackingpoint point) {
    return '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';
  }

  Map<String, String> _roadsApiHeaders() {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const <String, String>{};
    }

    final String packageName = _androidPackageName();
    final String certSha1 = _androidCertSha1();
    if (packageName.isEmpty || certSha1.isEmpty) {
      return const <String, String>{};
    }

    return <String, String>{
      'X-Android-Package': packageName,
      'X-Android-Cert': certSha1,
    };
  }

  String _androidPackageName() {
    const String dartDefineValue = String.fromEnvironment(
      'GOOGLE_MAPS_ANDROID_PACKAGE',
    );
    final String dotenvValue =
        dotenv.env['GOOGLE_MAPS_ANDROID_PACKAGE']?.trim() ?? '';
    if (dotenvValue.isNotEmpty) {
      return dotenvValue;
    }
    if (dartDefineValue.trim().isNotEmpty) {
      return dartDefineValue.trim();
    }
    return 'at.ac.htlperg.drivesense';
  }

  String _androidCertSha1() {
    const String dartDefineValue = String.fromEnvironment(
      'GOOGLE_MAPS_ANDROID_CERT_SHA1',
    );
    final String dotenvValue =
        dotenv.env['GOOGLE_MAPS_ANDROID_CERT_SHA1']?.trim() ?? '';
    final String value = dotenvValue.isNotEmpty
        ? dotenvValue
        : dartDefineValue.trim().isNotEmpty
        ? dartDefineValue
        : 'A3:E2:13:93:75:8C:32:E2:F6:D9:D1:D7:16:F3:53:2D:18:DD:ED:25';
    return value.replaceAll(':', '').trim().toUpperCase();
  }

  String _googleMapsApiKey() {
    final String dotenvValue = dotenv.env['GOOGLE_MAPS_API_KEY']?.trim() ?? '';
    if (dotenvValue.isNotEmpty) {
      return dotenvValue;
    }

    const String dartDefineValue = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
    );
    return dartDefineValue.trim();
  }

  static bool _isValidPoint(Trackingpoint point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }

  Set<Marker> _markersFor(List<LatLng> routePoints) {
    final Set<Marker> markers = <Marker>{
      Marker(
        markerId: const MarkerId('start'),
        position: routePoints.first,
        infoWindow: const InfoWindow(title: 'Start'),
      ),
    };

    if (routePoints.length > 1) {
      markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: routePoints.last,
          infoWindow: const InfoWindow(title: 'Ziel'),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _polylinesFor(List<LatLng> routePoints) {
    if (routePoints.length < 2) {
      return <Polyline>{};
    }

    return <Polyline>{
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: const Color(0xFF673AB7),
        width: 5,
      ),
    };
  }

  bool get _supportsEmbeddedGoogleMap {
    return defaultTargetPlatform == TargetPlatform.android;
  }

  Future<void> _fitRoute(
    List<LatLng> routePoints,
    GoogleMapController controller,
  ) async {
    if (routePoints.length < 2) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsFor(routePoints), 48),
    );
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final LatLng point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    if (minLat == maxLat) {
      minLat -= 0.001;
      maxLat += 0.001;
    }
    if (minLng == maxLng) {
      minLng -= 0.001;
      maxLng += 0.001;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  static List<Trackingpoint> _sampleRoutePoints(List<Trackingpoint> points) {
    const int maxPoints = 80;
    if (points.length <= maxPoints) {
      return points;
    }

    final double step = (points.length - 1) / (maxPoints - 1);
    final List<Trackingpoint> sampled = <Trackingpoint>[];
    int? previousIndex;

    for (int i = 0; i < maxPoints; i++) {
      final int index = (i * step).round().clamp(0, points.length - 1).toInt();
      if (index == previousIndex) {
        continue;
      }
      sampled.add(points[index]);
      previousIndex = index;
    }

    return sampled;
  }

  static LatLng _latLng(Trackingpoint point) {
    return LatLng(point.latitude, point.longitude);
  }
}

class _InteractiveStaticMapPreview extends StatelessWidget {
  final List<Trackingpoint> points;
  final String apiKey;

  const _InteractiveStaticMapPreview({
    required this.points,
    required this.apiKey,
  });

  @override
  Widget build(BuildContext context) {
    final Uri mapUri = _buildStaticMapUri(points, apiKey);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: SizedBox(
          height: 260,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image.network(
              mapUri.toString(),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder:
                  (
                    BuildContext context,
                    Widget child,
                    ImageChunkEvent? loadingProgress,
                  ) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return const _MapMessage(
                      message: 'Karte konnte nicht geladen werden.',
                    );
                  },
            ),
          ),
        ),
      ),
    );
  }

  static Uri _buildStaticMapUri(List<Trackingpoint> points, String apiKey) {
    final List<Trackingpoint> routePoints = _sampleRoutePoints(points);
    final Map<String, dynamic> queryParameters = <String, dynamic>{
      'size': '640x360',
      'scale': '2',
      'maptype': 'roadmap',
      'key': apiKey,
      'markers': <String>[
        'color:green|label:S|${_latLng(points.first)}',
        'color:red|label:Z|${_latLng(points.last)}',
      ],
    };

    if (routePoints.length > 1) {
      queryParameters['path'] = <String>[
        'color:0x673AB7ff',
        'weight:5',
        ...routePoints.map(_latLng),
      ].join('|');
    }

    return Uri.https(
      'maps.googleapis.com',
      '/maps/api/staticmap',
      queryParameters,
    );
  }

  static List<Trackingpoint> _sampleRoutePoints(List<Trackingpoint> points) {
    const int maxPoints = 80;
    if (points.length <= maxPoints) {
      return points;
    }

    final double step = (points.length - 1) / (maxPoints - 1);
    final List<Trackingpoint> sampled = <Trackingpoint>[];
    int? previousIndex;

    for (int i = 0; i < maxPoints; i++) {
      final int index = (i * step).round().clamp(0, points.length - 1).toInt();
      if (index == previousIndex) {
        continue;
      }
      sampled.add(points[index]);
      previousIndex = index;
    }

    return sampled;
  }

  static String _latLng(Trackingpoint point) {
    return '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';
  }
}

class _MapLoadingBadge extends StatelessWidget {
  const _MapLoadingBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Roads API'),
          ],
        ),
      ),
    );
  }
}

class _MapMessage extends StatelessWidget {
  final String message;

  const _MapMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}

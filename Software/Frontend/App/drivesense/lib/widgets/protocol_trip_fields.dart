import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/runtime_store.dart';

class ProtocolTripField {
  final String header;
  final double width;
  final String Function(TripSummary trip) value;

  const ProtocolTripField({
    required this.header,
    required this.width,
    required this.value,
  });

  String get detailLabel => header.replaceAll('\n', ' ');
}

List<ProtocolTripField> protocolTripFieldsForRole(String role) {
  switch (normalizeProtocolRole(role)) {
    case 'FAHRSCHUELER':
      return <ProtocolTripField>[
        ProtocolTripField(
          header: 'Datum',
          width: 100,
          value: (TripSummary trip) => formatProtocolTripDate(trip.startTime),
        ),
        ProtocolTripField(
          header: 'gefahrene\nkm',
          width: 100,
          value: (TripSummary trip) => formatProtocolDistance(trip.distanceKm),
        ),
        ProtocolTripField(
          header: 'km-Stand\nvon',
          width: 105,
          value: (TripSummary trip) => formatProtocolMileage(trip.startMileage),
        ),
        ProtocolTripField(
          header: 'km-Stand\nbis',
          width: 105,
          value: (TripSummary trip) => formatProtocolMileage(trip.endMileage),
        ),
        ProtocolTripField(
          header: 'KFZ-\nKennzeichen',
          width: 125,
          value: formatProtocolVehicleLicensePlate,
        ),
        ProtocolTripField(
          header: 'Tageszeit',
          width: 90,
          value: (TripSummary trip) => formatProtocolClockTime(trip.startTime),
        ),
        ProtocolTripField(
          header: 'Fahrstrecke /\nZiel',
          width: 190,
          value: formatProtocolRoute,
        ),
        ProtocolTripField(
          header: 'Strassenzustand /\nWitterung',
          width: 165,
          value: (TripSummary trip) =>
              formatProtocolText(trip.roadSurfaceConditions),
        ),
        ProtocolTripField(
          header: 'Unterschrift\nBegleiter',
          width: 130,
          value: (_) => '-',
        ),
        ProtocolTripField(
          header: 'Unterschrift\nBewerber',
          width: 130,
          value: (_) => '-',
        ),
      ];
    case 'BERUFSFAHRER':
      return <ProtocolTripField>[
        ProtocolTripField(
          header: 'Datum',
          width: 100,
          value: (TripSummary trip) => formatProtocolTripDate(trip.startTime),
        ),
        ProtocolTripField(
          header: 'Uhrzeit',
          width: 90,
          value: (TripSummary trip) => formatProtocolClockTime(trip.startTime),
        ),
        ProtocolTripField(
          header: 'Start',
          width: 145,
          value: (TripSummary trip) => formatProtocolText(trip.startPoint),
        ),
        ProtocolTripField(
          header: 'Wendepunkt',
          width: 145,
          value: (TripSummary trip) => formatProtocolText(trip.furthestPoint),
        ),
        ProtocolTripField(
          header: 'Ziel',
          width: 145,
          value: (TripSummary trip) => formatProtocolText(trip.endPoint),
        ),
        ProtocolTripField(
          header: 'km-Start',
          width: 100,
          value: (TripSummary trip) => formatProtocolMileage(trip.startMileage),
        ),
        ProtocolTripField(
          header: 'km-Ende',
          width: 100,
          value: (TripSummary trip) => formatProtocolMileage(trip.endMileage),
        ),
        ProtocolTripField(
          header: 'Strecke',
          width: 100,
          value: (TripSummary trip) => formatProtocolDistance(trip.distanceKm),
        ),
        ProtocolTripField(
          header: 'KFZ Kennzeichen',
          width: 130,
          value: formatProtocolVehicleLicensePlate,
        ),
        ProtocolTripField(
          header: 'Typ / Zweck',
          width: 150,
          value: (TripSummary trip) => formatProtocolText(trip.type),
        ),
      ];
    case 'PRIVAT':
    default:
      return <ProtocolTripField>[
        ProtocolTripField(
          header: 'Datum',
          width: 100,
          value: (TripSummary trip) => formatProtocolTripDate(trip.startTime),
        ),
        ProtocolTripField(
          header: 'Start',
          width: 150,
          value: (TripSummary trip) => formatProtocolText(trip.startPoint),
        ),
        ProtocolTripField(
          header: 'Wendepunkt',
          width: 150,
          value: (TripSummary trip) => formatProtocolText(trip.furthestPoint),
        ),
        ProtocolTripField(
          header: 'Ziel',
          width: 150,
          value: (TripSummary trip) => formatProtocolText(trip.endPoint),
        ),
        ProtocolTripField(
          header: 'km-Start',
          width: 100,
          value: (TripSummary trip) => formatProtocolMileage(trip.startMileage),
        ),
        ProtocolTripField(
          header: 'km-Ende',
          width: 100,
          value: (TripSummary trip) => formatProtocolMileage(trip.endMileage),
        ),
        ProtocolTripField(
          header: 'Strecke',
          width: 100,
          value: (TripSummary trip) => formatProtocolDistance(trip.distanceKm),
        ),
        ProtocolTripField(
          header: 'KFZ Kennzeichen',
          width: 130,
          value: formatProtocolVehicleLicensePlate,
        ),
      ];
  }
}

String normalizeProtocolRole(String role) {
  final String normalized = role.trim().toUpperCase().replaceAll(
    '\u00dc',
    'UE',
  );

  switch (normalized) {
    case 'FAHRSCHUELER':
    case 'FAHRSCHULER':
      return 'FAHRSCHUELER';
    case 'BERUFSFAHRER':
      return 'BERUFSFAHRER';
    case 'PRIVAT':
    default:
      return 'PRIVAT';
  }
}

String formatProtocolTripDate(DateTime dt) {
  return '${dt.day}.${dt.month}.${dt.year}';
}

String formatProtocolClockTime(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String formatProtocolDateTime(DateTime? dt) {
  if (dt == null) {
    return '-';
  }
  return '${formatProtocolTripDate(dt)} ${formatProtocolClockTime(dt)}';
}

String formatProtocolDistance(double distanceKm) {
  return '${distanceKm.toStringAsFixed(2)} km';
}

String formatProtocolMileage(int mileage) {
  return mileage >= 0 ? mileage.toString() : '-';
}

String formatProtocolText(String? value) {
  final String text = (value ?? '').trim();
  final String normalized = text.toLowerCase();
  if (normalized == 'undefined' ||
      normalized == 'null' ||
      normalized == 'unbekannt') {
    return '-';
  }
  return text.isNotEmpty ? text : '-';
}

String formatProtocolRoute(TripSummary trip) {
  final List<String> routePoints =
      <String>[
        trip.startPoint ?? '',
        trip.furthestPoint ?? '',
        trip.endPoint ?? '',
      ].map((String value) => value.trim()).where((String value) {
        final String normalized = value.toLowerCase();
        return value.isNotEmpty &&
            normalized != 'undefined' &&
            normalized != 'null' &&
            normalized != 'unbekannt';
      }).toList();

  if (routePoints.isNotEmpty) {
    return routePoints.join(' -> ');
  }

  final String type = (trip.type ?? '').trim();
  return formatProtocolText(type);
}

String formatProtocolVehicleLicensePlate(TripSummary trip) {
  final String licensePlate = (trip.vehicleLicensePlate ?? '').trim();
  final String normalized = licensePlate.toLowerCase();
  if (licensePlate.isNotEmpty &&
      normalized != 'undefined' &&
      normalized != 'null' &&
      normalized != 'unbekannt') {
    return licensePlate;
  }

  for (final vehicle in RuntimeStore.vehicles) {
    if (vehicle.id == trip.vehicleId) {
      return vehicle.licensePlate;
    }
  }

  return '-';
}

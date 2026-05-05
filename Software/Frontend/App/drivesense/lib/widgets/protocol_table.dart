import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:flutter/material.dart';

class ProtocolTable extends StatelessWidget {
  const ProtocolTable({super.key});

  @override
  Widget build(BuildContext context) {
    final List<TripSummary> trips = RuntimeStore.trips;

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 700),
            child: Table(
              border: TableBorder.all(color: Colors.black, width: 1),
              children: <TableRow>[
                TableRow(
                  key: const ValueKey('headerRow'),
                  children: <Widget>[
                    _headerCell('Startzeit'),
                    _headerCell('Endzeit'),
                    _headerCell('gefahrene\nkm'),
                    _headerCell('Kilometerstand\n(von/bis)'),
                    _headerCell('Kfz-Kennzeichen'),
                    _headerCell('Tageszeit'),
                    _headerCell('Fahrstrecke/-\nziel'),
                    _headerCell('Strassenzustand,\nWitterung'),
                  ],
                ),
                ...trips.map(
                  (TripSummary trip) => TableRow(
                    children: <Widget>[
                      _cell(_formatDate(trip.startTime)),
                      _cell(
                        trip.endTime != null ? _formatDate(trip.endTime!) : '-',
                      ),
                      _cell(trip.distanceKm.toStringAsFixed(2)),
                      _cell('-'),
                      _cell(trip.vehicleId.toString()),
                      _cell(_formatTimeOfDay(trip.startTime)),
                      _cell(_formatRoute(trip)),
                      _cell(trip.roadSurfaceConditions),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _cell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, textAlign: TextAlign.center),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  String _formatTimeOfDay(DateTime dt) {
    final int hour = dt.hour;
    if (hour < 6) return 'Nacht';
    if (hour < 12) return 'Vormittag';
    if (hour < 18) return 'Nachmittag';
    return 'Abend';
  }

  String _formatRoute(TripSummary trip) {
    final String start = (trip.startPoint ?? '').trim();
    final String end = (trip.endPoint ?? '').trim();

    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start -> $end';
    }
    if (start.isNotEmpty) {
      return start;
    }
    if (end.isNotEmpty) {
      return end;
    }
    return trip.type ?? '-';
  }
}

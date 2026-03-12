import 'package:drivesense/runtime_store.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/model/trip_summary.dart';

class ProtocolTable extends StatefulWidget {
  const ProtocolTable({super.key});

  @override
  State<ProtocolTable> createState() => _ProtocolTableState();
}

class _ProtocolTableState extends State<ProtocolTable> {
  @override
  Widget build(BuildContext context) {
    final List<TripSummary> trips = RuntimeStore.trips; // Beispiel: alle Trip-Objekte

    return SizedBox(
      width: double.infinity,
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: 700),
          child: Table(
            border: TableBorder.all(color: Colors.black, width: 1),
            children: [
              TableRow(
                key: ValueKey('headerRow'),
                children: [
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Datum',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'gefahrene\nkm',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Kilometerstand\n(von/bis)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Kfz-Kennzeichen',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Tageszeit',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Fahrstrecke/-\nziel',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Straßenzustand,\nWitterung',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              ...trips.map(
                (trip) => TableRow(
                  children: [
                    _cell(_formatDate(trip.startTime)),
                    _cell(trip.distanceKm.toStringAsFixed(2)),
                    _cell('-'), // du hast aktuell keinen km-stand im Model
                    _cell(trip.vehicleId.toString()),
                    _cell(_formatTimeOfDay(trip.startTime)),
                    _cell(trip.type ?? '-'),
                    _cell(trip.roadSurfaceConditions),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableCell _cell(String text) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  String _formatTimeOfDay(DateTime dt) {
    final hour = dt.hour;
    if (hour < 6) return 'Nacht';
    if (hour < 12) return 'Vormittag';
    if (hour < 18) return 'Nachmittag';
    return 'Abend';
  }
}

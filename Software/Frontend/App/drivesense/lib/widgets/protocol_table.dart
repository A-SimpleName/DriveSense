import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/trip_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProtocolTable extends StatelessWidget {
  final Future<void> Function()? onChanged;

  const ProtocolTable({super.key, this.onChanged});

  static const double _tableWidth = 1064;
  static const BorderSide _tableBorderSide = BorderSide(color: Colors.grey);
  static const Map<int, TableColumnWidth> _columnWidths =
      <int, TableColumnWidth>{
        0: FixedColumnWidth(100),
        1: FixedColumnWidth(100),
        2: FixedColumnWidth(90),
        3: FixedColumnWidth(130),
        4: FixedColumnWidth(120),
        5: FixedColumnWidth(100),
        6: FixedColumnWidth(150),
        7: FixedColumnWidth(170),
        8: FixedColumnWidth(104),
      };

  static final TableBorder _headerTableBorder = TableBorder(
    top: _tableBorderSide,
    left: _tableBorderSide,
    right: _tableBorderSide,
    bottom: _tableBorderSide,
    verticalInside: _tableBorderSide,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(4),
    ),
  );

  static final TableBorder _bodyTableBorder = TableBorder(
    left: _tableBorderSide,
    right: _tableBorderSide,
    bottom: _tableBorderSide,
    horizontalInside: _tableBorderSide,
    verticalInside: _tableBorderSide,
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(4),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final List<TripSummary> trips = RuntimeStore.trips;

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _tableWidth,
          child: Column(
            children: <Widget>[
              Table(
                border: _headerTableBorder,
                columnWidths: _columnWidths,
                children: <TableRow>[
                  TableRow(
                    key: const ValueKey('headerRow'),
                    decoration: BoxDecoration(color: Colors.grey.shade200),
                    children: _headerCells,
                  ),
                ],
              ),
              Expanded(
                child: trips.isEmpty
                    ? const Center(child: Text('Keine Fahrten vorhanden.'))
                    : SingleChildScrollView(
                        child: Table(
                          border: _bodyTableBorder,
                          columnWidths: _columnWidths,
                          children: trips
                              .map(
                                (TripSummary trip) => TableRow(
                                  children: <Widget>[
                                    _cell(_formatDate(trip.startTime)),
                                    _cell(
                                      trip.endTime != null
                                          ? _formatDate(trip.endTime!)
                                          : '-',
                                    ),
                                    _cell(trip.distanceKm.toStringAsFixed(2)),
                                    _cell(_formatMileageRange(trip)),
                                    _cell(_formatVehicleLicensePlate(trip)),
                                    _cell(_formatTimeOfDay(trip.startTime)),
                                    _cell(_formatRoute(trip)),
                                    _cell(trip.roadSurfaceConditions),
                                    _actionCell(context, trip),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> get _headerCells {
    return <Widget>[
      _headerCell('Startzeit'),
      _headerCell('Endzeit'),
      _headerCell('gefahrene\nkm'),
      _headerCell('Kilometerstand\n(von/bis)'),
      _headerCell('Kfz-Kennzeichen'),
      _headerCell('Tageszeit'),
      _headerCell('Fahrstrecke/-\nziel'),
      _headerCell('Strassenzustand,\nWitterung'),
      _headerCell('Aktionen'),
    ];
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _cell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(text),
    );
  }

  Widget _actionCell(BuildContext context, TripSummary trip) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              tooltip: 'Bearbeiten',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              onPressed: () => _openTripDialog(context, trip),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              tooltip: 'Loeschen',
              color: Colors.red,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              onPressed: () => _deleteTrip(context, trip),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTripDialog(BuildContext context, TripSummary trip) async {
    if (trip.endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offene Fahrt kann nicht bearbeitet werden.')),
      );
      return;
    }

    final TripSummary? updatedTrip = await showDialog<TripSummary>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => _TripEditDialog(trip: trip),
    );

    if (updatedTrip == null) {
      return;
    }

    try {
      await TripService().updateTripSummary(updatedTrip);
      await onChanged?.call();
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fahrt aktualisiert.')),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
      );
    }
  }

  Future<void> _deleteTrip(BuildContext context, TripSummary trip) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Fahrt loeschen'),
        content: Text(
          'Moechtest du die Fahrt vom ${_formatDate(trip.startTime)} wirklich loeschen?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final bool success = await TripService().deleteTripSummary(trip.id);
    await onChanged?.call();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Fahrt geloescht.' : 'Loeschen fehlgeschlagen.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
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

  String _formatMileageRange(TripSummary trip) {
    if (trip.startMileage <= 0 && trip.endMileage <= 0) {
      return '-';
    }

    return '${trip.startMileage} - ${trip.endMileage} km';
  }

  String _formatRoute(TripSummary trip) {
    final String start = (trip.startPoint ?? '').trim();
    final String end = (trip.endPoint ?? '').trim();
    final String type = (trip.type ?? '').trim();

    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start -> $end';
    }
    if (start.isNotEmpty) {
      return start;
    }
    if (end.isNotEmpty) {
      return end;
    }
    return type.isNotEmpty ? type : '-';
  }

  String _formatVehicleLicensePlate(TripSummary trip) {
    final String licensePlate = (trip.vehicleLicensePlate ?? '').trim();
    if (licensePlate.isNotEmpty) {
      return licensePlate;
    }

    for (final vehicle in RuntimeStore.vehicles) {
      if (vehicle.id == trip.vehicleId) {
        return vehicle.licensePlate;
      }
    }

    return '-';
  }
}

class _TripEditDialog extends StatefulWidget {
  final TripSummary trip;

  const _TripEditDialog({required this.trip});

  @override
  State<_TripEditDialog> createState() => _TripEditDialogState();
}

class _TripEditDialogState extends State<_TripEditDialog> {
  late final TextEditingController _distanceCtrl;
  late final TextEditingController _startMileageCtrl;
  late final TextEditingController _endMileageCtrl;
  late final TextEditingController _startPointCtrl;
  late final TextEditingController _endPointCtrl;
  late final TextEditingController _roadSurfaceCtrl;
  late final TextEditingController _typeCtrl;

  @override
  void initState() {
    super.initState();
    _distanceCtrl = TextEditingController(
      text: widget.trip.distanceKm.toStringAsFixed(2),
    );
    _startMileageCtrl = TextEditingController(
      text: widget.trip.startMileage.toString(),
    );
    _endMileageCtrl = TextEditingController(
      text: widget.trip.endMileage.toString(),
    );
    _startPointCtrl = TextEditingController(text: widget.trip.startPoint ?? '');
    _endPointCtrl = TextEditingController(text: widget.trip.endPoint ?? '');
    _roadSurfaceCtrl = TextEditingController(
      text: widget.trip.roadSurfaceConditions,
    );
    _typeCtrl = TextEditingController(text: widget.trip.type ?? '');
  }

  @override
  void dispose() {
    _distanceCtrl.dispose();
    _startMileageCtrl.dispose();
    _endMileageCtrl.dispose();
    _startPointCtrl.dispose();
    _endPointCtrl.dispose();
    _roadSurfaceCtrl.dispose();
    _typeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final double? distanceKm = double.tryParse(
      _distanceCtrl.text.trim().replaceAll(',', '.'),
    );
    final int? startMileage = int.tryParse(_startMileageCtrl.text.trim());
    final int? endMileage = int.tryParse(_endMileageCtrl.text.trim());

    if (distanceKm == null || startMileage == null || endMileage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Zahlen korrekt eingeben.')),
      );
      return;
    }

    if (distanceKm < 0 || startMileage < 0 || endMileage < startMileage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kilometerwerte sind ungueltig.')),
      );
      return;
    }

    Navigator.of(context).pop(
      widget.trip.copyWith(
        distanceKm: distanceKm,
        startMileage: startMileage,
        endMileage: endMileage,
        startPoint: _startPointCtrl.text.trim(),
        endPoint: _endPointCtrl.text.trim(),
        roadSurfaceConditions: _roadSurfaceCtrl.text.trim(),
        type: _typeCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fahrt bearbeiten'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _distanceCtrl,
              decoration: const InputDecoration(labelText: 'Gefahrene km'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _startMileageCtrl,
              decoration: const InputDecoration(labelText: 'Startkilometer'),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _endMileageCtrl,
              decoration: const InputDecoration(labelText: 'Endkilometer'),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _startPointCtrl,
              decoration: const InputDecoration(labelText: 'Startpunkt'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _endPointCtrl,
              decoration: const InputDecoration(labelText: 'Ziel'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _roadSurfaceCtrl,
              decoration: const InputDecoration(
                labelText: 'Strassenzustand / Witterung',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _typeCtrl,
              decoration: const InputDecoration(labelText: 'Typ'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

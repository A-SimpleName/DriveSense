import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/trip_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drivesense/widgets/delayed_confirm_dialog.dart';

class ProtocolTable extends StatelessWidget {
  final Future<void> Function()? onChanged;

  const ProtocolTable({super.key, this.onChanged});

  static const double _actionColumnWidth = 104;
  static const BorderSide _tableBorderSide = BorderSide(color: Colors.grey);

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
    final List<_ProtocolColumn> columns = _columnsForRole(
      RuntimeStore.getActiveProfileRole(),
    );
    final Map<int, TableColumnWidth> columnWidths = _columnWidthsFor(columns);
    final double tableWidth = _tableWidthFor(columns);

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            children: <Widget>[
              Table(
                border: _headerTableBorder,
                columnWidths: columnWidths,
                children: <TableRow>[
                  TableRow(
                    key: const ValueKey('headerRow'),
                    decoration: BoxDecoration(color: Colors.grey.shade200),
                    children: <Widget>[
                      ...columns.map(
                        (_ProtocolColumn column) => _headerCell(column.header),
                      ),
                      _headerCell('Aktionen'),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: trips.isEmpty
                    ? const Center(child: Text('Keine Fahrten vorhanden.'))
                    : SingleChildScrollView(
                        child: Table(
                          border: _bodyTableBorder,
                          columnWidths: columnWidths,
                          children: trips
                              .map(
                                (TripSummary trip) => TableRow(
                                  children: <Widget>[
                                    ...columns.map(
                                      (_ProtocolColumn column) =>
                                          _cell(column.value(trip)),
                                    ),
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

  List<_ProtocolColumn> _columnsForRole(String role) {
    switch (_normalizeRole(role)) {
      case 'FAHRSCHUELER':
        return <_ProtocolColumn>[
          _ProtocolColumn(
            header: 'Datum',
            width: 100,
            value: (TripSummary trip) => _formatDate(trip.startTime),
          ),
          _ProtocolColumn(
            header: 'gefahrene\nkm',
            width: 100,
            value: (TripSummary trip) => _formatDistance(trip.distanceKm),
          ),
          _ProtocolColumn(
            header: 'km-Stand\nvon',
            width: 105,
            value: (TripSummary trip) => _formatMileage(trip.startMileage),
          ),
          _ProtocolColumn(
            header: 'km-Stand\nbis',
            width: 105,
            value: (TripSummary trip) => _formatMileage(trip.endMileage),
          ),
          _ProtocolColumn(
            header: 'KFZ-\nKennzeichen',
            width: 125,
            value: _formatVehicleLicensePlate,
          ),
          _ProtocolColumn(
            header: 'Tageszeit',
            width: 90,
            value: (TripSummary trip) => _formatClockTime(trip.startTime),
          ),
          _ProtocolColumn(
            header: 'Fahrstrecke /\nZiel',
            width: 190,
            value: _formatRoute,
          ),
          _ProtocolColumn(
            header: 'Strassenzustand /\nWitterung',
            width: 165,
            value: (TripSummary trip) =>
                _formatText(trip.roadSurfaceConditions),
          ),
          _ProtocolColumn(
            header: 'Unterschrift\nBegleiter',
            width: 130,
            value: (_) => '-',
          ),
          _ProtocolColumn(
            header: 'Unterschrift\nBewerber',
            width: 130,
            value: (_) => '-',
          ),
        ];
      case 'BERUFSFAHRER':
        return <_ProtocolColumn>[
          _ProtocolColumn(
            header: 'Datum',
            width: 100,
            value: (TripSummary trip) => _formatDate(trip.startTime),
          ),
          _ProtocolColumn(
            header: 'Uhrzeit',
            width: 90,
            value: (TripSummary trip) => _formatClockTime(trip.startTime),
          ),
          _ProtocolColumn(
            header: 'Start',
            width: 145,
            value: (TripSummary trip) => _formatText(trip.startPoint),
          ),
          _ProtocolColumn(
            header: 'Wendepunkt',
            width: 145,
            value: (TripSummary trip) => _formatText(trip.furthestPoint),
          ),
          _ProtocolColumn(
            header: 'Ziel',
            width: 145,
            value: (TripSummary trip) => _formatText(trip.endPoint),
          ),
          _ProtocolColumn(
            header: 'km-Start',
            width: 100,
            value: (TripSummary trip) => _formatMileage(trip.startMileage),
          ),
          _ProtocolColumn(
            header: 'km-Ende',
            width: 100,
            value: (TripSummary trip) => _formatMileage(trip.endMileage),
          ),
          _ProtocolColumn(
            header: 'Strecke',
            width: 100,
            value: (TripSummary trip) => _formatDistance(trip.distanceKm),
          ),
          _ProtocolColumn(
            header: 'KFZ Kennzeichen',
            width: 130,
            value: _formatVehicleLicensePlate,
          ),
          _ProtocolColumn(
            header: 'Typ / Zweck',
            width: 150,
            value: (TripSummary trip) => _formatText(trip.type),
          ),
        ];
      case 'PRIVAT':
      default:
        return <_ProtocolColumn>[
          _ProtocolColumn(
            header: 'Datum',
            width: 100,
            value: (TripSummary trip) => _formatDate(trip.startTime),
          ),
          _ProtocolColumn(
            header: 'Start',
            width: 150,
            value: (TripSummary trip) => _formatText(trip.startPoint),
          ),
          _ProtocolColumn(
            header: 'Wendepunkt',
            width: 150,
            value: (TripSummary trip) => _formatText(trip.furthestPoint),
          ),
          _ProtocolColumn(
            header: 'Ziel',
            width: 150,
            value: (TripSummary trip) => _formatText(trip.endPoint),
          ),
          _ProtocolColumn(
            header: 'km-Start',
            width: 100,
            value: (TripSummary trip) => _formatMileage(trip.startMileage),
          ),
          _ProtocolColumn(
            header: 'km-Ende',
            width: 100,
            value: (TripSummary trip) => _formatMileage(trip.endMileage),
          ),
          _ProtocolColumn(
            header: 'Strecke',
            width: 100,
            value: (TripSummary trip) => _formatDistance(trip.distanceKm),
          ),
          _ProtocolColumn(
            header: 'KFZ Kennzeichen',
            width: 130,
            value: _formatVehicleLicensePlate,
          ),
        ];
    }
  }

  Map<int, TableColumnWidth> _columnWidthsFor(List<_ProtocolColumn> columns) {
    return <int, TableColumnWidth>{
      for (int i = 0; i < columns.length; i++)
        i: FixedColumnWidth(columns[i].width),
      columns.length: const FixedColumnWidth(_actionColumnWidth),
    };
  }

  double _tableWidthFor(List<_ProtocolColumn> columns) {
    return columns.fold<double>(
          0,
          (double width, _ProtocolColumn column) => width + column.width,
        ) +
        _actionColumnWidth;
  }

  String _normalizeRole(String role) {
    final String normalized = role.trim().toUpperCase();

    switch (normalized) {
      case 'FAHRSCHÜLER':
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

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        const SnackBar(
          content: Text('Offene Fahrt kann nicht bearbeitet werden.'),
        ),
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fahrt aktualisiert.')));
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Speichern fehlgeschlagen: $e')));
    }
  }

  Future<void> _deleteTrip(BuildContext context, TripSummary trip) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DelayedConfirmDialog(
        title: 'Fahrt löschen',
        content:
            'Fahrt am "${_formatDate(trip.startTime)}" wirklich löschen?\n\n'
            'Diese Aktion kann nicht rückgängig gemacht werden.',
        confirmText: 'Endgültig löschen',
        delaySeconds: 0,
        confirmButtonColor: Colors.red,
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
        content: Text(
          success ? 'Fahrt geloescht.' : 'Loeschen fehlgeschlagen.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  String _formatClockTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDistance(double distanceKm) {
    return '${distanceKm.toStringAsFixed(2)} km';
  }

  String _formatMileage(int mileage) {
    return mileage > 0 ? mileage.toString() : '-';
  }

  String _formatText(String? value) {
    final String text = (value ?? '').trim();
    return text.isNotEmpty ? text : '-';
  }

  String _formatRoute(TripSummary trip) {
    final List<String> routePoints =
        <String>[
          trip.startPoint ?? '',
          trip.furthestPoint ?? '',
          trip.endPoint ?? '',
        ].map((String value) => value.trim()).where((String value) {
          return value.isNotEmpty;
        }).toList();

    if (routePoints.isNotEmpty) {
      return routePoints.join(' -> ');
    }

    final String type = (trip.type ?? '').trim();
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

class _ProtocolColumn {
  final String header;
  final double width;
  final String Function(TripSummary trip) value;

  const _ProtocolColumn({
    required this.header,
    required this.width,
    required this.value,
  });
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
  late final TextEditingController _furthestPointCtrl;
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
    _furthestPointCtrl = TextEditingController(
      text: widget.trip.furthestPoint ?? '',
    );
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
    _furthestPointCtrl.dispose();
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
        furthestPoint: _furthestPointCtrl.text.trim(),
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
              controller: _furthestPointCtrl,
              decoration: const InputDecoration(labelText: 'Wendepunkt'),
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
        ElevatedButton(onPressed: _save, child: const Text('Speichern')),
      ],
    );
  }
}

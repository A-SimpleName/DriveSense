import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/trip_service.dart';
import 'package:drivesense/widgets/protocol_trip_fields.dart';
import 'package:drivesense/widgets/trip_detail_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProtocolTable extends StatelessWidget {
  final Future<void> Function()? onChanged;

  const ProtocolTable({super.key, this.onChanged});

  static const double _actionColumnWidth = 160;
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
    final List<ProtocolTripField> columns = protocolTripFieldsForRole(
      RuntimeStore.getActiveProfileRole(),
    );
    final Map<int, TableColumnWidth> columnWidths = _columnWidthsFor(columns);
    final double tableWidth = _tableWidthFor(columns);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 1
            ? constraints.maxWidth - 1
            : tableWidth;
        final double effectiveTableWidth = tableWidth > viewportWidth
            ? tableWidth
            : viewportWidth;

        return SizedBox(
          width: double.infinity,
          child: ClipRect(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: effectiveTableWidth,
                child: Column(
                  children: <Widget>[
                    Table(
                      border: _headerTableBorder,
                      columnWidths: columnWidths,
                      children: <TableRow>[
                        TableRow(
                          key: const ValueKey('headerRow'),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                          ),
                          children: <Widget>[
                            ...columns.map(
                              (ProtocolTripField column) =>
                                  _headerCell(column.header),
                            ),
                            _headerCell('Aktionen'),
                          ],
                        ),
                      ],
                    ),
                    Expanded(
                      child: trips.isEmpty
                          ? const Center(
                              child: Text('Keine Fahrten vorhanden.'),
                            )
                          : SingleChildScrollView(
                              child: Table(
                                border: _bodyTableBorder,
                                columnWidths: columnWidths,
                                children: trips
                                    .map(
                                      (TripSummary trip) => TableRow(
                                        children: <Widget>[
                                          ...columns.map(
                                            (ProtocolTripField column) =>
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
          ),
        );
      },
    );
  }

  Map<int, TableColumnWidth> _columnWidthsFor(List<ProtocolTripField> columns) {
    return <int, TableColumnWidth>{
      for (int i = 0; i < columns.length; i++)
        i: FixedColumnWidth(columns[i].width),
      columns.length: const FixedColumnWidth(_actionColumnWidth),
    };
  }

  double _tableWidthFor(List<ProtocolTripField> columns) {
    return columns.fold<double>(
          0,
          (double width, ProtocolTripField column) => width + column.width,
        ) +
        _actionColumnWidth;
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
              icon: const Icon(Icons.info_outline, size: 18),
              tooltip: 'Details',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              onPressed: () => showTripDetailDialog(context, trip),
            ),
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
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Fahrt loeschen'),
        content: Text(
          'Moechtest du die Fahrt vom ${formatProtocolTripDate(trip.startTime)} wirklich loeschen?',
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

    final bool success = await TripService().deleteTripSummary(trip);
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

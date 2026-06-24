import 'package:drivesense/config/app_colors.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/trip_service.dart';
import 'package:drivesense/widgets/protocol_trip_fields.dart';
import 'package:drivesense/widgets/trip_detail_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProtocolTable extends StatefulWidget {
  final Future<void> Function()? onChanged;

  const ProtocolTable({super.key, this.onChanged});

  @override
  State<ProtocolTable> createState() => _ProtocolTableState();
}

class _ProtocolTableState extends State<ProtocolTable> {
  static const int _tripsPerPage = 20;
  static const double _actionColumnWidth = 160;
  static const BorderSide _tableBorderSide = BorderSide(color: Colors.grey);
  int _pageIndex = 0;
  int _lastProtocolId = RuntimeStore.getCurrentProtocolId();

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
    // RuntimeStore.trips is already filtered to the selected profile/protocol;
    // this widget only handles presentation, paging, and row actions.
    final List<TripSummary> trips = RuntimeStore.trips;
    _syncPageState(trips.length);

    final List<ProtocolTripField> columns = protocolTripFieldsForRole(
      RuntimeStore.getActiveProfileRole(),
    );
    final Map<int, TableColumnWidth> columnWidths = _columnWidthsFor(columns);
    final double tableWidth = _tableWidthFor(columns);
    final int pageCount = _pageCountFor(trips.length);
    final int startIndex = trips.isEmpty ? 0 : _pageIndex * _tripsPerPage;
    final int endIndex = _pageEndIndex(trips.length, startIndex);
    final List<TripSummary> visibleTrips = trips.isEmpty
        ? <TripSummary>[]
        : trips.sublist(startIndex, endIndex);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 1
            ? constraints.maxWidth - 1
            : tableWidth;
        final double effectiveTableWidth = tableWidth > viewportWidth
            ? tableWidth
            : viewportWidth;

        return Column(
          children: <Widget>[
            Expanded(
              child: SizedBox(
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
                                  color: AppColors.primaryBlue,
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
                            child: visibleTrips.isEmpty
                                ? const Center(
                                    child: Text('Keine Fahrten vorhanden.'),
                                  )
                                : SingleChildScrollView(
                                    child: Table(
                                      border: _bodyTableBorder,
                                      columnWidths: columnWidths,
                                      children: visibleTrips
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
              ),
            ),
            if (trips.length > _tripsPerPage)
              _paginationControls(
                totalTrips: trips.length,
                pageCount: pageCount,
                startIndex: startIndex,
                endIndex: endIndex,
              ),
          ],
        );
      },
    );
  }

  /// Keeps the current page valid when the active protocol or trip count
  /// changes after sync, delete, or profile switching.
  void _syncPageState(int tripCount) {
    final int protocolId = RuntimeStore.getCurrentProtocolId();
    if (_lastProtocolId != protocolId) {
      _lastProtocolId = protocolId;
      _pageIndex = 0;
      return;
    }

    final int pageCount = _pageCountFor(tripCount);
    if (_pageIndex >= pageCount) {
      _pageIndex = pageCount - 1;
    }
  }

  int _pageCountFor(int tripCount) {
    if (tripCount <= 0) {
      return 1;
    }
    return ((tripCount - 1) ~/ _tripsPerPage) + 1;
  }

  int _pageEndIndex(int tripCount, int startIndex) {
    final int endIndex = startIndex + _tripsPerPage;
    return endIndex > tripCount ? tripCount : endIndex;
  }

  void _goToPage(int pageIndex, int pageCount) {
    final int nextPageIndex = pageIndex.clamp(0, pageCount - 1).toInt();
    if (nextPageIndex == _pageIndex) {
      return;
    }

    setState(() {
      _pageIndex = nextPageIndex;
    });
  }

  Widget _paginationControls({
    required int totalTrips,
    required int pageCount,
    required int startIndex,
    required int endIndex,
  }) {
    final bool isFirstPage = _pageIndex == 0;
    final bool isLastPage = _pageIndex >= pageCount - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Fahrten ${startIndex + 1}-$endIndex von $totalTrips',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Erste Seite',
            onPressed: isFirstPage ? null : () => _goToPage(0, pageCount),
            icon: const Icon(Icons.first_page),
          ),
          IconButton(
            tooltip: 'Vorherige Seite',
            onPressed: isFirstPage
                ? null
                : () => _goToPage(_pageIndex - 1, pageCount),
            icon: const Icon(Icons.chevron_left),
          ),
          SizedBox(
            width: 88,
            child: Center(child: Text('Seite ${_pageIndex + 1} / $pageCount')),
          ),
          IconButton(
            tooltip: 'Nächste Seite',
            onPressed: isLastPage
                ? null
                : () => _goToPage(_pageIndex + 1, pageCount),
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: 'Letzte Seite',
            onPressed: isLastPage
                ? null
                : () => _goToPage(pageCount - 1, pageCount),
            icon: const Icon(Icons.last_page),
          ),
        ],
      ),
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
              tooltip: 'Löschen',
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

  /// Opens the edit dialog for completed trips and refreshes the table after a
  /// successful backend update.
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
      await widget.onChanged?.call();
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

  /// Confirms trip deletion, delegates local/server deletion to TripService, and
  /// refreshes visible rows afterwards.
  Future<void> _deleteTrip(BuildContext context, TripSummary trip) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Fahrt löschen'),
        content: Text(
          'Möchtest du die Fahrt vom ${formatProtocolTripDate(trip.startTime)} wirklich löschen?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final TripActionResult result = await TripService()
        .deleteTripSummaryWithResult(trip);
    await widget.onChanged?.call();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
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

  /// Validates editable protocol-table fields and returns a copied TripSummary
  /// to the caller instead of mutating the original row directly.
  void _save() {
    final String role = normalizeProtocolRole(
      RuntimeStore.getActiveProfileRole(),
    );
    final bool showRoadSurface = role == 'FAHRSCHUELER';
    final bool showType = role == 'BERUFSFAHRER';
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
        const SnackBar(content: Text('Kilometerwerte sind ungültig.')),
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
        roadSurfaceConditions: showRoadSurface
            ? _roadSurfaceCtrl.text.trim()
            : widget.trip.roadSurfaceConditions,
        type: showType ? _typeCtrl.text.trim() : widget.trip.type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String role = normalizeProtocolRole(
      RuntimeStore.getActiveProfileRole(),
    );
    final bool showRoadSurface = role == 'FAHRSCHUELER';
    final bool showType = role == 'BERUFSFAHRER';

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
            if (showRoadSurface) ...<Widget>[
              const SizedBox(height: 8),
              TextField(
                controller: _roadSurfaceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Straßenzustand / Witterung',
                ),
              ),
            ],
            if (showType) ...<Widget>[
              const SizedBox(height: 8),
              TextField(
                controller: _typeCtrl,
                decoration: const InputDecoration(labelText: 'Typ / Zweck'),
              ),
            ],
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

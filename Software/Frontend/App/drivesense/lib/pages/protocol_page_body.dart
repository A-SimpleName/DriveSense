import 'dart:async';

import 'package:drivesense/model/protocol.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/protocol_service.dart';
import 'package:drivesense/services/trip_sync_service.dart';
import 'package:drivesense/widgets/ds_snyc_trips_button.dart';
import 'package:drivesense/widgets/protocol_table.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/services/pdf_service.dart';
import 'package:drivesense/widgets/delayed_confirm_dialog.dart';

class ProtocolPageBody extends StatefulWidget {
  final TripSyncService tripSyncService;

  const ProtocolPageBody({super.key, required this.tripSyncService});

  @override
  State<ProtocolPageBody> createState() => _ProtocolPageBodyState();
}

class _ProtocolPageBodyState extends State<ProtocolPageBody> {
  bool _isLoading = true;
  bool _isCreating = false;
  bool _isExportingPdf = false;
  String? _loadError;
  int? _lastProfileId;

  List<Protocol> get _protocols => RuntimeStore.protocols;

  @override
  void initState() {
    super.initState();
    _lastProfileId = RuntimeStore.currentProfileId;
    Future.microtask(_loadProtocolsAndTrips);
  }

  @override
  Widget build(BuildContext context) {
    _reloadIfProfileChanged();
    final int selectedProtocolId = RuntimeStore.getCurrentProtocolId();

    return SafeArea(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DropdownButtonFormField<int>(
                  initialValue: _resolveDropdownValue(selectedProtocolId),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ausgewaehltes Protokoll',
                    border: OutlineInputBorder(),
                  ),
                  hint: Text(
                    _isLoading
                        ? 'Protokolle werden geladen...'
                        : 'Protokoll auswaehlen',
                  ),
                  items: _protocols
                      .map(
                        (Protocol protocol) => DropdownMenuItem<int>(
                          value: protocol.id,
                          child: Text(protocol.name),
                        ),
                      )
                      .toList(),
                  onChanged: _isLoading || _protocols.isEmpty
                      ? null
                      : _handleProtocolChanged,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading || _protocols.isEmpty
                        ? null
                        : _handleDeleteProtocolPressed,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Protokoll löschen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isLoading || _protocols.isEmpty || _isExportingPdf
                            ? null
                            : _handlePdfExportPressed,
                        icon: _isExportingPdf
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf),
                        label: Text(
                          _isExportingPdf ? 'Exportiere...' : 'PDF exportieren',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isCreating ? null : _showCreateProtocolDialog,
                      icon: _isCreating
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: Text(_isCreating ? 'Erstelle...' : 'Neu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _loadError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _protocols.isEmpty
                  ? const Center(
                      child: Text('Keine Protokolle fuer das aktuelle Profil.'),
                    )
                  : ProtocolTable(onChanged: _refreshVisibleTrips),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DsSnycTripsButton(tripSyncService: widget.tripSyncService),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteProtocolPressed() async {
    final int selectedProtocolId = RuntimeStore.getCurrentProtocolId();
    if (selectedProtocolId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kein Protokoll ausgewählt.')),
      );
      return;
    }

    final Protocol? selectedProtocol = _protocols.cast<Protocol?>().firstWhere(
      (Protocol? protocol) => protocol?.id == selectedProtocolId,
      orElse: () => null,
    );

    final String protocolName =
        selectedProtocol?.name ?? 'Unbekanntes Protokoll';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DelayedConfirmDialog(
        title: 'Protokoll löschen',
        content:
            'Protokoll "$protocolName" wirklich löschen?\n\n'
            'Diese Aktion kann nicht rückgängig gemacht werden.',
        confirmText: 'Endgültig löschen',
        delaySeconds: 0,
        confirmButtonColor: Colors.red,
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    final bool success = await ProtocolService.deleteProtocol(
      selectedProtocolId,
    );

    if (!mounted) return;

    if (success) {
      await _loadProtocolsAndTrips();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Protokoll wurde gelöscht.')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Löschen fehlgeschlagen.')));
    }
  }

  Future<void> _handlePdfExportPressed() async {
    setState(() {
      _isExportingPdf = true;
    });

    final PdfExportResult result = await PdfService.generatePdf(
      protocolId: RuntimeStore.getCurrentProtocolId(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isExportingPdf = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _refreshVisibleTrips() async {
    await RuntimeStore.refreshTrips();
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _reloadIfProfileChanged() {
    final int? activeProfileId = RuntimeStore.currentProfileId;
    if (activeProfileId == _lastProfileId) {
      return;
    }

    _lastProfileId = activeProfileId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadProtocolsAndTrips());
      }
    });
  }

  int? _resolveDropdownValue(int selectedProtocolId) {
    for (final Protocol protocol in _protocols) {
      if (protocol.id == selectedProtocolId) {
        return selectedProtocolId;
      }
    }

    return null;
  }

  Future<void> _loadProtocolsAndTrips() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final List<Protocol> protocols = await ProtocolService.fetchProtocols();
      if (!mounted) {
        return;
      }

      if (protocols.isEmpty) {
        RuntimeStore.setProtocols(<Protocol>[]);
        RuntimeStore.setCurrentProtocolId(0);
        RuntimeStore.setTrips(<TripSummary>[]);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Protocol selectedProtocol = _findSelectedProtocol(protocols);
      RuntimeStore.setCurrentProtocolId(selectedProtocol.id);
      await RuntimeStore.refreshTrips();
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = 'Protokolle konnten nicht geladen werden: $e';
      });
    }
  }

  Protocol _findSelectedProtocol(List<Protocol> protocols) {
    final int selectedProtocolId = RuntimeStore.getCurrentProtocolId();
    for (final Protocol protocol in protocols) {
      if (protocol.id == selectedProtocolId) {
        return protocol;
      }
    }

    return protocols.first;
  }

  Future<void> _handleProtocolChanged(int? protocolId) async {
    if (protocolId == null ||
        protocolId == RuntimeStore.getCurrentProtocolId()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    RuntimeStore.setCurrentProtocolId(protocolId);
    await RuntimeStore.refreshTrips();
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showCreateProtocolDialog() async {
    String protocolDraftName = 'L17 Protokoll ${_protocols.length + 1}';

    final String? protocolName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Neues Protokoll'),
          content: TextFormField(
            initialValue: protocolDraftName,
            autofocus: true,
            onChanged: (String value) {
              protocolDraftName = value;
            },
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(protocolDraftName.trim()),
              child: const Text('Erstellen'),
            ),
          ],
        );
      },
    );

    if (protocolName == null || protocolName.trim().isEmpty) {
      return;
    }

    await _createProtocol(protocolName);
  }

  Future<void> _createProtocol(String name) async {
    final int? profileId = RuntimeStore.currentProfileId;
    if (profileId == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kein aktives Profil verfuegbar.')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
      _loadError = null;
    });

    try {
      final Protocol? createdProtocol = await ProtocolService.createProtocol(
        name: name,
      );

      if (createdProtocol == null) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Protokoll konnte nicht erstellt werden.'),
          ),
        );
        return;
      }

      final List<Protocol> protocols = await ProtocolService.fetchProtocols();
      if (protocols.isEmpty) {
        RuntimeStore.upsertProtocol(createdProtocol);
      }

      RuntimeStore.setCurrentProtocolId(createdProtocol.id);
      await RuntimeStore.refreshTrips();
      if (!mounted) {
        return;
      }

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Protokoll "${createdProtocol.name}" erstellt.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = 'Protokoll konnte nicht erstellt werden: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}

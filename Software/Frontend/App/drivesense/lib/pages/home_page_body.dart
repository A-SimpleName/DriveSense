import 'dart:async';

import 'package:drivesense/exceptions/trip_http_exception.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/model/vehicle.dart';
import 'package:drivesense/repository/active_trip_repository.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/protocol_service.dart';
import 'package:drivesense/services/trip_session_service.dart';
import 'package:drivesense/services/trip_sync_service.dart';
import 'package:drivesense/services/vehicle_service.dart';
import 'package:drivesense/widgets/current_trip_card.dart';
import 'package:drivesense/widgets/last_trip_card.dart';
import 'package:drivesense/widgets/start_trip_card.dart';
import 'package:drivesense/widgets/trip_detail_dialog.dart';
import 'package:flutter/material.dart';

class HomePageBody extends StatefulWidget {
  final TripSyncService tripSyncService;
  const HomePageBody({super.key, required this.tripSyncService});

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  late final TripSessionService _tripSessionService;
  bool _isStartingTrip = false;
  bool _isStoppingTrip = false;
  bool _isChangingPauseState = false;

  @override
  void initState() {
    super.initState();
    _tripSessionService = TripSessionService(
      tripSyncService: widget.tripSyncService,
      activeTripRepository: ActiveTripRepository(),
    );
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await Future.wait(<Future<void>>[_loadVehicles(), _loadProtocols()]);
    await _tripSessionService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: AnimatedBuilder(
            animation: _tripSessionService,
            builder: (BuildContext context, _) {
              final TripSessionState state = _tripSessionService.state;
              final Vehicle? currentVehicle = RuntimeStore.getCurrentVehicle();

              if (state.hasActiveTrip) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CurrentTripCard(
                      onStop: _onStopTrip,
                      onAbort: _onAbortTrip,
                      onPauseResume: _onPauseResumeTrip,
                      currentTripDistance: state.totalDistanceMeters,
                      currentTripDuration: state.currentTripDuration,
                      currentVehicle: _tripSessionService.formatVehicleName(
                        currentVehicle,
                      ),
                      isPaused: state.isPaused,
                      isStoppingTrip: _isStoppingTrip,
                      isChangingPauseState: _isChangingPauseState,
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }

              return Column(
                children: [
                  StartTripCard(
                    onStart: _onStartTrip,
                    vehicles: RuntimeStore.vehicles,
                    protocols: RuntimeStore.protocols,
                    selectedProtocolId: RuntimeStore.getCurrentProtocolId(),
                    selectedVehicleId: RuntimeStore.getCurrentVehicleId(),
                    onProtocolChanged: _onProtocolChanged,
                    onVehicleChanged: _onVehicleChanged,
                    isStartingTrip: _isStartingTrip,
                  ),
                  const SizedBox(height: 24),
                  LastTripCard(lastTrip: _resolveLastTrip(state.lastTrip)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _loadVehicles() async {
    final List<Vehicle> vehicles = await VehicleService.fetchVehicles();
    if (!mounted) return;

    setState(() {
      RuntimeStore.setVehicles(vehicles);
    });
  }

  Future<void> _loadProtocols() async {
    await ProtocolService.ensureDefaultProtocolForActiveProfile();
    if (!mounted) return;

    setState(() {});
  }

  void _onVehicleChanged(int vehicleId) {
    setState(() {
      RuntimeStore.setCurrentVehicleId(vehicleId);
    });
  }

  void _onProtocolChanged(int protocolId) {
    setState(() {
      RuntimeStore.setCurrentProtocolId(protocolId);
    });
    unawaited(_refreshTripsForSelectedProtocol());
  }

  Future<void> _refreshTripsForSelectedProtocol() async {
    await RuntimeStore.refreshTrips();
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _onStartTrip() {
    if (_isStartingTrip) {
      return;
    }

    setState(() {
      _isStartingTrip = true;
    });
    unawaited(_startTrip());
  }

  Future<void> _startTrip() async {
    try {
      await _tripSessionService.startTrip();
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isStartingTrip = false;
        });
      }
    }
  }

  void _onPauseResumeTrip() {
    if (_isStoppingTrip || _isChangingPauseState) {
      return;
    }

    setState(() {
      _isChangingPauseState = true;
    });
    unawaited(_pauseOrResumeTrip());
  }

  Future<void> _pauseOrResumeTrip() async {
    try {
      if (_tripSessionService.state.isPaused) {
        await _tripSessionService.resumeTrip();
      } else {
        await _tripSessionService.pauseTrip();
      }
    } catch (e) {
      _showSnackBar(_messageForError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPauseState = false;
        });
      }
    }
  }

  void _onAbortTrip() {
    if (_isStoppingTrip || _isChangingPauseState) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Fahrt abbrechen?'),
          content: const Text(
            'Moechtest du die aktuelle Fahrt wirklich abbrechen? Alle gesammelten Daten gehen verloren.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Nein'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                unawaited(_tripSessionService.abortTrip());
              },
              child: const Text('Ja'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onStopTrip() async {
    if (_isStoppingTrip || _isChangingPauseState) {
      return;
    }

    setState(() {
      _isStoppingTrip = true;
    });

    try {
      final TripSessionStopResult result = await _tripSessionService.stopTrip();

      if (!mounted) {
        return;
      }

      unawaited(
        showTripDetailDialog(
          context,
          result.trip,
          initialDetail: result.localDetail,
          refreshDetail: result.syncFuture.then(
            (TripSessionSyncResult syncResult) => syncResult.detail,
          ),
        ),
      );

      unawaited(_handleTripSyncResult(result.syncFuture));
    } on TripHttpException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar(_messageForError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isStoppingTrip = false;
        });
      }
    }
  }

  TripSummary? _resolveLastTrip(TripSummary? stateLastTrip) {
    if (stateLastTrip != null) {
      return stateLastTrip;
    }

    if (RuntimeStore.trips.isEmpty) {
      return null;
    }

    final List<TripSummary> trips = List<TripSummary>.from(RuntimeStore.trips);
    trips.sort((TripSummary a, TripSummary b) {
      final DateTime aTime = a.endTime ?? a.startTime;
      final DateTime bTime = b.endTime ?? b.startTime;
      return bTime.compareTo(aTime);
    });
    return trips.first;
  }

  Future<void> _handleTripSyncResult(
    Future<TripSessionSyncResult> syncFuture,
  ) async {
    try {
      final TripSessionSyncResult result = await syncFuture;
      if (!result.vehicleMileageSaved) {
        _showSnackBar(
          'Fahrt gespeichert, aber Fahrzeug-Kilometerstand konnte nicht aktualisiert werden.',
        );
      }
    } catch (e) {
      _showSnackBar(_messageForError(e));
    }
  }

  String _messageForError(Object error) {
    final String rawMessage = error.toString().trim();
    final String message = rawMessage.startsWith('Exception: ')
        ? rawMessage.substring('Exception: '.length).trim()
        : rawMessage;
    if (message.isEmpty ||
        message == 'undefined' ||
        rawMessage == 'Exception: undefined') {
      return 'Fahrt lokal gespeichert. Serverdaten werden spaeter synchronisiert.';
    }
    return message;
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _tripSessionService.dispose();
    super.dispose();
  }
}

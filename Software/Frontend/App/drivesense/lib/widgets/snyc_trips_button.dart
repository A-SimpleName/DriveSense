import 'dart:async';

import 'package:flutter/material.dart';
import 'package:drivesense/services/trip_sync_service.dart';

class DsSnycTripsButton extends StatefulWidget {
  final TripSyncService tripSyncService;

  const DsSnycTripsButton({super.key, required this.tripSyncService});

  @override
  State<DsSnycTripsButton> createState() => _DsSnycTripsButtonState();
}

class _DsSnycTripsButtonState extends State<DsSnycTripsButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSync,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text("Fahrten mit Server synchronisieren"),
    );
  }

  /// Runs a manual sync request and keeps the button in a loading state until
  /// the request finishes, fails, or hits the UI timeout.
  Future<void> _handleSync() async {
    setState(() => _isLoading = true);

    try {
      // Keep manual sync bounded so the button cannot stay disabled forever.
      final result = await widget.tripSyncService.syncPendingTrips().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Synchronisierung hat zu lange gedauert (> 10s)',
          );
        },
      );

      if (!context.mounted) {
        return;
      }
      _showSyncResult(result);
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Synchronisieren: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Converts sync counters into the snackbar text the user sees.
  void _showSyncResult(TripSyncResult result) {
    if (result.total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Keine ausstehenden Fahrten zum Synchronisieren."),
        ),
      );
      return;
    }

    if (result.failed == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${result.successful} ausstehende Fahrten wurden synchronisiert.",
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Synchronisierung fehlgeschlagen: ${result.failed} von ${result.total} Fahrten konnten nicht gesendet werden.",
        ),
      ),
    );
  }
}

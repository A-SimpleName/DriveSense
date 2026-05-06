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

  Future<void> _handleSync() async {
    debugPrint('🔄 Sync button pressed');
    setState(() => _isLoading = true);
    
    try {
      debugPrint('🔄 Starting sync with 10s timeout...');
      final result = await widget.tripSyncService.syncPendingTrips().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ Sync timeout after 10 seconds');
          throw TimeoutException('Synchronisierung hat zu lange gedauert (> 10s)');
        },
      );
      debugPrint('🔄 Sync completed: total=${result.total}, successful=${result.successful}, failed=${result.failed}');

      if (context.mounted) {
        if (result.total == 0) {
          debugPrint('ℹ️ No pending trips');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Keine ausstehenden Fahrten zum Synchronisieren."),
            ),
          );
        } else if (result.failed == 0) {
          debugPrint('✅ Sync successful: ${result.successful} trips');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${result.successful} ausstehende Fahrten wurden synchronisiert.",
              ),
            ),
          );
        } else {
          debugPrint('⚠️ Sync partial failure: ${result.successful}/${result.total} successful');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Synchronisierung fehlgeschlagen: ${result.failed} von ${result.total} Fahrten konnten nicht gesendet werden.",
              ),
            ),
          );
        }
      } else {
        debugPrint('⚠️ Context not mounted after sync');
      }
    } catch (e, st) {
      debugPrint('❌ Sync error: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fehler beim Synchronisieren: ${e.toString()}"),
          ),
        );
      } else {
        debugPrint('⚠️ Context not mounted after error');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

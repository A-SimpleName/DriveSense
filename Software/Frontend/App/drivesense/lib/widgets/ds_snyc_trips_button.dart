import 'package:flutter/material.dart';
import 'package:drivesense/services/trip_sync_service.dart';

class DsSnycTripsButton extends StatelessWidget {
  final TripSyncService tripSyncService;

  const DsSnycTripsButton({super.key, required this.tripSyncService});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          final result = await tripSyncService.syncPendingTrips();
          if (context.mounted) {
            if (result.total == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Keine ausstehenden Fahrten zum Synchronisieren."),
                ),
              );
            } else if (result.failed == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "${result.successful} ausstehende Fahrten wurden synchronisiert.",
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Synchronisierung fehlgeschlagen: ${result.failed} von ${result.total} Fahrten konnten nicht gesendet werden.",
                  ),
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Fehler beim Synchronisieren: ${e.toString()}"),
              ),
            );
          }
        }
      },
      child: const Text("Fahrten mit Server synchronisieren"),
    );
  }
}

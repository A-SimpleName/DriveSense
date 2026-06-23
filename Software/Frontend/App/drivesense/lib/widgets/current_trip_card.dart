import 'package:flutter/material.dart';
import 'package:drivesense/config/app_colors.dart';

class CurrentTripCard extends StatelessWidget {
  const CurrentTripCard({
    super.key,
    required this.onStop,
    required this.onAbort,
    required this.onPauseResume,
    required this.currentTripDistance,
    required this.currentTripDuration,
    required this.currentVehicle,
    required this.isPaused,
    required this.isStoppingTrip,
    required this.isChangingPauseState,
  });

  final VoidCallback onStop;
  final VoidCallback onAbort;
  final VoidCallback onPauseResume;
  final double currentTripDistance;
  final Duration currentTripDuration;
  final String currentVehicle;
  final bool isPaused;
  final bool isStoppingTrip;
  final bool isChangingPauseState;

  @override
  Widget build(BuildContext context) {
    final bool isTripActionBlocked = isStoppingTrip || isChangingPauseState;

    return Card(
      elevation: 0,
      color: AppColors.primaryBlue.withAlpha(77),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.black),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(2.0),
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              childAspectRatio: 4.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                Text('Aktuelle Fahrt: '),
                Text(''),
                Text('Distanz: '),
                Text('${(currentTripDistance / 1000).toStringAsFixed(2)} km'),
                Text('Zeit: '),
                Text(currentTripDuration.toString().split('.').first),
                Text('Status: '),
                Text(isPaused ? 'Pausiert' : 'Aktiv'),
                Text('Aktives Fahrzeug: '),
                Text(currentVehicle),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: isTripActionBlocked ? null : onStop,
                style: ButtonStyle(
                  fixedSize: WidgetStateProperty.all(Size.fromWidth(200)),
                ),
                child: isStoppingTrip
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Fahrt beenden'),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: isTripActionBlocked ? null : onPauseResume,
                style: ButtonStyle(
                  fixedSize: WidgetStateProperty.all(Size.fromWidth(200)),
                ),
                child: isChangingPauseState
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isPaused ? 'Fahrt fortsetzen' : 'Fahrt pausieren'),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: isTripActionBlocked ? null : onAbort,
                style: ButtonStyle(
                  fixedSize: WidgetStateProperty.all(Size.fromWidth(200)),
                ),
                child: const Text(
                  'Fahrt abbrechen',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

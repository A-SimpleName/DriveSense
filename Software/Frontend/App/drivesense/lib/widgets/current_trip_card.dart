import 'package:flutter/material.dart';
import 'package:drivesense/constants/app_colors.dart';

class CurrentTripCard extends StatefulWidget {
  const CurrentTripCard({super.key, required this.onStop, required this.onAbort, required this.currentTripDistance, required this.currentTripDuration, required this.currentVehicle});

  final VoidCallback onStop;
  final VoidCallback onAbort;
  final double currentTripDistance;
  final Duration currentTripDuration;
  final String currentVehicle;

  @override
  State<CurrentTripCard> createState() => _CurrentTripCardState();
}

class _CurrentTripCardState extends State<CurrentTripCard> {
  bool isPaused = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.primaryPurple.withValues(alpha: 0.4),
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
                Text('${(widget.currentTripDistance / 1000).toStringAsFixed(2)} km'),
                Text('Zeit: '),
                Text(widget.currentTripDuration.toString().split('.').first),
                Text('Aktives Fahrzeug: '),
                Text(widget.currentVehicle),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Text('Eingebettetes Karten-Widget hier'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () => {
                  widget.onStop()
                },
                style: ButtonStyle(
                  fixedSize: WidgetStateProperty.all(Size.fromWidth(200)),
                ),
                child: const Text('Fahrt beenden'),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () => {
                  _onPauseResumeTrip()
                },
                style: ButtonStyle(
                  fixedSize: WidgetStateProperty.all(Size.fromWidth(200)),
                ),
                child: Text(isPaused ? 'Fahrt fortsetzen' : 'Fahrt pausieren'),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () => {
                  widget.onAbort()
                },
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

  void _onPauseResumeTrip() {
    setState(() {
      isPaused = !isPaused;
    });
  }
}

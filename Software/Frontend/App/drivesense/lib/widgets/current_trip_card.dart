import 'package:flutter/material.dart';
import 'package:drivesense/values/app_colors.dart';

class CurrentTripCard extends StatefulWidget {
  const CurrentTripCard({super.key, required this.onStop});

  final VoidCallback onStop;

  @override
  State<CurrentTripCard> createState() => _CurrentTripCardState();
}

class _CurrentTripCardState extends State<CurrentTripCard> {
  double currentTripDistance = 0;
  Duration currentTripDuration = Duration.zero;
  String currentVehicle = 'BMW i3';
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
                Text('${(currentTripDistance / 1000).toStringAsFixed(2)} km'),
                Text('Zeit: '),
                Text(currentTripDuration.toString().split('.').first),
                Text('Aktives Fahrzeug: '),
                Text(currentVehicle),
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
                  widget.onStop()
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

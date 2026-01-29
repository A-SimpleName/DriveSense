import 'package:flutter/material.dart';
import 'package:drivesense/constants/app_colors.dart';

class LastTripCard extends StatefulWidget {
  const LastTripCard({super.key});

  @override
  State<LastTripCard> createState() => _LastTripCardState();
}

class _LastTripCardState extends State<LastTripCard> {
  final int? lastTripId = 1;
  final double lastTripDistance = 7812.0;
  final Duration lastTripDuration = const Duration(
    hours: 0,
    minutes: 15,
    seconds: 42,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryPurple.withValues(alpha: 0.4),
      elevation: 0,
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
                Text('Letzte Fahrt: '),
                Text(''),
                Text('Distanz: '),
                Text(
                  lastTripId != null
                      ? '${(lastTripDistance / 1000).toStringAsFixed(2)} km'
                      : '--',
                ),
                Text('Zeit: '),
                Text(
                  lastTripId != null
                      ? lastTripDuration.toString().split('.').first
                      : '--',
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () => {
                  // Todo: navigate to trip details page for last Trip
                },
                style: ButtonStyle(
                  fixedSize: WidgetStateProperty.all(Size.fromWidth(200)),
                ),
                child: Text('Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

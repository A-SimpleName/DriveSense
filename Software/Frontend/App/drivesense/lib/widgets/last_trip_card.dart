import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/config/app_colors.dart';
import 'package:drivesense/widgets/protocol_trip_fields.dart';
import 'package:drivesense/widgets/trip_detail_dialog.dart';
import 'package:flutter/material.dart';

class LastTripCard extends StatefulWidget {
  final TripSummary? lastTrip;

  const LastTripCard({super.key, required this.lastTrip});

  @override
  State<LastTripCard> createState() => _LastTripCardState();
}

class _LastTripCardState extends State<LastTripCard> {
  Duration? get lastTripDuration {
    final TripSummary? trip = widget.lastTrip;
    if (trip == null) {
      return null;
    }
    if (trip.durationSeconds > 0) {
      return Duration(seconds: trip.durationSeconds);
    }
    return trip.endTime?.difference(trip.startTime);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryBlue.withAlpha(77),
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
                  widget.lastTrip != null
                      ? '${widget.lastTrip!.distanceKm.toStringAsFixed(2)} km'
                      : '--',
                ),
                Text('Zeit: '),
                Text(
                  widget.lastTrip?.endTime != null && lastTripDuration != null
                      ? lastTripDuration.toString().split('.').first
                      : '--',
                ),
                Text('Start-km: '),
                Text(
                  widget.lastTrip != null
                      ? formatProtocolMileage(widget.lastTrip!.startMileage)
                      : '--',
                ),
                Text('End-km: '),
                Text(
                  widget.lastTrip != null
                      ? formatProtocolMileage(widget.lastTrip!.endMileage)
                      : '--',
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: widget.lastTrip == null
                    ? null
                    : () => showTripDetailDialog(context, widget.lastTrip!),
                icon: const Icon(Icons.info_outline),
                style: ButtonStyle(
                  fixedSize: WidgetStateProperty.all(Size.fromWidth(200)),
                ),
                label: const Text('Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

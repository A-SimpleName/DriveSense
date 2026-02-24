import 'package:drivesense/widgets/current_trip_card.dart';
import 'package:drivesense/widgets/start_trip_card.dart';
import 'package:drivesense/widgets/last_trip_card.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/services/gps_tracking.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:drivesense/widgets/position_widgets.dart';

class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  bool hasActiveTrip = false;
  double currentLatitude = 0.0;
  double currentLongitude = 0.0;
  Timer? _gpsTimer;
  List<Position> trackingPositions = [];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: hasActiveTrip
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurrentTripCard(onStop: _onStopTrip),
            const SizedBox(height: 12),
            Text('Lat: $currentLatitude'),
            Text('Lng: $currentLongitude'),
            const SizedBox(height: 16),

            Expanded(
              child: PositionListWidget(
                positions: trackingPositions,
              ),
            ),
          ],
        )
        : Column(
          children: [
            StartTripCard(onStart: _onStartTrip),
            const SizedBox(height: 24),
            LastTripCard(),
          ],
        ),
      )
    );
  }

  void _onStartTrip() {
    setState(() {
      hasActiveTrip = true;
    });
    _startGpsLogging();
  }

  void _onStopTrip() {
    setState(() {
      hasActiveTrip = false;
    });
    _gpsTimer?.cancel();
    _gpsTimer = null;
  }

  void _startGpsLogging() {
    _gpsTimer ??= Timer.periodic(const Duration(seconds: 10), (timer) async {
      final position = await determinePosition();        
      setState(() {
        trackingPositions.add(position);
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
      });
    });
  }
}
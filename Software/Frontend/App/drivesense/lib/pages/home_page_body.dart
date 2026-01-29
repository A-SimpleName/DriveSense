import 'package:drivesense/widgets/current_trip_card.dart';
import 'package:drivesense/widgets/start_trip_card.dart';
import 'package:drivesense/widgets/last_trip_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tracking_provider.dart';

class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  @override
  Widget build(BuildContext context) {
    final trackingProvider = context.watch<TrackingProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: trackingProvider.isTracking
            ? CurrentTripCard(onStop: stopTrip)
            : Column(
                children: [
                  StartTripCard(onStart: startTrip),
                  const SizedBox(height: 24),
                  LastTripCard(),
                ],
              ),
      ),
    );
  }

  // normale Methoden statt Inline-Funktionen
  void startTrip() async {
    final trackingProvider = context.read<TrackingProvider>();
    await trackingProvider.startTracking();
  }

  void stopTrip() async {
    final trackingProvider = context.read<TrackingProvider>();
    await trackingProvider.stopTracking();
  }
}
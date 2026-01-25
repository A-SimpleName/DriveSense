import 'package:drivesense/widgets/current_trip_card.dart';
import 'package:drivesense/widgets/start_trip_card.dart';
import 'package:drivesense/widgets/last_trip_card.dart';
import 'package:flutter/material.dart';

class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  bool hasActiveTrip = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: hasActiveTrip
            ? CurrentTripCard()
            : Column(
                children: [
                  StartTripCard(),
                  const SizedBox(height: 24),
                  LastTripCard(),
                ],
              ),
      ),
    );
  }
}

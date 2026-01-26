import 'package:flutter/material.dart';
import '../providers/tracking_provider.dart';
import 'package:provider/provider.dart';

class HomePageBody extends StatelessWidget {
  const HomePageBody({super.key});

  @override
Widget build(BuildContext context) {
  final tracking = context.watch<TrackingProvider>().tracking;
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Tracking Status: ${tracking ? "Active" : "Inactive"}'),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            if (tracking) {
              context.read<TrackingProvider>().stopTracking();
            } else {
              context.read<TrackingProvider>().startTracking();
            }
          },
          child: Text(tracking ? 'Stop Tracking' : 'Start Tracking'),
        ),
      ],
    ),
  );
}

  // @override
  // Widget build(BuildContext context) {
  //   return Center(
  //     child: Text('This is the Home Page Body')
      
  //   );
  // }
}

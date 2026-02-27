import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:drivesense/model/trackingpoint.dart';

class PositionWidget extends StatelessWidget {
  final Trackingpoint position;

  const PositionWidget({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Position aufgenommen am ${position.timestamp}'),
      subtitle: Text('Long: ${position.latitude}, Lat: ${position.longitude}'),
    );
  }
}

class PositionListWidget extends StatelessWidget {
  final List<Trackingpoint> positions;

  const PositionListWidget({super.key, required this.positions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: positions.length,
      itemBuilder: (context, index) {
        return PositionWidget(position: positions[index]);
      },
    );
  }
}
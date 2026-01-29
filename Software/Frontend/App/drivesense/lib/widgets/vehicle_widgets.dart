import 'package:flutter/material.dart';
import 'package:drivesense/constants/app_interfaces.dart';

class VehicleWidget extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleWidget({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${vehicle.make} ${vehicle.model}'),
      subtitle: Text('Kennzeichen: ${vehicle.licensePlate}'),
    );
  }
}

class VehicleListWidget extends StatelessWidget {
  final List<Vehicle> vehicles;

  const VehicleListWidget({super.key, required this.vehicles});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: vehicles
          .map((vehicle) => VehicleWidget(vehicle: vehicle))
          .toList(),
    );
  }
}

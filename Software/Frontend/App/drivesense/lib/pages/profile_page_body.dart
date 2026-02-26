import 'package:drivesense/widgets/vehicle_widgets.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/model/vehicle.dart';

class ProfilePageBody extends StatelessWidget {
  const ProfilePageBody({super.key});


  @override
  Widget build(BuildContext context) {
    final String userName = "Eric Hölzl";
    final String profileType = "Fahrschüler";
    final List<Vehicle> registeredVehicles = [
      Vehicle(id: 1, userId: 1, model: "Volkswagen Golf", licensePlate: "AB-1234", mileage: 50000),
      Vehicle(id: 2, userId: 1, model: "BMW 3er", licensePlate: "CD-5678", mileage: 30000),
    ];

    return SafeArea(
      child: Padding(padding: EdgeInsets.all(16.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $userName', ),
            Text('Profiltyp: $profileType', ),
            Text('Registrierte Fahrzeuge:', ),
            VehicleListWidget(vehicles: registeredVehicles),
          ],
        ),
      ),
    );
  }
}
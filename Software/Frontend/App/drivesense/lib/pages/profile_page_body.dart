import 'package:drivesense/widgets/vehicle_widgets.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/constants/app_interfaces.dart';

class ProfilePageBody extends StatelessWidget {
  const ProfilePageBody({super.key});


  @override
  Widget build(BuildContext context) {
    final String userName = "Eric Hölzl";
    final String profileType = "Fahrschüler";
    final List<Vehicle> registeredVehicles = [
      Vehicle(id: "1", make: "Volkswagen", model: "Golf", year: 2020, licensePlate: "AB-1234"),
      Vehicle(id: "2", make: "BMW", model: "3er", year: 2018, licensePlate: "CD-5678"),
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
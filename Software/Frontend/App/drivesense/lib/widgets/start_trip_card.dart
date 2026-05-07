import 'package:flutter/material.dart';
import 'package:drivesense/config/app_colors.dart';
import 'package:drivesense/model/vehicle.dart';

class StartTripCard extends StatefulWidget {
  const StartTripCard({
    super.key,
    required this.onStart,
    required this.vehicles,
    required this.selectedVehicleId,
    required this.onVehicleChanged,
  });

  final VoidCallback onStart;
  final List<Vehicle> vehicles;
  final int selectedVehicleId;
  final ValueChanged<int> onVehicleChanged;

  @override
  State<StartTripCard> createState() => _StartTripCardState();
}

class _StartTripCardState extends State<StartTripCard> {
  @override
  Widget build(BuildContext context) {
    final int? selectedVehicleId = widget.vehicles.any(
      (Vehicle vehicle) => vehicle.id == widget.selectedVehicleId,
    )
        ? widget.selectedVehicleId
        : null;

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
              childAspectRatio: 3.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                Text('Neue Fahrt starten: '),
                Text(''),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Fahrzeug: '),
                ),
                DropdownButtonFormField<int>(
                  initialValue: selectedVehicleId,
                  isExpanded: true,
                  hint: const Text('Fahrzeug auswaehlen'),
                  items: widget.vehicles
                      .map(
                        (Vehicle vehicle) => DropdownMenuItem<int>(
                          value: vehicle.id,
                          child: Text(
                            '${vehicle.model} (${vehicle.licensePlate})',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (int? vehicleId) {
                    if (vehicleId != null) {
                      widget.onVehicleChanged(vehicleId);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: widget.vehicles.isEmpty ? null : widget.onStart,
                style: ButtonStyle(
                  fixedSize: WidgetStateProperty.all(Size.fromWidth(200)),
                ),
                child: Text('Fahrt Starten'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

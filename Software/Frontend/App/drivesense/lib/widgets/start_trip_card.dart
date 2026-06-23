import 'package:drivesense/runtime_store.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/config/app_colors.dart';
import 'package:drivesense/model/vehicle.dart';
import 'package:drivesense/model/protocol.dart';

class StartTripCard extends StatefulWidget {
  const StartTripCard({
    super.key,
    required this.onStart,
    required this.protocols,
    required this.selectedProtocolId,
    required this.onProtocolChanged,
    required this.vehicles,
    required this.selectedVehicleId,
    required this.onVehicleChanged,
    required this.isStartingTrip,
  });

  final VoidCallback onStart;
  final List<Protocol> protocols;
  final int selectedProtocolId;
  final ValueChanged<int> onProtocolChanged;
  final List<Vehicle> vehicles;
  final int selectedVehicleId;
  final ValueChanged<int> onVehicleChanged;
  final bool isStartingTrip;

  @override
  State<StartTripCard> createState() => _StartTripCardState();
}

class _StartTripCardState extends State<StartTripCard> {
  @override
  Widget build(BuildContext context) {
    final int? selectedVehicleId =
        widget.vehicles.any(
          (Vehicle vehicle) => vehicle.id == widget.selectedVehicleId,
        )
        ? widget.selectedVehicleId
        : null;
    final int? selectedProtocolId =
        widget.protocols.any(
          (Protocol protocol) => protocol.id == widget.selectedProtocolId,
        )
        ? widget.selectedProtocolId
        : null;
    final bool canStartTrip =
        widget.vehicles.isNotEmpty &&
        widget.protocols.isNotEmpty &&
        selectedVehicleId != null &&
        selectedProtocolId != null &&
        !widget.isStartingTrip;

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
                  key: ValueKey<String>('vehicle-$selectedVehicleId'),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Protokoll: '),
                ),
                DropdownButtonFormField<int>(
                  key: ValueKey<String>('protocol-$selectedProtocolId'),
                  initialValue: selectedProtocolId,
                  isExpanded: true,
                  hint: Text(
                    widget.protocols.isEmpty
                        ? 'Keine Protokolle'
                        : 'Protokoll auswaehlen',
                  ),

                  items: widget.protocols
                      .map(
                        (Protocol protocol) => DropdownMenuItem<int>(
                          value: protocol.id,
                          child: Text(protocol.name),
                        ),
                      )
                      .toList(),
                  onChanged: widget.protocols.isEmpty
                      ? null
                      : (int? protocolId) {
                          if (protocolId != null) {
                            widget.onProtocolChanged(protocolId);
                          }
                        },
                ),
                if (RuntimeStore.getActiveProfileRole() == 'BERUFSFAHRER') ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Typ / Zweck: '),
                  ),
                  TextFormField(
                    key: ValueKey<String>(
                      'trip-purpose-${RuntimeStore.getCurrentProtocolId()}',
                    ),
                    initialValue: RuntimeStore.getCurrentTripPurpose(),
                    decoration: const InputDecoration(hintText: 'Typ / Zweck'),
                    onChanged: (String value) {
                      RuntimeStore.setCurrentTripPurpose(value);
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: canStartTrip ? widget.onStart : null,
                style: ButtonStyle(
                  fixedSize: WidgetStateProperty.all(Size.fromWidth(200)),
                ),
                child: widget.isStartingTrip
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Fahrt Starten'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

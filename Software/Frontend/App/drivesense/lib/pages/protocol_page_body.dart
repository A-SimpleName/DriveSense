import 'package:flutter/material.dart';
import 'package:drivesense/widgets/protocol_table.dart';
import 'package:drivesense/widgets/ds_snyc_trips_button.dart';
import 'package:drivesense/services/trip_sync_service.dart';

class ProtocolPageBody extends StatelessWidget {
  final TripSyncService tripSyncService;

  const ProtocolPageBody({super.key, required this.tripSyncService});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        Padding(padding: EdgeInsets.all(8.0), child: ProtocolTable()),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DsSnycTripsButton(tripSyncService: tripSyncService),
        ),
      ],) 
      
    );
  }
}

import 'package:drivesense/repository/pending_trip_repository.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/trip_service.dart';
import 'package:drivesense/widgets/ds_app_bar.dart';
import 'package:drivesense/widgets/ds_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/pages/home_page_body.dart';
import 'package:drivesense/pages/protocol_page_body.dart';
import 'package:drivesense/pages/profile_page_body.dart';
import 'package:drivesense/services/trip_sync_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndexBottomNav = 0;
  String _currentAppBarTitle = 'Übersicht';
  late final PendingTripRepository pendingTripRepository;
  late final TripSyncService tripSyncService;
  late final TripService tripService;
  

  @override
  void initState() {
    super.initState();

    tripService = TripService();
    pendingTripRepository = PendingTripRepository();
    tripSyncService = TripSyncService(
      pendingTripRepository: pendingTripRepository,
      tripService: tripService
    );

    Future.microtask(_syncPendingTrips);
  }

  Future<void> _syncPendingTrips() async {
    await tripSyncService.syncPendingTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(title: _currentAppBarTitle),
      body: IndexedStack(
        index: _selectedIndexBottomNav,
        children: [
          HomePageBody(tripSyncService: tripSyncService),
          ProtocolPageBody(tripSyncService: tripSyncService),
          ProfilePageBody(),
        ],
      ),
      bottomNavigationBar: DsBottomNavigation(
        currentIndex: _selectedIndexBottomNav,
        onTap: (int index) {
          setState(() {
            _selectedIndexBottomNav = index;
            switch (index) {
              case 0:
                _currentAppBarTitle = 'Übersicht';
                break;
              case 1:
                _currentAppBarTitle = 'Protokoll';
                RuntimeStore.refreshTrips(); // TODO: ProfileId dynamisch setzen
                break;
              case 2:
                _currentAppBarTitle = 'Profil';
                break;
              default:
                _currentAppBarTitle = 'Übersicht';
            }
          });
        },
      ),
    );
  }
}

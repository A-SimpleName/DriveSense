import 'package:drivesense/repository/trip_repository.dart';
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
  late final TripRepository isarTripRepository;
  late final TripSyncService tripSyncService;
  late final TripService tripService;
  

  @override
  void initState() {
    super.initState();
    debugPrint('[MainPage.initState] START');

    tripService = TripService();
    isarTripRepository = TripRepository();
    tripSyncService = TripSyncService(
      isarTripRepository: isarTripRepository,
      tripService: tripService
    );

    debugPrint('[MainPage.initState] Scheduling _syncPendingTrips via microtask');
    Future.microtask(_syncPendingTrips);
  }

  Future<void> _syncPendingTrips() async {
    debugPrint('[_syncPendingTrips] START');
    try {
      debugPrint('[_syncPendingTrips] Calling syncPendingTrips...');
      await tripSyncService.syncPendingTrips();
      debugPrint('[_syncPendingTrips] syncPendingTrips completed');
    } catch (e) {
      debugPrint('[_syncPendingTrips] syncPendingTrips error (continuing anyway): $e');
    }
    // Refresh from server after sync to repopulate local DB if cleared by user
    // (e.g., via phone settings "Clear app data")
    // This MUST run regardless of sync errors
    debugPrint('[_syncPendingTrips] Calling refreshTrips...');
    await RuntimeStore.refreshTrips();
    debugPrint('[_syncPendingTrips] DONE');
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

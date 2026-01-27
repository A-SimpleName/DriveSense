import 'package:drivesense/widgets/ds_app_bar.dart';
import 'package:drivesense/widgets/ds_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/pages/home_page_body.dart';
import 'package:drivesense/pages/protocol_page_body.dart';
import 'package:drivesense/pages/profile_page_body.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndexBottomNav = 0;
  String _currentAppBarTitle = 'Übersicht';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(title: _currentAppBarTitle),
      body: IndexedStack(
        index: _selectedIndexBottomNav,
        children: [
          HomePageBody(),
          ProtocolPageBody(),
          ProfilePageBody(),
        ],
      ),
      bottomNavigationBar: DsBottomNavigation(
        currentIndex: _selectedIndexBottomNav,
        onTap: (int index) {
          setState(() {
            _selectedIndexBottomNav = index;
            //_changePageBody(index);
          });
        },
      ),
    );
  }


  /* executed when switching to another tab in the bottom navigation */
  /* void _changePageBody(int index) {
    switch (index) {
      case 0:
        _currentAppBarTitle = 'Übersicht';
        break;
      case 1:
        _currentAppBarTitle = 'Protokoll';
        break;
      case 2:
        _currentAppBarTitle = 'Profil';
        break;
      default:
        _currentAppBarTitle = 'Übersicht';
    }
  } */
}

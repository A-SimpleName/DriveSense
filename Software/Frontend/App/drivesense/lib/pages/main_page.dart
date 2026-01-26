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
  StatelessWidget _currentBody = const HomePageBody();
  String _currentAppBarTitle = 'DriveSense';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(title: _currentAppBarTitle),
      body: _currentBody,
      bottomNavigationBar: DsBottomNavigation(
        currentIndex: _selectedIndexBottomNav,
        onTap: (int index) {
          setState(() {
            _selectedIndexBottomNav = index;
            _changePageBody(index);
          });
        },
      ),
    );
  }


  /* executed when switching to another tab in the bottom navigation */
  void _changePageBody(int index) {
    switch (index) {
      case 0:
        _currentBody = const HomePageBody();
        _currentAppBarTitle = 'DriveSense';
        break;
      case 1:
        _currentBody = const ProtocolPageBody();
        _currentAppBarTitle = 'Protocols';
        break;
      case 2:
        _currentBody = const ProfilePageBody();
        _currentAppBarTitle = 'Profile';
        break;
      default:
        _currentBody = const HomePageBody();
        _currentAppBarTitle = 'DriveSense';
    }
  }
}

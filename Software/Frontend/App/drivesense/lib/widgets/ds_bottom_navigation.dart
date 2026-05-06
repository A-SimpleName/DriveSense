import 'package:flutter/material.dart';
import 'package:drivesense/config/app_colors.dart';

class DsBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final void Function(int)? onTap;

  const DsBottomNavigation({super.key, required this.currentIndex, this.onTap});

  @override
  State<DsBottomNavigation> createState() => _DsBottomNavigationState();
}

class _DsBottomNavigationState extends State<DsBottomNavigation> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Protocols'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
      unselectedItemColor: Colors.grey,
      selectedItemColor: AppColors.primaryBlue,
      backgroundColor: Colors.white,
    );
  }
}

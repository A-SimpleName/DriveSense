import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DriveSense')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.all(16.0),
          
        )
      )
      

    );
  }
}

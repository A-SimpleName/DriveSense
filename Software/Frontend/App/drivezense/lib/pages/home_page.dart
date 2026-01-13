import 'package:flutter/material.dart';
import 'package:drivezense/services/weather_service.dart';
import 'package:nowa_runtime/nowa_runtime.dart';

@NowaGenerated({'auto-width': 1013})
class HomePage extends StatelessWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drivezensus')),
      body: SafeArea(
        child: Center(
          child: FutureBuilder<num>(
            future: getTemperatures(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Lade…');
              }
              if (snapshot.hasError) {
                return Text('Fehler: ${snapshot.error}');
              }
              return Text('${snapshot.data}');
            },
          ),
        ),
      ),
    );
  }
}

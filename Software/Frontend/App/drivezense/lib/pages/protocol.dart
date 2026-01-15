import 'package:flutter/material.dart';
import 'package:drivezense/services/weather_service.dart';
import 'package:nowa_runtime/nowa_runtime.dart';

class ProtocolPage extends StatelessWidget {
  const ProtocolPage({super.key});

  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: 'ProtocolPage',
      home: Scaffold(
        appBar: AppBar(title: Text('Protokoll')),
        body: Column(
          children: <Widget>[
            DataTable(
                columns: [
                  DataColumn(label: Text('Zeitstempel')),
                  DataColumn(label: Text('Geschwindigkeit')),
                  DataColumn(label: Text('Beschleunigung X')),
                  DataColumn(label: Text('Beschleunigung Y')),
                  DataColumn(label: Text('Beschleunigung Z')),
                  DataColumn(label: Text('Gyroskop X')),
                  DataColumn(label: Text('Gyroskop Y')),
                  DataColumn(label: Text('Gyroskop Z')),
                ],
                rows: List<DataRow>.generate(10, (index) {
                  return DataRow(cells: [
                    DataCell(Text(
                        '2024-01-01 12:00:${index.toString().padLeft(2, '0')}')),
                    DataCell(Text('${50 + index} km/h')),
                    DataCell(Text('${0.1 * index} m/s²')),
                    DataCell(Text('${0.2 * index} m/s²')),
                    DataCell(Text('${0.3 * index} m/s²')),
                    DataCell(Text('${1.0 * index} °/s')),
                    DataCell(Text('${1.5 * index} °/s')),
                    DataCell(Text('${2.0 * index} °/s')),
                  ]);
                })),

                ElevatedButton(onPressed: () {
                  Navigator.pop(context);
                }, 
                child: Text('Zurück')),
          ],
        ),
      ),
    );
  }
}

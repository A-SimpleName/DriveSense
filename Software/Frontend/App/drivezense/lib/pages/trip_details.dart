import 'package:flutter/material.dart';
import 'package:drivezense/services/weather_service.dart';
import 'google'

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
            ,

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

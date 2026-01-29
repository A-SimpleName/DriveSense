import 'package:flutter/material.dart';
import 'package:drivesense/widgets/protocol_table.dart';

class ProtocolPageBody extends StatelessWidget {
  const ProtocolPageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(padding: EdgeInsets.all(8.0), child: ProtocolTable()),
    );
  }
}

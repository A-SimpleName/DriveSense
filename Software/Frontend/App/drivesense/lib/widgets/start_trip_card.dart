import 'package:flutter/material.dart';
import 'package:drivesense/values/app_colors.dart';

class StartTripCard extends StatefulWidget {
  const StartTripCard({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  State<StartTripCard> createState() => _StartTripCardState();
}

class _StartTripCardState extends State<StartTripCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryPurple.withValues(alpha: 0.4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.black),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(2.0),
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              childAspectRatio: 4.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                Text('Neue Fahrt starten: '),
                Text(''),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Fahrzeug: '),
                ),
                DropdownMenu<String>(
                  dropdownMenuEntries: [
                    DropdownMenuEntry(value: 'BMW i3', label: 'BMW i3'),
                    DropdownMenuEntry(
                      value: 'Skoda Octavia',
                      label: 'Skoda Octavia',
                    ),
                  ],
                  initialSelection: 'BMW i3',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () => {
                  // TODO: implement start trip functionality
                  widget.onStart(),
                },
                style: ButtonStyle(
                  fixedSize: WidgetStateProperty.all(Size.fromWidth(200)),
                ),
                child: Text('Fahrt Starten'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

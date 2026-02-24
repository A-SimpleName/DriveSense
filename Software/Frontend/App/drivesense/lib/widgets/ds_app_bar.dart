import 'package:drivesense/constants/app_assets.dart';
import 'package:drivesense/constants/app_colors.dart';
import 'package:flutter/material.dart';

class DsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const DsAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      leading: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 1.3,
        child: Image.asset(AppAssetPaths.logoPath),
      ),
      foregroundColor: Colors.white,
      backgroundColor: AppColors.primaryPurple,
      actions: [
        PopupMenuButton<String>(
          itemBuilder: (BuildContext context) {
            return {'Einstellungen', 'Account', 'Abmelden'}.map((
              String choice,
            ) {
              return PopupMenuItem<String>(value: choice, child: Text(choice));
            }).toList();
          },
          onSelected: (String choice) => {
            switch (choice) {
              'Einstellungen' => {Navigator.pushNamed(context, '/settings')},
              'Account' => {Navigator.pushNamed(context, '/account')},
              'Abmelden' => {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    actionsAlignment: MainAxisAlignment.center,
                    actionsOverflowAlignment: OverflowBarAlignment.center,
                    title: Text('Möchten Sie sich abmelden?'),
                    actions: [
                      TextButton(
                        onPressed: () => {Navigator.pop(context)},
                        child: Text('Abbrechen'),
                      ),
                      TextButton(
                        onPressed: () => {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            'LoginPage',
                            (route) => false,
                          ),
                        },
                        child: Text('Abmelden'),
                      ),
                    ],
                  ),
                ),
              },
              // TODO: Handle this case.
              String() => throw UnimplementedError(),
            },
          },
          icon: Icon(Icons.settings),
        ),
      ],
      centerTitle: true,
    );
  }
}

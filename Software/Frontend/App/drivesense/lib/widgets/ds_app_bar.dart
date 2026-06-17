import 'package:drivesense/config/app_assets.dart';
import 'package:drivesense/config/app_colors.dart';
import 'package:drivesense/services/sign_in_and_sign_up.dart';
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
            return {'Account', 'Abmelden'}.map((String choice) {
              return PopupMenuItem<String>(value: choice, child: Text(choice));
            }).toList();
          },
          onSelected: (String choice) {
            switch (choice) {
              case 'Account':
                Navigator.pushNamed(context, 'AccountPage');
                break;

              case 'Abmelden':
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Möchten Sie sich abmelden?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Abbrechen'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await SignInAndSignUp.signOut();
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            'SignInPage',
                            (route) => false,
                          );
                        },
                        child: const Text('Abmelden'),
                      ),
                    ],
                  ),
                );
                break;
            }
          },
          icon: const Icon(Icons.settings),
        ),
      ],
    );
  }
}

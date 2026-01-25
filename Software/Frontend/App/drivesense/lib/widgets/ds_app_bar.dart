import 'package:drivesense/values/app_assets.dart';
import 'package:drivesense/values/app_colors.dart';
import 'package:flutter/material.dart';


class DsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const DsAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
        title: Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        leading: FractionallySizedBox(
          alignment: Alignment.centerLeft, 
          widthFactor: 1.3, 
          child: Image.asset(AppAssetPaths.logoPath)
        ),
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primaryPurple,
        actions: [
          IconButton(onPressed: () => {}, icon: Icon(Icons.settings))
        ],
        centerTitle: true,
      );
  }
}


import 'package:drivesense/values/app_colors.dart';
import 'package:drivesense/widgets/ds_app_bar.dart';
import 'package:flutter/material.dart';

class DsAuthScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const DsAuthScaffold({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(title: title),
      body: SafeArea(
        child: ColoredBox(
          color: AppColors.primaryBlue,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool wide = constraints.maxWidth > 600;

              final double cardWidth = wide ? 420 : constraints.maxWidth * 0.85;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardWidth),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 18,
                            offset: Offset(0, 8),
                            color: Colors.black26,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: child
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );   
  }
}
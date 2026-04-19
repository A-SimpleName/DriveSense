import 'package:drivesense/model/profile.dart';
import 'package:drivesense/services/profile_service.dart';
import 'package:drivesense/widgets/ds_app_bar.dart';
import 'package:flutter/material.dart';

class ProfileSelectPage extends StatelessWidget {
  const ProfileSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(
        title: ('Profil auswählen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: FutureBuilder<List<Profile>>(
          future: ProfileService.fetchProfiles(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final List<Profile> profiles = snapshot.data ?? <Profile>[];
            if (profiles.isEmpty) {
              return const Center(child: Text('Keine Profile gefunden.'));
            }

            return ListView.separated(
              itemCount: profiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final Profile profile = profiles[index];
                return ListTile(
                  title: Text(profile.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final SelectProfileResponse result =
                        await ProfileService.selectProfile(profile.id);

                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(result.message)));

                    if (result.isSuccess) {
                      Navigator.pushNamedAndRemoveUntil(context, 'MainPage', (route) => false);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

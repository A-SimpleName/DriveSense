import 'package:drivesense/config/app_colors.dart';
import 'package:drivesense/model/profile.dart';
import 'package:drivesense/services/profile_service.dart';
import 'package:drivesense/widgets/ds_app_bar.dart';
import 'package:flutter/material.dart';

class ProfileSelectPage extends StatefulWidget {
  const ProfileSelectPage({super.key});

  @override
  State<ProfileSelectPage> createState() => _ProfileSelectPageState();
}

class _ProfileSelectPageState extends State<ProfileSelectPage> {
  late Future<List<Profile>> _profilesFuture;
  bool _isCreatingProfile = false;

  @override
  void initState() {
    super.initState();
    _profilesFuture = ProfileService.fetchProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DsAppBar(title: 'Profil auswaehlen'),
      body: SafeArea(
        child: ColoredBox(
          color: AppColors.primaryBlue,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
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
                    child: FutureBuilder<List<Profile>>(
                      future: _profilesFuture,
                      builder: (context, snapshot) {
                        final bool isLoading =
                            snapshot.connectionState == ConnectionState.waiting;
                        final List<Profile> profiles =
                            snapshot.data ?? <Profile>[];

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Profile',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _AddProfileButton(
                                  isLoading: _isCreatingProfile,
                                  onPressed: _isCreatingProfile
                                      ? null
                                      : _createProfile,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (isLoading)
                              const SizedBox(
                                height: 180,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (snapshot.hasError)
                              _ProfileMessage(
                                icon: Icons.error_outline,
                                text: 'Profile konnten nicht geladen werden.',
                                detail: '${snapshot.error}',
                              )
                            else if (profiles.isEmpty)
                              const _ProfileMessage(
                                icon: Icons.person_add_alt_1,
                                text: 'Keine Profile gefunden.',
                                detail:
                                    'Lege ein neues Profil an, um fortzufahren.',
                              )
                            else
                              _ProfileList(
                                profiles: profiles,
                                onProfileSelected: _selectProfile,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createProfile() async {
    setState(() {
      _isCreatingProfile = true;
    });

    try {
      final Profile? createdProfile =
          await ProfileService.createDefaultStudentProfile();

      if (!mounted) {
        return;
      }

      if (createdProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil konnte nicht erstellt werden.')),
        );
        return;
      }

      setState(() {
        _profilesFuture = ProfileService.fetchProfiles();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${createdProfile.name} wurde erstellt.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingProfile = false;
        });
      }
    }
  }

  Future<void> _selectProfile(Profile profile) async {
    final SelectProfileResponse result = await ProfileService.selectProfile(
      profile.id,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));

    if (result.isSuccess) {
      Navigator.pushNamedAndRemoveUntil(context, 'MainPage', (route) => false);
    }
  }
}

class _AddProfileButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _AddProfileButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: const Text('Profil'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _ProfileList extends StatelessWidget {
  final List<Profile> profiles;
  final ValueChanged<Profile> onProfileSelected;

  const _ProfileList({required this.profiles, required this.onProfileSelected});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: profiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final Profile profile = profiles[index];
        return Material(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryPurple.withAlpha(31),
              foregroundColor: AppColors.primaryPurple,
              child: const Icon(Icons.person),
            ),
            title: Text(
              profile.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: profile.role == null ? null : Text(profile.role!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onProfileSelected(profile),
          ),
        );
      },
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? detail;

  const _ProfileMessage({required this.icon, required this.text, this.detail});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.primaryBlue),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
    final _ProfileCreationData? creationData =
        await showDialog<_ProfileCreationData>(
          context: context,
          builder: (BuildContext context) => const _CreateProfileDialog(),
        );

    if (creationData == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isCreatingProfile = true;
    });

    try {
      final Profile? createdProfile = await ProfileService.createProfile(
        name: creationData.name,
        role: creationData.role,
      );

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

const List<_ProfileRoleOption> _profileRoleOptions = <_ProfileRoleOption>[
  _ProfileRoleOption(value: 'PRIVAT', label: 'Privat'),
  _ProfileRoleOption(value: 'FAHRSCHUELER', label: 'Fahrschueler'),
  _ProfileRoleOption(value: 'BERUFSFAHRER', label: 'Berufsfahrer'),
];

class _ProfileRoleOption {
  final String value;
  final String label;

  const _ProfileRoleOption({required this.value, required this.label});
}

class _ProfileCreationData {
  final String name;
  final String role;

  const _ProfileCreationData({required this.name, required this.role});
}

String _profileRoleLabel(String role) {
  final String normalizedRole = role.trim().toUpperCase();
  for (final _ProfileRoleOption option in _profileRoleOptions) {
    if (option.value == normalizedRole) {
      return option.label;
    }
  }
  return role;
}

class _CreateProfileDialog extends StatefulWidget {
  const _CreateProfileDialog();

  @override
  State<_CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends State<_CreateProfileDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String _selectedRole = _profileRoleOptions.first.value;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    Navigator.of(context).pop(
      _ProfileCreationData(
        name: _nameController.text.trim(),
        role: _selectedRole,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profil erstellen'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                final String name = value?.trim() ?? '';
                if (name.isEmpty) {
                  return 'Name darf nicht leer sein.';
                }
                if (name.length > 100) {
                  return 'Name darf maximal 100 Zeichen haben.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Profiltyp',
                border: OutlineInputBorder(),
              ),
              items: _profileRoleOptions
                  .map(
                    (_ProfileRoleOption option) => DropdownMenuItem<String>(
                      value: option.value,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedRole = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Erstellen')),
      ],
    );
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
            subtitle: profile.role == null
                ? null
                : Text(_profileRoleLabel(profile.role!)),
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

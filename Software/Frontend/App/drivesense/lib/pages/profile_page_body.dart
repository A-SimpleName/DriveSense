import 'dart:async';

import 'package:drivesense/config/app_colors.dart';
import 'package:drivesense/model/profile.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/profile_service.dart';
import 'package:drivesense/widgets/vehicle_widgets.dart';
import 'package:flutter/material.dart';

class ProfilePageBody extends StatefulWidget {
  const ProfilePageBody({super.key});

  @override
  State<ProfilePageBody> createState() => _ProfilePageBodyState();
}

class _ProfilePageBodyState extends State<ProfilePageBody> {
  Profile? _profile;
  bool _isLoading = true;
  bool _isSavingProfileName = false;
  bool _isDeletingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final List<Profile> profiles = await ProfileService.fetchProfiles();

    if (!mounted) return;

    final int? currentId = RuntimeStore.currentProfileId;
    Profile? selectedProfile;

    if (currentId != null) {
      try {
        selectedProfile = profiles.firstWhere((Profile p) => p.id == currentId);
      } catch (_) {
        selectedProfile = null;
      }
    }

    selectedProfile ??= profiles.isNotEmpty ? profiles.first : null;

    setState(() {
      _profile = selectedProfile;
      _isLoading = false;
    });
  }

  Future<void> _showEditProfileNameDialog() async {
    final Profile? profile = _profile;
    if (profile == null || _isSavingProfileName || _isDeletingProfile) {
      return;
    }

    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          _ProfileNameDialog(initialName: profile.name),
    );

    final String trimmedName = newName?.trim() ?? '';
    if (trimmedName.isEmpty || trimmedName == profile.name) {
      return;
    }

    if (!mounted) return;

    setState(() => _isSavingProfileName = true);

    final ProfileMutationResponse result =
        await ProfileService.updateProfileName(
          profile: profile,
          name: trimmedName,
        );

    if (!mounted) return;

    setState(() {
      _isSavingProfileName = false;
      if (result.isSuccess) {
        _profile = result.profile;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _deleteProfile() async {
    final Profile? profile = _profile;
    if (profile == null || _isDeletingProfile || _isSavingProfileName) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          _DeleteProfileDialog(profileName: profile.name),
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) return;

    setState(() => _isDeletingProfile = true);

    final ProfileMutationResponse result = await ProfileService.deleteProfile(
      profile.id,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      RuntimeStore.clearActiveProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.green),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        'ProfileSelectPage',
        (Route<dynamic> route) => false,
      );
      return;
    }

    setState(() => _isDeletingProfile = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildProfileOverview(),
            const SizedBox(height: 24),
            const VehicleTableWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOverview() {
    if (_isLoading) {
      return const Row(
        children: <Widget>[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Profil wird geladen...'),
        ],
      );
    }

    final Profile? profile = _profile;
    if (profile == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Kein Profil ausgewaehlt.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryPurple.withAlpha(31),
                  foregroundColor: AppColors.primaryPurple,
                  child: Text(
                    profile.name.isNotEmpty
                        ? profile.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Profil',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Typ: ${_profileRoleLabel(profile.role)}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Name bearbeiten',
                  onPressed: _isSavingProfileName || _isDeletingProfile
                      ? null
                      : _showEditProfileNameDialog,
                  icon: _isSavingProfileName
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _isDeletingProfile
                      ? null
                      : () {
                          Navigator.pushNamed(
                            context,
                            'ProfileSelectPage',
                          ).then((_) => _loadProfile());
                        },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Profil wechseln'),
                ),
                TextButton.icon(
                  onPressed: _isDeletingProfile || _isSavingProfileName
                      ? null
                      : _deleteProfile,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  icon: _isDeletingProfile
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  label: const Text('Profil loeschen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _profileRoleLabel(String? role) {
  switch (role?.trim().toUpperCase()) {
    case 'FAHRSCHUELER':
    case 'FAHRSCHULER':
    case 'FAHRSCH\u00dcLER':
      return 'Fahrschueler';
    case 'BERUFSFAHRER':
      return 'Berufsfahrer';
    case 'PRIVAT':
      return 'Privat';
    default:
      return role?.trim().isNotEmpty == true ? role!.trim() : 'Unbekannt';
  }
}

class _ProfileNameDialog extends StatefulWidget {
  final String initialName;

  const _ProfileNameDialog({required this.initialName});

  @override
  State<_ProfileNameDialog> createState() => _ProfileNameDialogState();
}

class _ProfileNameDialogState extends State<_ProfileNameDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profilname bearbeiten'),
      content: Form(
        key: _formKey,
        child: TextFormField(
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
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Speichern')),
      ],
    );
  }
}

class _DeleteProfileDialog extends StatefulWidget {
  final String profileName;

  const _DeleteProfileDialog({required this.profileName});

  @override
  State<_DeleteProfileDialog> createState() => _DeleteProfileDialogState();
}

class _DeleteProfileDialogState extends State<_DeleteProfileDialog> {
  static const int _deleteDelaySeconds = 5;

  Timer? _timer;
  int _secondsRemaining = _deleteDelaySeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profil loeschen'),
      content: Text(
        'Profil "${widget.profileName}" wirklich loeschen? '
        'Fahrzeuge und Gruppen werden getrennt. Fahrten und Protokolle bleiben erhalten.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _secondsRemaining == 0
              ? () => Navigator.of(context).pop(true)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(
            _secondsRemaining == 0
                ? 'Endgueltig loeschen'
                : 'Loeschen ($_secondsRemaining)',
          ),
        ),
      ],
    );
  }
}

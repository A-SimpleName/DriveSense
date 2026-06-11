import 'package:drivesense/config/app_colors.dart';
import 'package:drivesense/model/profile.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/group_service.dart';
import 'package:drivesense/services/profile_service.dart';
import 'package:drivesense/services/protocol_service.dart';
import 'package:drivesense/services/token_storage.dart';
import 'package:drivesense/services/vehicle_service.dart';
import 'package:drivesense/widgets/delayed_confirm_dialog.dart';
import 'package:drivesense/widgets/group_widgets.dart';
import 'package:drivesense/widgets/vehicle_widgets.dart';
import 'package:flutter/material.dart';

class ProfilePageBody extends StatefulWidget {
  final Future<void> Function()? onProtocolsChanged;

  const ProfilePageBody({super.key, this.onProtocolsChanged});

  @override
  State<ProfilePageBody> createState() => _ProfilePageBodyState();
}

class _ProfilePageBodyState extends State<ProfilePageBody> {
  Profile? _profile;

  bool _isLoading = true;
  bool _isSavingProfileName = false;
  bool _isDeletingProfile = false;
  bool _isAcceptingVehicleInvite = false;
  bool _isAcceptingGroupInvite = false;
  int _vehicleListVersion = 0;
  int _groupListVersion = 0;

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
      builder: (BuildContext context) => DelayedConfirmDialog(
        title: 'Profil loeschen',
        content:
            'Profil "${profile.name}" wirklich loeschen? '
            'Fahrzeuge und Gruppen werden getrennt. '
            'Fahrten und Protokolle bleiben erhalten.',
        confirmText: 'Endgueltig loeschen',
        delaySeconds: 5,
        confirmButtonColor: Colors.red,
      ),
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
      await TokenStorage.instance.clearProfile();

      if (!mounted) return;

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

  Future<void> _showAcceptVehicleInviteDialog() async {
    final Profile? profile = _profile;
    if (profile == null ||
        _isAcceptingVehicleInvite ||
        _isDeletingProfile ||
        _isSavingProfileName) {
      return;
    }

    final String? rawCode = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _VehicleInviteAcceptDialog(),
    );

    final String code = _extractInviteCode(rawCode ?? '');
    if (code.isEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() => _isAcceptingVehicleInvite = true);

    final VehicleActionResult result = await VehicleService.acceptVehicleInvite(
      code: code,
      profileId: profile.id,
    );

    if (!mounted) return;

    setState(() {
      _isAcceptingVehicleInvite = false;
      if (result.isSuccess) {
        _vehicleListVersion++;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _showAcceptGroupInviteDialog() async {
    final Profile? profile = _profile;
    if (profile == null ||
        _isAcceptingGroupInvite ||
        _isDeletingProfile ||
        _isSavingProfileName) {
      return;
    }

    final String? rawCode = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _GroupInviteAcceptCodeDialog(),
    );

    final String code = _extractInviteCode(rawCode ?? '');
    if (code.isEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() => _isAcceptingGroupInvite = true);

    final GroupInviteVerificationResult verification =
        await GroupService.verifyInvite(code);

    if (!mounted) return;

    if (!verification.isSuccess) {
      setState(() => _isAcceptingGroupInvite = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(verification.message),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Profile? selectedProfile = await showDialog<Profile>(
      context: context,
      builder: (BuildContext context) => _GroupInviteProfileDialog(
        profiles: verification.profiles,
        preferredProfileId: profile.id,
      ),
    );

    if (selectedProfile == null) {
      if (!mounted) return;
      setState(() => _isAcceptingGroupInvite = false);
      return;
    }

    final GroupActionResult result = await GroupService.acceptInvite(
      code: code,
      profileId: selectedProfile.id,
    );

    if (!mounted) return;

    setState(() {
      _isAcceptingGroupInvite = false;
      if (result.isSuccess) {
        _groupListVersion++;
      }
    });

    if (result.isSuccess && selectedProfile.id != profile.id) {
      final SelectProfileResponse switchResult =
          await ProfileService.selectProfile(selectedProfile.id);
      if (!mounted) return;

      if (!switchResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.message} Profilwechsel fehlgeschlagen: ${switchResult.message}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await _loadProfile();
    }

    if (result.isSuccess) {
      await _refreshProtocolsForActiveProfile();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _refreshProtocolsForActiveProfile() async {
    await ProtocolService.fetchProtocols();
    if (RuntimeStore.protocols.isEmpty) {
      await ProtocolService.ensureDefaultProtocolForActiveProfile();
    }
    await RuntimeStore.refreshTrips();
    await widget.onProtocolsChanged?.call();
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
            if (_profile != null) ...<Widget>[
              GroupTableWidget(
                key: ValueKey<String>(
                  'groups-${_profile!.id}-$_groupListVersion',
                ),
                currentProfileId: _profile!.id,
                onProtocolsChanged: _refreshProtocolsForActiveProfile,
              ),
              const SizedBox(height: 24),
            ],
            VehicleTableWidget(key: ValueKey<int>(_vehicleListVersion)),
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
                OutlinedButton.icon(
                  onPressed:
                      _isAcceptingVehicleInvite ||
                          _isDeletingProfile ||
                          _isSavingProfileName
                      ? null
                      : _showAcceptVehicleInviteDialog,
                  icon: _isAcceptingVehicleInvite
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mark_email_read_outlined),
                  label: const Text('Fahrzeugeinladung annehmen'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      _isAcceptingGroupInvite ||
                          _isDeletingProfile ||
                          _isSavingProfileName
                      ? null
                      : _showAcceptGroupInviteDialog,
                  icon: _isAcceptingGroupInvite
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.group_add_outlined),
                  label: const Text('Gruppeneinladung annehmen'),
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

String _extractInviteCode(String input) {
  final String trimmed = input.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final Uri? uri = Uri.tryParse(trimmed);
  final String? codeFromUri = uri?.queryParameters['code'];
  if (codeFromUri != null && codeFromUri.trim().isNotEmpty) {
    return codeFromUri.trim();
  }

  return trimmed;
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

class _VehicleInviteAcceptDialog extends StatefulWidget {
  const _VehicleInviteAcceptDialog();

  @override
  State<_VehicleInviteAcceptDialog> createState() =>
      _VehicleInviteAcceptDialogState();
}

class _VehicleInviteAcceptDialogState
    extends State<_VehicleInviteAcceptDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    Navigator.of(context).pop(_codeController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fahrzeugeinladung annehmen'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _codeController,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Link oder Code',
            border: OutlineInputBorder(),
          ),
          validator: (String? value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Bitte Link oder Code eingeben.';
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
        ElevatedButton(onPressed: _submit, child: const Text('Annehmen')),
      ],
    );
  }
}

class _GroupInviteAcceptCodeDialog extends StatefulWidget {
  const _GroupInviteAcceptCodeDialog();

  @override
  State<_GroupInviteAcceptCodeDialog> createState() =>
      _GroupInviteAcceptCodeDialogState();
}

class _GroupInviteAcceptCodeDialogState
    extends State<_GroupInviteAcceptCodeDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    Navigator.of(context).pop(_codeController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gruppeneinladung annehmen'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _codeController,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Link oder Code',
            border: OutlineInputBorder(),
          ),
          validator: (String? value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Bitte Link oder Code eingeben.';
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
        ElevatedButton(onPressed: _submit, child: const Text('Weiter')),
      ],
    );
  }
}

class _GroupInviteProfileDialog extends StatefulWidget {
  final List<Profile> profiles;
  final int preferredProfileId;

  const _GroupInviteProfileDialog({
    required this.profiles,
    required this.preferredProfileId,
  });

  @override
  State<_GroupInviteProfileDialog> createState() =>
      _GroupInviteProfileDialogState();
}

class _GroupInviteProfileDialogState extends State<_GroupInviteProfileDialog> {
  int? _selectedProfileId;

  @override
  void initState() {
    super.initState();
    for (final Profile profile in widget.profiles) {
      if (profile.id == widget.preferredProfileId) {
        _selectedProfileId = profile.id;
        return;
      }
    }
    _selectedProfileId = widget.profiles.isNotEmpty
        ? widget.profiles.first.id
        : null;
  }

  void _submit() {
    final int? selectedProfileId = _selectedProfileId;
    if (selectedProfileId == null) {
      return;
    }

    for (final Profile profile in widget.profiles) {
      if (profile.id == selectedProfileId) {
        Navigator.of(context).pop(profile);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasProfiles = widget.profiles.isNotEmpty;

    return AlertDialog(
      title: const Text('Profil auswaehlen'),
      content: SizedBox(
        width: double.maxFinite,
        child: hasProfiles
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Mit welchem Profil beitreten?'),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.profiles.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Profile profile = widget.profiles[index];
                        final bool selected = profile.id == _selectedProfileId;
                        return ListTile(
                          selected: selected,
                          leading: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                          ),
                          title: Text(profile.name),
                          subtitle: profile.role == null
                              ? null
                              : Text(_profileRoleLabel(profile.role)),
                          onTap: () {
                            setState(() => _selectedProfileId = profile.id);
                          },
                        );
                      },
                    ),
                  ),
                ],
              )
            : const Text(
                'Kein Profil dieses Accounts kann dieser Gruppe beitreten.',
              ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: hasProfiles && _selectedProfileId != null ? _submit : null,
          child: const Text('Beitreten'),
        ),
      ],
    );
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

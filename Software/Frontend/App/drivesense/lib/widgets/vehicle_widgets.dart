import 'package:drivesense/model/vehicle.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/vehicle_service.dart';
import 'package:drivesense/widgets/delayed_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VehicleTableWidget extends StatefulWidget {
  const VehicleTableWidget({super.key});

  @override
  State<VehicleTableWidget> createState() => _VehicleTableWidgetState();
}

class _VehicleTableWidgetState extends State<VehicleTableWidget> {
  List<Vehicle> _vehicles = <Vehicle>[];
  Map<int, List<VehicleMember>> _membersByVehicle =
      <int, List<VehicleMember>>{};
  bool _isLoading = true;
  final Set<String> _busyMemberActions = <String>{};

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  /// Loads vehicles and their share/member metadata for the current profile.
  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);

    final List<Vehicle> vehicles = await VehicleService.fetchVehicles();
    final Map<int, List<VehicleMember>> membersByVehicle =
        <int, List<VehicleMember>>{};

    await Future.wait(
      vehicles.where(_canViewMembers).map((Vehicle vehicle) async {
        membersByVehicle[vehicle.id] = await VehicleService.fetchVehicleMembers(
          vehicle.id,
        );
      }),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _vehicles = vehicles;
      _membersByVehicle = membersByVehicle;
      RuntimeStore.setVehicles(vehicles);
      _isLoading = false;
    });
  }

  /// Opens the add/edit dialog and reloads the table when the dialog saves.
  Future<void> _openVehicleDialog({Vehicle? vehicle}) async {
    final bool? saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _VehicleDialog(vehicle: vehicle),
    );

    if (saved == true) {
      await _loadVehicles();
    }
  }

  /// Confirms and deletes a vehicle, using stricter copy for owner deletion.
  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final bool isOwner = _normalizeVehicleRole(vehicle.myRole) == 'OWNER';
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DelayedConfirmDialog(
        title: isOwner ? 'Fahrzeug löschen' : 'Fahrzeug entfernen',
        content: isOwner
            ? 'Fahrzeug mit Kennzeichen "${vehicle.licensePlate}" wirklich löschen? '
                  'Alle Freigaben werden dadurch entfernt.'
            : 'Fahrzeug mit Kennzeichen "${vehicle.licensePlate}" aus diesem Profil entfernen?',
        confirmText: isOwner ? 'Endgültig löschen' : 'Entfernen',
        delaySeconds: 0,
        confirmButtonColor: Colors.red,
      ),
    );

    if (confirmed != true) {
      return;
    }

    final VehicleActionResult result =
        await VehicleService.deleteVehicleWithResult(vehicle.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );

    if (result.isSuccess) {
      await _loadVehicles();
    }
  }

  /// Opens the invite dialog when the current profile has share permission.
  Future<void> _shareVehicle(Vehicle vehicle) async {
    if (!_canInvite(vehicle)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nur Owner und Co-Owner dürfen Fahrzeuge teilen.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final VehicleActionResult? result = await showDialog<VehicleActionResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _VehicleInviteDialog(vehicle: vehicle),
    );

    if (result == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );

    if (result.isSuccess) {
      await _loadVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            const Text(
              'Fahrzeuge',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _openVehicleDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Hinzufügen'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_vehicles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Keine Fahrzeuge vorhanden.'),
          )
        else
          ..._vehicles.map(_buildVehicleCard),
      ],
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    final bool canInvite = _canInvite(vehicle);
    final bool canEdit = _normalizeVehicleRole(vehicle.myRole) == 'OWNER';
    final String ownerText = _ownerText(vehicle);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: const CircleAvatar(child: Icon(Icons.directions_car)),
        title: Text(
          vehicle.model,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('${vehicle.licensePlate} | ${vehicle.mileage} km'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                _InfoPill(
                  icon: Icons.verified_user_outlined,
                  text: _vehicleRoleLabel(vehicle.myRole),
                ),
                _InfoPill(
                  icon: Icons.people_alt_outlined,
                  text: _shareSummary(vehicle),
                ),
              ],
            ),
          ],
        ),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Owner: $ownerText',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: canEdit
                    ? () => _openVehicleDialog(vehicle: vehicle)
                    : null,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Bearbeiten'),
              ),
              OutlinedButton.icon(
                onPressed: canInvite ? () => _shareVehicle(vehicle) : null,
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Teilen'),
              ),
              TextButton.icon(
                onPressed: () => _deleteVehicle(vehicle),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(canEdit ? 'Löschen' : 'Entfernen'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildShareOverview(vehicle),
        ],
      ),
    );
  }

  Widget _buildShareOverview(Vehicle vehicle) {
    if (!_canViewMembers(vehicle)) {
      return _AccessNotice(
        text:
            'Dieses Fahrzeug wurde mit deinem Profil geteilt. Deine Rolle ist ${_vehicleRoleLabel(vehicle.myRole)}.',
      );
    }

    final List<VehicleMember> members =
        _membersByVehicle[vehicle.id] ?? <VehicleMember>[];

    if (members.isEmpty) {
      return const _AccessNotice(
        text: 'Keine Freigaben vorhanden oder nicht geladen.',
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: members.map((VehicleMember member) {
          final bool isSelf = member.profileId == RuntimeStore.currentProfileId;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _VehicleMemberTile(
                member: member,
                isSelf: isSelf,
                trailing: _buildMemberActions(vehicle, member, isSelf),
              ),
              if (member != members.last)
                Divider(height: 1, color: Colors.grey.shade300),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _shareSummary(Vehicle vehicle) {
    if (!_canViewMembers(vehicle)) {
      return 'Mit dir geteilt';
    }

    final int count = _sharedWithCount(vehicle);
    if (count == 0) {
      return 'Nicht geteilt';
    }
    if (count == 1) {
      return 'Mit 1 Profil geteilt';
    }
    return 'Mit $count Profilen geteilt';
  }

  int _sharedWithCount(Vehicle vehicle) {
    final int? currentProfileId = RuntimeStore.currentProfileId;
    final List<VehicleMember> members =
        _membersByVehicle[vehicle.id] ?? <VehicleMember>[];
    return members
        .where((VehicleMember member) => member.profileId != currentProfileId)
        .length;
  }

  String _ownerText(Vehicle vehicle) {
    final String profileName = vehicle.ownerProfileName.trim();
    final String accountName = vehicle.ownerAccountName.trim();
    if (profileName.isNotEmpty && accountName.isNotEmpty) {
      return '$profileName ($accountName)';
    }
    if (profileName.isNotEmpty) {
      return profileName;
    }
    if (accountName.isNotEmpty) {
      return accountName;
    }
    return 'Unbekannt';
  }

  bool _canInvite(Vehicle vehicle) {
    final String role = _normalizeVehicleRole(vehicle.myRole);
    return role == 'OWNER' || role == 'CO_OWNER';
  }

  bool _canViewMembers(Vehicle vehicle) {
    return _canInvite(vehicle);
  }

  Widget? _buildMemberActions(
    Vehicle vehicle,
    VehicleMember member,
    bool isSelf,
  ) {
    final String myRole = _normalizeVehicleRole(vehicle.myRole);
    final String targetRole = _normalizeVehicleRole(member.vehicleRole);
    final bool canLeave = isSelf && myRole != 'OWNER';
    final bool canRemove = !isSelf && _canRemoveMember(myRole, targetRole);
    final bool canChangeRole = !isSelf && _canChangeRole(myRole, targetRole);

    if (!canLeave && !canRemove && !canChangeRole) {
      return null;
    }

    final bool removeBusy = _busyMemberActions.contains(
      _memberActionKey(vehicle.id, member.profileId, 'remove'),
    );
    final bool roleBusy = _busyMemberActions.contains(
      _memberActionKey(vehicle.id, member.profileId, 'role'),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (canChangeRole)
          IconButton(
            tooltip: targetRole == 'CO_OWNER' ? 'Zu Fahrer' : 'Zu Co-Owner',
            onPressed: roleBusy
                ? null
                : () => _toggleVehicleMemberRole(vehicle, member),
            icon: roleBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    targetRole == 'CO_OWNER'
                        ? Icons.person_outline
                        : Icons.admin_panel_settings_outlined,
                  ),
          ),
        if (canLeave || canRemove)
          IconButton(
            tooltip: canLeave ? 'Fahrzeug verlassen' : 'Entfernen',
            onPressed: removeBusy
                ? null
                : () => _removeVehicleMember(vehicle, member, isSelf),
            color: Colors.red,
            icon: removeBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    canLeave ? Icons.logout : Icons.person_remove_outlined,
                  ),
          ),
      ],
    );
  }

  Future<void> _toggleVehicleMemberRole(
    Vehicle vehicle,
    VehicleMember member,
  ) async {
    final String myRole = _normalizeVehicleRole(vehicle.myRole);
    final String currentRole = _normalizeVehicleRole(member.vehicleRole);
    if (!_canChangeRole(myRole, currentRole)) {
      _showResult(false, 'Nur Owner duerfen Rollen aendern.');
      return;
    }

    final String nextRole = currentRole == 'CO_OWNER' ? 'DRIVER' : 'CO_OWNER';
    final String actionKey = _memberActionKey(vehicle.id, member.profileId, 'role');
    setState(() => _busyMemberActions.add(actionKey));

    final VehicleActionResult result = await VehicleService.updateVehicleMemberRole(
      vehicleId: vehicle.id,
      profileId: member.profileId,
      role: nextRole,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _busyMemberActions.remove(actionKey);
      if (result.isSuccess) {
        final List<VehicleMember> current =
            _membersByVehicle[vehicle.id] ?? <VehicleMember>[];
        _membersByVehicle = Map<int, List<VehicleMember>>.from(_membersByVehicle)
          ..[vehicle.id] = current
              .map(
                (VehicleMember existing) => existing.profileId == member.profileId
                    ? VehicleMember(
                        profileId: existing.profileId,
                        profileName: existing.profileName,
                        profileRole: existing.profileRole,
                        accountName: existing.accountName,
                        accountEmail: existing.accountEmail,
                        vehicleRole: nextRole,
                      )
                    : existing,
              )
              .toList();
      }
    });

    _showResult(result.isSuccess, result.message);
  }

  Future<void> _removeVehicleMember(
    Vehicle vehicle,
    VehicleMember member,
    bool isSelf,
  ) async {
    final String myRole = _normalizeVehicleRole(vehicle.myRole);
    final String targetRole = _normalizeVehicleRole(member.vehicleRole);
    final bool allowed = isSelf
        ? myRole != 'OWNER'
        : _canRemoveMember(myRole, targetRole);

    if (!allowed) {
      _showResult(false, 'Keine Berechtigung fuer diese Aktion.');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DelayedConfirmDialog(
        title: isSelf ? 'Fahrzeug verlassen' : 'Mitglied entfernen',
        content: isSelf
            ? 'Fahrzeug "${vehicle.model} (${vehicle.licensePlate})" wirklich verlassen?'
            : 'Mitglied "${member.profileName}" wirklich entfernen?',
        confirmText: isSelf ? 'Verlassen' : 'Entfernen',
        delaySeconds: 0,
        confirmButtonColor: Colors.red,
      ),
    );

    if (confirmed != true) {
      return;
    }

    final String actionKey = _memberActionKey(
      vehicle.id,
      member.profileId,
      'remove',
    );
    setState(() => _busyMemberActions.add(actionKey));

    final VehicleActionResult result = isSelf
        ? await VehicleService.deleteVehicleWithResult(vehicle.id)
        : await VehicleService.removeVehicleMember(
            vehicleId: vehicle.id,
            profileId: member.profileId,
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _busyMemberActions.remove(actionKey);
      if (result.isSuccess && !isSelf) {
        final List<VehicleMember> current =
            _membersByVehicle[vehicle.id] ?? <VehicleMember>[];
        _membersByVehicle = Map<int, List<VehicleMember>>.from(_membersByVehicle)
          ..[vehicle.id] = current
              .where(
                (VehicleMember existing) => existing.profileId != member.profileId,
              )
              .toList();
      }
    });

    _showResult(
      result.isSuccess,
      isSelf && result.isSuccess ? 'Fahrzeug wurde verlassen.' : result.message,
    );

    if (result.isSuccess && isSelf) {
      await _loadVehicles();
    }
  }

  bool _canRemoveMember(String myRole, String targetRole) {
    if (targetRole == 'OWNER') {
      return false;
    }

    return myRole == 'OWNER' || (myRole == 'CO_OWNER' && targetRole == 'DRIVER');
  }

  bool _canChangeRole(String myRole, String targetRole) {
    if (targetRole == 'OWNER') {
      return false;
    }

    return myRole == 'OWNER';
  }

  String _memberActionKey(int vehicleId, int profileId, String action) {
    return '$vehicleId:$profileId:$action';
  }

  void _showResult(bool isSuccess, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _AccessNotice extends StatelessWidget {
  final String text;

  const _AccessNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: TextStyle(color: Colors.grey.shade700)),
      ),
    );
  }
}

class _VehicleMemberTile extends StatelessWidget {
  final VehicleMember member;
  final bool isSelf;
  final Widget? trailing;

  const _VehicleMemberTile({
    required this.member,
    required this.isSelf,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final String displayName = member.profileName.isNotEmpty
        ? member.profileName
        : member.accountEmail;
    final String title = isSelf ? '$displayName (du)' : displayName;
    final String accountLine = _memberAccountLine(member);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: const Icon(Icons.person_outline),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: accountLine.isEmpty
          ? null
          : Text(accountLine, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _RoleBadge(label: _vehicleRoleLabel(member.vehicleRole)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;

  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _VehicleDialog extends StatefulWidget {
  final Vehicle? vehicle;

  const _VehicleDialog({this.vehicle});

  @override
  State<_VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends State<_VehicleDialog> {
  late final TextEditingController _modelCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _mileageCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _modelCtrl = TextEditingController(text: widget.vehicle?.model ?? '');
    _plateCtrl = TextEditingController(
      text: widget.vehicle?.licensePlate ?? '',
    );
    _mileageCtrl = TextEditingController(
      text: widget.vehicle != null ? widget.vehicle!.mileage.toString() : '',
    );
  }

  @override
  void dispose() {
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }

  /// Validates vehicle form input and then calls create or update depending on
  /// whether this dialog is editing an existing vehicle.
  Future<void> _save() async {
    final String model = _modelCtrl.text.trim();
    final String plate = _plateCtrl.text.trim();
    final int? mileage = int.tryParse(_mileageCtrl.text.trim());

    if (model.isEmpty || plate.isEmpty || mileage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte alle Felder korrekt ausfüllen.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    late final VehicleActionResult result;

    if (widget.vehicle == null) {
      final VehicleActionResultWithVehicle createResult =
          await VehicleService.createVehicleWithResult(
        model: model,
        licensePlate: plate,
        mileage: mileage,
      );
      result = createResult;
    } else {
      final Vehicle updated = Vehicle(
        id: widget.vehicle!.id,
        userId: widget.vehicle!.userId,
        model: model,
        licensePlate: plate,
        mileage: mileage,
        myRole: widget.vehicle!.myRole,
        ownerAccountName: widget.vehicle!.ownerAccountName,
        ownerProfileName: widget.vehicle!.ownerProfileName,
      );
      result = await VehicleService.updateVehicleWithResult(updated);
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    if (result.isSuccess) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.vehicle == null;

    return AlertDialog(
      title: Text(isNew ? 'Fahrzeug hinzufügen' : 'Fahrzeug bearbeiten'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _modelCtrl,
            decoration: const InputDecoration(labelText: 'Modell'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _plateCtrl,
            decoration: const InputDecoration(labelText: 'Kennzeichen'),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _mileageCtrl,
            decoration: const InputDecoration(labelText: 'Kilometerstand'),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Speichern'),
        ),
      ],
    );
  }
}

class _VehicleInviteDialog extends StatefulWidget {
  final Vehicle vehicle;

  const _VehicleInviteDialog({required this.vehicle});

  @override
  State<_VehicleInviteDialog> createState() => _VehicleInviteDialogState();
}

class _VehicleInviteDialogState extends State<_VehicleInviteDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isSending = false;
  String _role = 'DRIVER';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Sends a vehicle invite code to the entered email and keeps the dialog open
  /// when the backend rejects the invite.
  Future<void> _sendInvite() async {
    if (_formKey.currentState?.validate() != true || _isSending) {
      return;
    }

    setState(() => _isSending = true);

    final VehicleActionResult result = await VehicleService.inviteVehicle(
      vehicleId: widget.vehicle.id,
      email: _emailController.text.trim(),
      role: _role,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSending = false);
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner =
        _normalizeVehicleRole(widget.vehicle.myRole) == 'OWNER';

    return AlertDialog(
      title: const Text('Fahrzeug teilen'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '${widget.vehicle.model} (${widget.vehicle.licensePlate})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
                helperText: 'Du kannst auch deine eigene E-Mail einladen.',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                final String email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return 'E-Mail darf nicht leer sein.';
                }
                if (!email.contains('@') || !email.contains('.')) {
                  return 'Bitte eine gültige E-Mail eingeben.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Rolle',
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: 'DRIVER',
                  child: Text('Fahrer'),
                ),
                if (isOwner)
                  const DropdownMenuItem<String>(
                    value: 'CO_OWNER',
                    child: Text('Co-Owner'),
                  ),
              ],
              onChanged: _isSending
                  ? null
                  : (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _role = value);
                    },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendInvite,
          child: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Senden'),
        ),
      ],
    );
  }
}

String _normalizeVehicleRole(String? role) {
  return role?.trim().toUpperCase() ?? '';
}

String _vehicleRoleLabel(String? role) {
  switch (_normalizeVehicleRole(role)) {
    case 'OWNER':
      return 'Owner';
    case 'CO_OWNER':
      return 'Co-Owner';
    case 'DRIVER':
      return 'Fahrer';
    default:
      return role?.trim().isNotEmpty == true ? role!.trim() : 'Unbekannt';
  }
}

String _profileRoleLabel(String? role) {
  switch (role?.trim().toUpperCase()) {
    case 'FAHRSCHUELER':
      return 'Fahrschüler';
    case 'BERUFSFAHRER':
      return 'Berufsfahrer';
    case 'PRIVAT':
      return 'Privat';
    default:
      return role?.trim().isNotEmpty == true ? role!.trim() : '';
  }
}

String _memberAccountLine(VehicleMember member) {
  final List<String> parts = <String>[];
  if (member.accountName.trim().isNotEmpty) {
    parts.add(member.accountName.trim());
  }
  if (member.accountEmail.trim().isNotEmpty) {
    parts.add(member.accountEmail.trim());
  }
  final String profileRole = _profileRoleLabel(member.profileRole);
  if (profileRole.isNotEmpty) {
    parts.add(profileRole);
  }
  return parts.join(' | ');
}

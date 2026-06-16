import 'package:drivesense/model/user_group.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/group_service.dart';
import 'package:drivesense/services/protocol_service.dart';
import 'package:drivesense/widgets/delayed_confirm_dialog.dart';
import 'package:flutter/material.dart';

class GroupTableWidget extends StatefulWidget {
  final int currentProfileId;
  final Future<void> Function()? onProtocolsChanged;

  const GroupTableWidget({
    super.key,
    required this.currentProfileId,
    this.onProtocolsChanged,
  });

  @override
  State<GroupTableWidget> createState() => _GroupTableWidgetState();
}

class _GroupTableWidgetState extends State<GroupTableWidget> {
  List<UserGroup> _groups = <UserGroup>[];
  Map<int, List<GroupMember>> _membersByGroup = <int, List<GroupMember>>{};
  bool _isLoading = true;
  bool _isCreatingGroup = false;
  int? _busyGroupId;
  final Set<String> _busyMemberActions = <String>{};

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  bool get _isGlobalAdmin =>
      RuntimeStore.getActiveProfileRole().trim().toUpperCase() == 'ADMIN';

  /// Loads groups and their member lists together so each table section can
  /// render role-based actions without extra per-row requests.
  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);

    final List<UserGroup> groups = await GroupService.fetchGroups();
    final Map<int, List<GroupMember>> membersByGroup =
        <int, List<GroupMember>>{};

    await Future.wait(
      groups.map((UserGroup group) async {
        membersByGroup[group.id] = await GroupService.fetchGroupMembers(
          group.id,
        );
      }),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _groups = groups;
      _membersByGroup = membersByGroup;
      _isLoading = false;
    });
  }

  /// Opens the create dialog, posts the new group, and refreshes the table when
  /// creation succeeds.
  Future<void> _createGroup() async {
    if (_isCreatingGroup) {
      return;
    }

    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _GroupNameDialog(
        title: 'Gruppe erstellen',
        confirmText: 'Erstellen',
      ),
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    setState(() => _isCreatingGroup = true);

    final GroupMutationResult result = await GroupService.createGroup(
      name: name,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isCreatingGroup = false);
    _showResult(result.isSuccess, result.message);

    if (result.isSuccess) {
      await _loadGroups();
    }
  }

  /// Renames a group only when the current profile can manage it and no other
  /// group mutation is already running.
  Future<void> _renameGroup(UserGroup group) async {
    if (!_canManageGroup(group) || _busyGroupId != null) {
      return;
    }

    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _GroupNameDialog(
        title: 'Gruppe umbenennen',
        confirmText: 'Speichern',
        initialName: group.name,
      ),
    );

    final String trimmedName = name?.trim() ?? '';
    if (trimmedName.isEmpty || trimmedName == group.name) {
      return;
    }

    setState(() => _busyGroupId = group.id);

    final GroupActionResult result = await GroupService.updateGroup(
      groupId: group.id,
      name: trimmedName,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _busyGroupId = null;
      if (result.isSuccess) {
        _groups = _groups
            .map(
              (UserGroup existing) => existing.id == group.id
                  ? existing.copyWith(name: trimmedName)
                  : existing,
            )
            .toList();
      }
    });
    _showResult(result.isSuccess, result.message);
  }

  /// Deletes a group after confirmation and refreshes protocols because group
  /// deletion can remove group-owned protocols from the active profile.
  Future<void> _deleteGroup(UserGroup group) async {
    if (!_canManageGroup(group) || _busyGroupId != null) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DelayedConfirmDialog(
        title: 'Gruppe loeschen',
        content:
            'Gruppe "${group.name}" wirklich loeschen? '
            'Mitglieder verlieren dadurch Zugriff auf Gruppenprotokolle.',
        confirmText: 'Endgueltig loeschen',
        delaySeconds: 0,
        confirmButtonColor: Colors.red,
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _busyGroupId = group.id);

    final GroupActionResult result = await GroupService.deleteGroup(group.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _busyGroupId = null;
      if (result.isSuccess) {
        _groups = _groups
            .where((UserGroup existing) => existing.id != group.id)
            .toList();
        _membersByGroup = Map<int, List<GroupMember>>.from(_membersByGroup)
          ..remove(group.id);
      }
    });

    _showResult(result.isSuccess, result.message);
    if (result.isSuccess) {
      await widget.onProtocolsChanged?.call();
    }
  }

  /// Sends a group invite when the current member role is allowed to invite.
  Future<void> _inviteMember(UserGroup group) async {
    final String myRole = _myRoleForGroup(group);
    if (!_canInvite(myRole) || _busyGroupId != null) {
      _showResult(false, 'Nur Owner und Admins duerfen Mitglieder einladen.');
      return;
    }

    final String? email = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _GroupInviteDialog(group: group),
    );

    if (email == null || email.trim().isEmpty) {
      return;
    }

    setState(() => _busyGroupId = group.id);

    final GroupActionResult result = await GroupService.inviteMember(
      groupId: group.id,
      email: email,
    );

    if (!mounted) {
      return;
    }

    setState(() => _busyGroupId = null);
    _showResult(result.isSuccess, result.message);
  }

  /// Creates a protocol owned by this group and selects it immediately.
  Future<void> _createGroupProtocol(UserGroup group) async {
    if (_busyGroupId != null) {
      return;
    }

    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          _GroupProtocolDialog(initialName: '${group.name} Protokoll'),
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    setState(() => _busyGroupId = group.id);

    final created = await ProtocolService.createProtocol(
      name: name,
      usergroupId: group.id,
    );

    if (!mounted) {
      return;
    }

    setState(() => _busyGroupId = null);

    if (created == null) {
      _showResult(false, 'Gruppenprotokoll konnte nicht erstellt werden.');
      return;
    }

    RuntimeStore.setCurrentProtocolId(created.id);
    await widget.onProtocolsChanged?.call();
    if (!mounted) {
      return;
    }

    _showResult(true, 'Gruppenprotokoll wurde erstellt.');
  }

  /// Removes another member or lets the current profile leave the group.
  ///
  /// The permission rules differ for self-removal and member removal, so this
  /// method calculates the action first and then runs the shared delete flow.
  Future<void> _removeMember(UserGroup group, GroupMember member) async {
    final String myRole = _myRoleForGroup(group);
    final bool isSelf = member.profileId == widget.currentProfileId;
    final bool allowed = isSelf
        ? _normalizeGroupRole(member.groupRole) != 'OWNER'
        : _canRemove(myRole, member.groupRole);

    if (!allowed) {
      _showResult(false, 'Keine Berechtigung fuer diese Aktion.');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DelayedConfirmDialog(
        title: isSelf ? 'Gruppe verlassen' : 'Mitglied entfernen',
        content: isSelf
            ? 'Gruppe "${group.name}" wirklich verlassen?'
            : 'Mitglied "${member.name}" wirklich entfernen?',
        confirmText: isSelf ? 'Verlassen' : 'Entfernen',
        delaySeconds: 0,
        confirmButtonColor: Colors.red,
      ),
    );

    if (confirmed != true) {
      return;
    }

    final String actionKey = _memberActionKey(
      group.id,
      member.profileId,
      'remove',
    );
    setState(() => _busyMemberActions.add(actionKey));

    final GroupActionResult result = await GroupService.deleteMember(
      groupId: group.id,
      profileId: member.profileId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _busyMemberActions.remove(actionKey);
      if (result.isSuccess) {
        final List<GroupMember> current =
            _membersByGroup[group.id] ?? <GroupMember>[];
        _membersByGroup = Map<int, List<GroupMember>>.from(_membersByGroup)
          ..[group.id] = current
              .where(
                (GroupMember existing) =>
                    existing.profileId != member.profileId,
              )
              .toList();
      }
    });

    _showResult(
      result.isSuccess,
      isSelf && result.isSuccess ? 'Gruppe wurde verlassen.' : result.message,
    );

    if (result.isSuccess && isSelf) {
      await _loadGroups();
      await widget.onProtocolsChanged?.call();
    }
  }

  /// Toggles a member between ADMIN and MEMBER when the current role is allowed
  /// to change roles.
  Future<void> _toggleMemberRole(UserGroup group, GroupMember member) async {
    final String myRole = _myRoleForGroup(group);
    if (!_canChangeRole(myRole, member.groupRole)) {
      _showResult(false, 'Nur Owner duerfen Rollen aendern.');
      return;
    }

    final String currentRole = _normalizeGroupRole(member.groupRole);
    final String nextRole = currentRole == 'ADMIN' ? 'MEMBER' : 'ADMIN';
    final String actionKey = _memberActionKey(
      group.id,
      member.profileId,
      'role',
    );

    setState(() => _busyMemberActions.add(actionKey));

    final GroupActionResult result = await GroupService.updateMemberRole(
      groupId: group.id,
      profileId: member.profileId,
      role: nextRole,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _busyMemberActions.remove(actionKey);
      if (result.isSuccess) {
        final List<GroupMember> current =
            _membersByGroup[group.id] ?? <GroupMember>[];
        _membersByGroup = Map<int, List<GroupMember>>.from(_membersByGroup)
          ..[group.id] = current
              .map(
                (GroupMember existing) => existing.profileId == member.profileId
                    ? existing.copyWith(groupRole: nextRole)
                    : existing,
              )
              .toList();
      }
    });

    _showResult(result.isSuccess, result.message);
  }

  @override
  Widget build(BuildContext context) {
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
              'Gruppen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _isCreatingGroup ? null : _createGroup,
              icon: _isCreatingGroup
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add, size: 18),
              label: Text(_isCreatingGroup ? 'Erstelle...' : 'Hinzufuegen'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_groups.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Keine Gruppen vorhanden.'),
          )
        else
          ..._groups.map(_buildGroupCard),
      ],
    );
  }

  Widget _buildGroupCard(UserGroup group) {
    final List<GroupMember> members =
        _membersByGroup[group.id] ?? <GroupMember>[];
    final String myRole = _myRoleForGroup(group);
    final bool isBusy = _busyGroupId != null;
    final String ownerText = group.owner.isNotEmpty
        ? group.owner
        : 'Profil ${group.ownerId}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text(group.name),
        subtitle: Text(
          'Owner: $ownerText | Meine Rolle: ${_groupRoleLabel(myRole)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (_canInvite(myRole))
                OutlinedButton.icon(
                  onPressed: isBusy ? null : () => _inviteMember(group),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Mitglied einladen'),
                ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : () => _createGroupProtocol(group),
                icon: const Icon(Icons.playlist_add, size: 18),
                label: const Text('Gruppenprotokoll'),
              ),
              if (_canManageGroup(group))
                OutlinedButton.icon(
                  onPressed: isBusy ? null : () => _renameGroup(group),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Umbenennen'),
                ),
              if (_canManageGroup(group))
                TextButton.icon(
                  onPressed: isBusy ? null : () => _deleteGroup(group),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Gruppe loeschen'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMemberList(group, members, myRole),
        ],
      ),
    );
  }

  Widget _buildMemberList(
    UserGroup group,
    List<GroupMember> members,
    String myRole,
  ) {
    if (members.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Keine Mitglieder geladen.'),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: members.map((GroupMember member) {
          final bool isSelf = member.profileId == widget.currentProfileId;
          final String role = _normalizeGroupRole(member.groupRole);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(
                  isSelf ? '${member.name} (du)' : member.name,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_groupRoleLabel(role)),
                trailing: _buildMemberActions(group, member, myRole, isSelf),
              ),
              if (member != members.last)
                Divider(height: 1, color: Colors.grey.shade300),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget? _buildMemberActions(
    UserGroup group,
    GroupMember member,
    String myRole,
    bool isSelf,
  ) {
    final String role = _normalizeGroupRole(member.groupRole);
    final bool canLeave = isSelf && role != 'OWNER';
    final bool canRemoveMember = !isSelf && _canRemove(myRole, role);
    final bool canChangeRole = !isSelf && _canChangeRole(myRole, role);

    if (!canLeave && !canRemoveMember && !canChangeRole) {
      return null;
    }

    final bool removeBusy = _busyMemberActions.contains(
      _memberActionKey(group.id, member.profileId, 'remove'),
    );
    final bool roleBusy = _busyMemberActions.contains(
      _memberActionKey(group.id, member.profileId, 'role'),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (canChangeRole)
          IconButton(
            tooltip: role == 'ADMIN' ? 'Zu Member' : 'Zu Admin',
            onPressed: roleBusy ? null : () => _toggleMemberRole(group, member),
            icon: roleBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    role == 'ADMIN'
                        ? Icons.person_outline
                        : Icons.admin_panel_settings_outlined,
                  ),
          ),
        if (canLeave || canRemoveMember)
          IconButton(
            tooltip: canLeave ? 'Gruppe verlassen' : 'Entfernen',
            onPressed: removeBusy ? null : () => _removeMember(group, member),
            color: Colors.red,
            icon: removeBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(canLeave ? Icons.logout : Icons.person_remove_outlined),
          ),
      ],
    );
  }

  bool _canManageGroup(UserGroup group) {
    return _isGlobalAdmin || group.ownerId == widget.currentProfileId;
  }

  bool _canInvite(String myRole) {
    final String role = _normalizeGroupRole(myRole);
    return _isGlobalAdmin || role == 'OWNER' || role == 'ADMIN';
  }

  bool _canRemove(String myRole, String targetRole) {
    final String normalizedMyRole = _normalizeGroupRole(myRole);
    final String normalizedTargetRole = _normalizeGroupRole(targetRole);

    if (normalizedTargetRole == 'OWNER') {
      return false;
    }
    return _isGlobalAdmin ||
        normalizedMyRole == 'OWNER' ||
        (normalizedMyRole == 'ADMIN' && normalizedTargetRole == 'MEMBER');
  }

  bool _canChangeRole(String myRole, String targetRole) {
    final String normalizedTargetRole = _normalizeGroupRole(targetRole);
    if (normalizedTargetRole == 'OWNER') {
      return false;
    }
    return _isGlobalAdmin || _normalizeGroupRole(myRole) == 'OWNER';
  }

  String _myRoleForGroup(UserGroup group) {
    if (group.ownerId == widget.currentProfileId) {
      return 'OWNER';
    }

    final List<GroupMember> members =
        _membersByGroup[group.id] ?? <GroupMember>[];
    for (final GroupMember member in members) {
      if (member.profileId == widget.currentProfileId) {
        return _normalizeGroupRole(member.groupRole);
      }
    }

    return _isGlobalAdmin ? 'ADMIN' : 'MEMBER';
  }

  String _memberActionKey(int groupId, int profileId, String action) {
    return '$groupId:$profileId:$action';
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

String _normalizeGroupRole(String? role) {
  return role?.trim().toUpperCase() ?? '';
}

String _groupRoleLabel(String? role) {
  switch (_normalizeGroupRole(role)) {
    case 'OWNER':
      return 'Owner';
    case 'ADMIN':
      return 'Admin';
    case 'MEMBER':
      return 'Member';
    default:
      return role?.trim().isNotEmpty == true ? role!.trim() : 'Unbekannt';
  }
}

class _GroupNameDialog extends StatefulWidget {
  final String title;
  final String confirmText;
  final String initialName;

  const _GroupNameDialog({
    required this.title,
    required this.confirmText,
    this.initialName = '',
  });

  @override
  State<_GroupNameDialog> createState() => _GroupNameDialogState();
}

class _GroupNameDialogState extends State<_GroupNameDialog> {
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
      title: Text(widget.title),
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
        ElevatedButton(onPressed: _submit, child: Text(widget.confirmText)),
      ],
    );
  }
}

class _GroupInviteDialog extends StatefulWidget {
  final UserGroup group;

  const _GroupInviteDialog({required this.group});

  @override
  State<_GroupInviteDialog> createState() => _GroupInviteDialogState();
}

class _GroupInviteDialogState extends State<_GroupInviteDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    Navigator.of(context).pop(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mitglied einladen'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.group.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                final String email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return 'E-Mail darf nicht leer sein.';
                }
                if (!email.contains('@') || !email.contains('.')) {
                  return 'Bitte eine gueltige E-Mail eingeben.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Senden')),
      ],
    );
  }
}

class _GroupProtocolDialog extends StatefulWidget {
  final String initialName;

  const _GroupProtocolDialog({required this.initialName});

  @override
  State<_GroupProtocolDialog> createState() => _GroupProtocolDialogState();
}

class _GroupProtocolDialogState extends State<_GroupProtocolDialog> {
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
      title: const Text('Gruppenprotokoll erstellen'),
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
        ElevatedButton(onPressed: _submit, child: const Text('Erstellen')),
      ],
    );
  }
}

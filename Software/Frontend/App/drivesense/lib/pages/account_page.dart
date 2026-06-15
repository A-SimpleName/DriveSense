import 'package:drivesense/model/account.dart';
import 'package:drivesense/services/account_service.dart';
import 'package:drivesense/widgets/delayed_confirm_dialog.dart';
import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Account? _account;

  bool _loading = true;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Account? acc = await AccountService.fetchAccount();

    if (!mounted) return;

    setState(() {
      _account = acc;
      _loading = false;
    });
  }

  Future<void> _confirmDeleteAccount() async {
    if (_isDeletingAccount) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DelayedConfirmDialog(
        title: 'Account loeschen',
        content:
            'Willst du deinen Account wirklich endgueltig loeschen?\n\n'
            'Dieser Vorgang kann nicht rueckgaengig gemacht werden.',
        confirmText: 'Endgueltig loeschen',
        delaySeconds: 5,
        confirmButtonColor: Colors.red,
      ),
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) return;

    setState(() => _isDeletingAccount = true);

    Navigator.pushNamed(context, 'DeleteAccountPage');

    if (!mounted) return;

    setState(() => _isDeletingAccount = false);
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 26, color: Theme.of(context).primaryColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool destructive = false,
    Widget? child,
  }) {
    final Color color = destructive
        ? Colors.red
        : Theme.of(context).primaryColor;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: child == null
            ? Icon(icon, color: Colors.white)
            : const SizedBox.shrink(),
        label:
            child ??
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Account? acc = _account;

    return Scaffold(
      appBar: AppBar(title: const Text('Account'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: acc == null
              ? const Center(child: Text('Kein Account geladen'))
              : SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 10),
                      CircleAvatar(
                        radius: 42,
                        child: Text(
                          acc.firstName.isNotEmpty
                              ? acc.firstName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${acc.firstName} ${acc.lastName}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        acc.email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildInfoTile(
                        icon: Icons.email_outlined,
                        label: 'E-Mail',
                        value: acc.email,
                      ),
                      _buildInfoTile(
                        icon: Icons.person_outline,
                        label: 'Vorname',
                        value: acc.firstName,
                      ),
                      _buildInfoTile(
                        icon: Icons.badge_outlined,
                        label: 'Nachname',
                        value: acc.lastName,
                      ),
                      const SizedBox(height: 24),
                      _buildActionButton(
                        label: 'Account bearbeiten',
                        icon: Icons.edit_outlined,
                        onPressed: () {
                          Navigator.pushNamed(context, 'EditAccountPage');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        label: 'Passwort aendern',
                        icon: Icons.lock_outline,
                        onPressed: () {
                          Navigator.pushNamed(context, 'ChangePasswordPage');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        label: 'Account loeschen',
                        icon: Icons.delete_outline,
                        destructive: true,
                        onPressed: _isDeletingAccount
                            ? null
                            : _confirmDeleteAccount,
                        child: _isDeletingAccount
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

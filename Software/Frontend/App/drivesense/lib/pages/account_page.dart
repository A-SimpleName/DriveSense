import 'package:drivesense/model/account.dart';
import 'package:drivesense/services/account_service.dart';
import 'package:drivesense/services/email_verification_service.dart';
import 'package:drivesense/widgets/delayed_confirm_dialog.dart';
import 'package:drivesense/widgets/verification_code_dialog.dart';
import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Account? _account;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _loading = true;
  bool _isEditing = false;
  bool _isSavingAccount = false;
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

    if (acc != null) {
      _syncControllers(acc);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _syncControllers(Account account) {
    _firstNameController.text = account.firstName;
    _lastNameController.text = account.lastName;
    _emailController.text = account.email;
  }

  void _toggleEditMode() {
    final Account? acc = _account;
    if (acc == null) {
      return;
    }

    if (_isEditing) {
      _saveAccountChanges();
      return;
    }

    setState(() {
      _isEditing = true;
      _syncControllers(acc);
    });
  }

  Future<void> _saveAccountChanges() async {
    if (_isSavingAccount) {
      return;
    }

    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() => _isSavingAccount = true);

    final String previousEmail = _account?.email.trim() ?? '';
    final String nextEmail = _emailController.text.trim();
    final bool emailChanged =
        previousEmail.toLowerCase() != nextEmail.toLowerCase();

    final Account? updatedAccount = await AccountService.updateAccount(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: nextEmail,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSavingAccount = false);

    if (updatedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account konnte nicht gespeichert werden'),
        ),
      );
      return;
    }

    setState(() {
      _account = updatedAccount;
      _isEditing = false;
      _syncControllers(updatedAccount);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Account gespeichert')));

    if (!emailChanged) {
      return;
    }

    final bool? verified = await VerificationCodeDialog.show(
      context: context,
      title: 'E-Mail bestaetigen',
      description:
          'Wir haben einen Code an $nextEmail geschickt. Bitte gib ihn ein, damit die neue Adresse uebernommen wird.',
      submitLabel: 'Code bestaetigen',
      resendLabel: 'Code erneut senden',
      onSubmit: (String code) =>
          EmailVerificationService.confirmEmailChange(code),
      onResend: () => EmailVerificationService.requestEmailChange(nextEmail),
    );

    if (!mounted) {
      return;
    }

    if (verified == true) {
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-Mail-Adresse bestaetigt')),
      );
      return;
    }

    if (emailChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Die neue E-Mail ist noch nicht bestaetigt.'),
        ),
      );
    }
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

  Widget _buildAccountField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
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
                      if (acc.pendingEmail != null) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          'Ausstehende Bestätigung: ${acc.pendingEmail}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 30),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            _buildAccountField(
                              label: 'Vorname',
                              icon: Icons.person_outline,
                              controller: _firstNameController,
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vorname darf nicht leer sein';
                                }
                                return null;
                              },
                            ),
                            _buildAccountField(
                              label: 'Nachname',
                              icon: Icons.badge_outlined,
                              controller: _lastNameController,
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nachname darf nicht leer sein';
                                }
                                return null;
                              },
                            ),
                            _buildAccountField(
                              label: 'E-Mail',
                              icon: Icons.email_outlined,
                              controller: _emailController,
                              validator: (String? value) {
                                final String email = value?.trim() ?? '';
                                if (email.isEmpty) {
                                  return 'E-Mail darf nicht leer sein';
                                }
                                final RegExp emailPattern = RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                );
                                if (!emailPattern.hasMatch(email)) {
                                  return 'Bitte eine gültige E-Mail eingeben';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildActionButton(
                        label: _isEditing
                            ? 'Aenderungen speichern'
                            : 'Account bearbeiten',
                        icon: _isEditing
                            ? Icons.save_outlined
                            : Icons.edit_outlined,
                        onPressed: _isSavingAccount ? null : _toggleEditMode,
                        child: _isSavingAccount
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
                      const SizedBox(height: 12),
                      _buildActionButton(
                        label: 'Passwort aendern',
                        icon: Icons.lock_outline,
                        onPressed: () async {
                          final Object? changed = await Navigator.pushNamed(
                            context,
                            'ChangePasswordPage',
                          );

                          if (!mounted || changed != true) {
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Passwort erfolgreich geändert'),
                            ),
                          );
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

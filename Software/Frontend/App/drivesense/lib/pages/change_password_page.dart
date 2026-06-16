import 'package:drivesense/services/account_service.dart';
import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSaving = false;
  bool _obscurePasswords = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isStrongPassword(String password) {
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(password);
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }

    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final String oldPassword = _oldPasswordController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte alle Felder ausfuellen.')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Die neuen Passwörter stimmen nicht ueberein.'),
        ),
      );
      return;
    }

    if (!_isStrongPassword(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Das neue Passwort muss mindestens 8 Zeichen, einen Grossbuchstaben, einen Kleinbuchstaben und eine Zahl enthalten.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final String? errorMessage = await AccountService.updatePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    Navigator.pop(context, true);
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _obscurePasswords,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePasswords ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePasswords = !_obscurePasswords;
            });
          },
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passwort ändern'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildPasswordField(
                  label: 'Altes Passwort',
                  controller: _oldPasswordController,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Altes Passwort darf nicht leer sein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildPasswordField(
                  label: 'Neues Passwort',
                  controller: _newPasswordController,
                  validator: (String? value) {
                    final String password = value?.trim() ?? '';
                    if (password.isEmpty) {
                      return 'Neues Passwort darf nicht leer sein';
                    }
                    if (!_isStrongPassword(password)) {
                      return 'Mindestens 8 Zeichen, Gross-/Kleinbuchstabe und Zahl';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildPasswordField(
                  label: 'Neues Passwort wiederholen',
                  controller: _confirmPasswordController,
                  validator: (String? value) {
                    final String confirmPassword = value?.trim() ?? '';
                    if (confirmPassword.isEmpty) {
                      return 'Bitte das neue Passwort wiederholen';
                    }
                    if (confirmPassword != _newPasswordController.text.trim()) {
                      return 'Die Passwörter stimmen nicht überein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Passwort speichern'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

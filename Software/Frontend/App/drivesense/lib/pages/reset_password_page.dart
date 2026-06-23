import 'package:drivesense/config/app_colors.dart';
import 'package:drivesense/services/account_service.dart';
import 'package:drivesense/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordPage({super.key, required this.email, required this.code});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isStrongPassword(String password) {
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(password);
  }

  Future<void> _submit() async {
    if (_isLoading) {
      return;
    }

    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte alle Felder ausfuellen.')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Die Passwörter stimmen nicht überein.')),
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

    setState(() => _isLoading = true);

    final String? errorMessage = await AccountService.resetPassword(
      email: widget.email,
      code: widget.code,
      newPassword: newPassword,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passwort erfolgreich zurückgesetzt')),
    );

    Navigator.pushNamedAndRemoveUntil(context, 'SignInPage', (route) => false);
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DsAuthScaffold(
      title: 'Neues Passwort',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Bestätigter Code für ${widget.email}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
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
    );
  }
}

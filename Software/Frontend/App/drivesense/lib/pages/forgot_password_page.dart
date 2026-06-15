import 'package:drivesense/services/account_service.dart';
import 'package:drivesense/pages/reset_password_page.dart';
import 'package:drivesense/widgets/auth_scaffold.dart';
import 'package:drivesense/widgets/verification_code_dialog.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSending) {
      return;
    }

    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final String email = _emailController.text.trim();

    setState(() => _isSending = true);

    final String? sendError = await AccountService.requestPasswordReset(email);

    if (!mounted) {
      return;
    }

    setState(() => _isSending = false);

    if (sendError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(sendError)));
      return;
    }

    final String? code = await VerificationCodeDialog.collect(
      context: context,
      title: 'Code eingeben',
      description:
          'Wir haben einen Code an $email gesendet. Bitte gib ihn ein, um fortzufahren.',
      submitLabel: 'Weiter',
      resendLabel: 'Code erneut senden',
      onResend: () => AccountService.requestPasswordReset(email),
    );

    if (!mounted || code == null || code.isEmpty) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            ResetPasswordPage(email: email, code: code),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DsAuthScaffold(
      title: 'Passwort vergessen',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Gib die E-Mail-Adresse deines Accounts ein. Wir senden dir danach einen Code.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'E-Mail Adresse',
                hintText: 'name@example.com',
                border: OutlineInputBorder(),
              ),
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
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submit,
                child: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Code senden'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

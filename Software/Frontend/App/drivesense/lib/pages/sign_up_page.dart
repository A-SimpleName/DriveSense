import 'package:drivesense/config/app_colors.dart';
import 'package:drivesense/model/account.dart';
import 'package:drivesense/services/email_verification_service.dart';
import 'package:drivesense/services/sign_in_and_sign_up.dart';
import 'package:drivesense/widgets/auth_scaffold.dart';
import 'package:drivesense/widgets/verification_code_dialog.dart';
import 'package:flutter/material.dart';

enum _VerificationResult { verified, cancelled, failed }

class SignUpPage extends StatefulWidget {
  final bool? token;

  const SignUpPage({super.key, this.token});

  @override
  State<StatefulWidget> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  DateTime? _birthdate;
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool _isStrongPassword(String password) {
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(password);
  }

  Future<_VerificationResult> _openVerificationDialog(String email) async {
    final bool? verified = await VerificationCodeDialog.show(
      context: context,
      title: 'E-Mail bestaetigen',
      description:
          'Wir haben einen Bestätigungscode an $email gesendet. Bitte gib ihn ein, um die Registrierung abzuschliessen.',
      submitLabel: 'Code bestaetigen',
      resendLabel: 'Code erneut senden',
      onSubmit: (String code) =>
          EmailVerificationService.verifySignupEmail(email: email, code: code),
      onResend: () => EmailVerificationService.resendSignupVerification(email),
    );

    if (verified == true) {
      return _VerificationResult.verified;
    }

    if (verified == false) {
      return _VerificationResult.cancelled;
    }

    return _VerificationResult.failed;
  }

  Future<_VerificationResult> _recoverVerificationAfterServerError(
    String email,
  ) async {
    final String? resendError =
        await EmailVerificationService.resendSignupVerification(email);

    if (resendError != null) {
      return _VerificationResult.failed;
    }

    if (!mounted) {
      return _VerificationResult.failed;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Registrierung möglicherweise erstellt. Bitte E-Mail-Code bestaetigen.',
        ),
      ),
    );

    return _openVerificationDialog(email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DsAuthScaffold(
      title: 'Registrieren',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _firstNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Vorname',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nachname',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _birthdateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Geburtsdatum (optional)',
                border: OutlineInputBorder(),
                hintText: 'TT.MM.JJJJ',
              ),
              onTap: () async {
                final DateTime now = DateTime.now();
                final DateTime initial = _birthdate ?? DateTime(now.year - 20);
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: DateTime(1900),
                  lastDate: now,
                );
                if (picked != null) {
                  setState(() {
                    _birthdate = picked;
                    _birthdateController.text =
                        '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year.toString().padLeft(4, '0')}';
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-Mail Adresse',
                hintText: 'name@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Passwort',
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
              validator: (String? value) {
                final String password = value?.trim() ?? '';
                if (password.isEmpty) {
                  return 'Passwort darf nicht leer sein';
                }
                if (!_isStrongPassword(password)) {
                  return 'Mindestens 8 Zeichen, Gross-/Kleinbuchstabe und Zahl';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: const InputDecoration(
                labelText: 'Passwort wiederholen',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrieren'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sie haben bereits einen Account?',
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () => {
                Navigator.pushReplacementNamed(context, 'SignInPage'),
              },
              child: const Text('Anmelden'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitSignUp() async {
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte alle Felder ausfuellen.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Die Passwörter stimmen nicht ueberein.')),
      );
      return;
    }

    if (!_isStrongPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Das Passwort muss mindestens 8 Zeichen, einen Grossbuchstaben, einen Kleinbuchstaben und eine Zahl enthalten.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Account account = Account(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        birthdate: _birthdate,
      );

      final SignUpResult signUpResult = await SignInAndSignUp.signUp(account);
      if (!mounted) {
        return;
      }

      _VerificationResult verificationResult = _VerificationResult.failed;
      if (signUpResult.isSuccess) {
        verificationResult = await _openVerificationDialog(email);
      } else if (signUpResult.statusCode == 500) {
        verificationResult = await _recoverVerificationAfterServerError(email);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(signUpResult.message)));
        return;
      }

      if (!mounted) {
        return;
      }

      if (verificationResult == _VerificationResult.cancelled) {
        await EmailVerificationService.cancelSignup(
          email: email,
          password: password,
        );
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registrierung fehlgeschlagen, Email wurde nicht verifiziert',
            ),
          ),
        );
        return;
      }

      if (verificationResult != _VerificationResult.verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registrierung konnte nicht abgeschlossen werden. Bitte erneut versuchen.',
            ),
          ),
        );
        return;
      }

      final SignInResult signInResult = await SignInAndSignUp.signIn(
        email,
        password,
      );
      if (!signInResult.isSuccess ||
          signInResult.accountToken == null ||
          signInResult.accountToken!.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registrierung erfolgreich, aber automatischer Login fehlgeschlagen.',
            ),
          ),
        );
        return;
      }

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        SignInAndSignUp.redirectToProfileSelectPage(
          token: signInResult.accountToken,
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Registrierung: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

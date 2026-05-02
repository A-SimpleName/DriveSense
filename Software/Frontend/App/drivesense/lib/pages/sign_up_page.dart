import 'package:drivesense/config/app_colors.dart';
import 'package:drivesense/model/account.dart';
import 'package:drivesense/model/profile.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/profile_service.dart';
import 'package:drivesense/services/sign_in_and_sign_up.dart';
import 'package:drivesense/widgets/ds_auth_scaffold.dart';
import 'package:flutter/material.dart';

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
  final TextEditingController _birthdateController = TextEditingController();
  DateTime? _birthdate;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
                    _birthdateController.text = '${picked.day.toString().padLeft(2,'0')}.${picked.month.toString().padLeft(2,'0')}.${picked.year.toString().padLeft(4,'0')}';
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
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passwort',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
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

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte alle Felder ausfuellen.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Account account = Account(
        fName: firstName,
        lName: lastName,
        email: email,
        password: password,
        birthdate: _birthdate,
      );

      final SignUpResult signUpResult = await SignInAndSignUp.signUp(account);
      if (!signUpResult.isSuccess) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(signUpResult.message)));
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

      RuntimeStore.setAuthToken(signInResult.accountToken!);
      if (signInResult.refreshToken != null &&
          signInResult.refreshToken!.isNotEmpty) {
        RuntimeStore.setRefreshToken(signInResult.refreshToken!);
      }

      SignInAndSignUp.redirectToProfileSelectPage(token: signInResult.accountToken);

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(context, 'MainPage', (route) => false);
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

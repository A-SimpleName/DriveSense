import 'package:drivesense/config/app_colors.dart';
import 'package:drivesense/pages/forgot_password_page.dart';
import 'package:drivesense/widgets/ds_auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/services/sign_in_and_sign_up.dart';

class SignInPage extends StatefulWidget {
  final bool? token;

  const SignInPage({super.key, this.token});

  @override
  State<StatefulWidget> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

  String? email;
  String? password;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return DsAuthScaffold(
      title: 'Anmelden',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              onChanged: (value) {
                email = value;

                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-Mail Adresse',
                hintText: 'name@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              onChanged: (value) {
                password = value;

                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Passwort',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submitSignIn,
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Anmelden'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const ForgotPasswordPage(),
                  ),
                );
              },
              child: const Text('Passwort vergessen?'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sie haben noch keinen Account?',
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  'SignUpPage',
                );
              },
              child: const Text('Jetzt Registrieren'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitSignIn() async {
    final String emailValue = email?.trim() ?? '';
    final String passwordValue = password?.trim() ?? '';

    if (emailValue.isEmpty || passwordValue.isEmpty) {
      setState(() {
        _errorMessage =
            'Bitte E-Mail-Adresse und Passwort eingeben.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final SignInResult result = await SignInAndSignUp.signIn(
        emailValue,
        passwordValue,
      );

      debugPrint(
        'SignIn result: success=${result.isSuccess}, status=${result.statusCode}, message=${result.message}, accountToken=${result.accountToken != null ? 'present' : 'null'}',
      );

      if (!mounted) {
        return;
      }

      if (result.statusCode == 400) {
        setState(() {
          _errorMessage =
              'E-Mail-Adresse oder Passwort sind nicht korrekt.';
        });
        return;
      }

      if (result.isSuccess) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          SignInAndSignUp.redirectToProfileSelectPage(
            token: result.accountToken,
          ),
          (route) => false,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (e) {
      debugPrint('SignIn error: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Fehler bei der Anmeldung. Bitte versuchen Sie es erneut.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
import 'package:drivesense/constants/app_colors.dart';
import 'package:drivesense/runtime_store.dart';
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

  bool _isLoading = false;
  String? email;
  String? password;

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
              onChanged: (value) => email = value,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-Mail Adresse',
                hintText: 'name@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              onChanged: (value) => password = value,
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Anmelden'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => {
                // TODO: implement forgot password
              },
              child: const Text('Passwort vergessen?'),
            ),
            const SizedBox(height: 16),
            Text('Sie haben noch keinen Account?', textAlign: TextAlign.center),
            TextButton(
              onPressed: () => {
                Navigator.pushReplacementNamed(context, 'SignUpPage'),
              },
              child: Text('Jetzt Registrieren'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte E-Mail und Passwort eingeben.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));

      if (result.isSuccess) {
        if (result.accountToken != null && result.accountToken!.isNotEmpty) {
          RuntimeStore.setAuthToken(result.accountToken!);
        }

        if (result.refreshToken != null && result.refreshToken!.isNotEmpty) {
          RuntimeStore.setRefreshToken(result.refreshToken!);
        }

        Navigator.pushNamedAndRemoveUntil(
          context,
          SignInAndSignUp.redirectToProfileSelectPage(
            token: result.accountToken,
          ),
          (route) => false
        );
      }
    } catch (e) {
      debugPrint('SignIn error: $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fehler bei der Anmeldung. Bitte versuchen Sie es erneut.',
          ),
        ),
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

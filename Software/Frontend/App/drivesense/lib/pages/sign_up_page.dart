import 'package:drivesense/constants/app_colors.dart';
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

  final ValueNotifier<bool> passwordNotifier = ValueNotifier(true);
  final ValueNotifier<bool> fieldValidNotifier = ValueNotifier(false);

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
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-Mail Adresse',
                hintText: 'name@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
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
                onPressed: () {
                  // TODO: validate + login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Registrieren'),
              ),
            ),
            const SizedBox(height: 16),
            Text('Sie haben bereits einen Account?', textAlign: TextAlign.center),
            TextButton(
                onPressed: () => {
                  Navigator.pushReplacementNamed(context, 'LoginPage')
                },
                child: Text('Anmelden'),
            )
          ],
        ),
      ),
    );
  }
}

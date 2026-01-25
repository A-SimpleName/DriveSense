import 'package:drivesense/values/colors.dart';
import 'package:drivesense/widgets/ds_auth_scaffold.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final bool? token;

  const LoginPage({super.key, this.token});

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final ValueNotifier<bool> passwordNotifier = ValueNotifier(true);
  final ValueNotifier<bool> fieldValidNotifier = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return DsAuthScaffold(
      title: 'Login',
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
                child: const Text('Login'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: () => {
              // TODO: implement forgot password
            }, child: const Text('Passwort vergessen?')),
            const SizedBox(height: 16),
            Text('Sie haben noch keinen Account?', textAlign: TextAlign.center),
            TextButton(
                onPressed: () => {
                  Navigator.pushReplacementNamed(context, 'RegisterPage')
                },
                child: Text('Jetzt Registrieren'),
            )
          ],
        ),
      ),
    );
  }
}

import 'package:drivesense/constants/app_colors.dart';
import 'package:drivesense/widgets/ds_auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/services/sign_in_and_sign_up.dart';
import 'package:drivesense/model/account.dart';

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

  bool _isLoading = false;

  DateTime? selectedDate;
  String? firstName;
  String? lastName;
  String? email;
  String? password;

  final dateController = TextEditingController();

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
              onChanged: (value) => firstName = value,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Vorname',
                hintText: 'Max',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              onChanged: (value) => lastName = value,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Nachname',
                hintText: 'Mustermann',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Geburtsdatum (optional)',
                hintText: 'TT.MM.JJJJ',
                helperText: 'Kann leer bleiben',
                border: const OutlineInputBorder(),
                suffixIcon: dateController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            selectedDate = null;
                            dateController.clear();
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              readOnly: true,
              controller: dateController,
              onTap: () => pickDate(context),
            ),
            const SizedBox(height: 12),
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
              child: Text('Anmelden'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('de', 'DE'),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text =
            "${picked.day.toString().padLeft(2, '0')}."
            "${picked.month.toString().padLeft(2, '0')}."
            "${picked.year}";
      });
    }
  }

  Future<void> _submitSignUp() async {
    final String firstNameValue = firstName?.trim() ?? '';
    final String lastNameValue = lastName?.trim() ?? '';
    final String emailValue = email?.trim() ?? '';
    final String passwordValue = password ?? '';

    if (firstNameValue.isEmpty || lastNameValue.isEmpty || emailValue.isEmpty || passwordValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte füllen Sie alle Felder aus.')),
      );
      return;
    }

    if (passwordValue.length < 8 || !RegExp(r'[A-Z]').hasMatch(passwordValue) || !RegExp(r'[0-9]').hasMatch(passwordValue)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Das Passwort muss mindestens 8 Zeichen lang sein und mindestens einen Großbuchstaben und eine Zahl enthalten.')),
      );
      return;
    }

    final Account account = Account(
      fName: firstNameValue,
      lName: lastNameValue,
      email: emailValue,
      password: passwordValue,
      birthdate: selectedDate,
    );

    debugPrint('Signup pressed: firstName=$firstNameValue, lastName=$lastNameValue, email=$emailValue, birthDate=$selectedDate');

    setState(() {
      _isLoading = true;
    });

    try {
      final SignUpResult result = await SignInAndSignUp.signUp(account);
      debugPrint('Signup result: success=${result.isSuccess}, status=${result.statusCode}, message=${result.message}, token=${result.token != null ? 'present' : 'null'}');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );

      if (result.isSuccess) {
        if (result.token != null && result.token!.isNotEmpty) {
          Navigator.pushNamedAndRemoveUntil(context, 'MainPage', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, 'SignInPage', (route) => false);
        }
      }
    } catch (e, st) {
      debugPrint('Signup exception: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Registrieren: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

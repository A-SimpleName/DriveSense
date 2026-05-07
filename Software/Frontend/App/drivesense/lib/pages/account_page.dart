import 'package:flutter/material.dart';
import 'package:drivesense/model/account.dart';
import 'package:drivesense/services/account_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Account? _account;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final acc = await AccountService.fetchAccount();

    if (!mounted) return;

    setState(() {
      _account = acc;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final acc = _account;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: acc == null
            ? const Text('Kein Account geladen')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${acc.email}'),
                  const SizedBox(height: 8),
                  Text('Vorname: ${acc.fName}'),
                  Text('Nachname: ${acc.lName}'),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, 'EditAccountPage');
                    },
                    child: const Text('Account bearbeiten'),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, 'ChangePasswordPage');
                    },
                    child: const Text('Passwort ändern'),
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, 'DeleteAccountPage');
                    },
                    child: const Text('Profil löschen'),
                  ),
                ],
              ),
      ),
    );
  }
}
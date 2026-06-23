import 'package:drivesense/widgets/ds_app_bar.dart';
import 'package:flutter/material.dart';

class ImprintPage extends StatelessWidget {
  const ImprintPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const DsAppBar(title: 'Impressum'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              const Color(0xFFF9FAFD),
              const Color(0xFFF5F8FE),
              const Color(0xFFF0F4FA),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                            return;
                          }
                          Navigator.pushReplacementNamed(context, 'MainPage');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: colorScheme.primary,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Zurück zur App'),
                      ),
                      const SizedBox(height: 24),
                      const _Header(),
                      const _Section(
                        title: 'Medieninhaber und Betreiber',
                        lines: <String>[
                          'HTL Perg',
                          'Machlandstraße 48',
                          '4320 Perg',
                          'Österreich',
                        ],
                      ),
                      const _Section(
                        title: 'Kontakt',
                        lines: <String>[
                          'E-Mail: at.drivesense@gmail.com',
                          'Telefon: +43 7262 52391',
                        ],
                      ),
                      const _Section(
                        title: 'Verantwortlich für den Inhalt',
                        lines: <String>[
                          'Eric Hölzl (Projektleitung)',
                          'HTL Perg',
                          'Machlandstraße 48',
                          '4320 Perg',
                          'Österreich',
                        ],
                      ),
                      const _Section(
                        title: 'Zweck des Mediums',
                        lines: <String>[
                          'DriveSense ist ein nicht-kommerzielles Schulprojekt und stellt eine Web-App zur digitalen Fahrtenaufzeichnung, Fahrzeugverwaltung und Fahrtenprotokollverwaltung bereit.',
                        ],
                      ),
                      _PrivacySection(colorScheme: colorScheme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'DriveSense',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.04,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Impressum',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _Section({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    final TextStyle? bodyStyle = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (String line) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(line, style: bodyStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final ColorScheme colorScheme;

  const _PrivacySection({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final TextStyle? bodyStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Datenschutz',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                'Informationen zur Verarbeitung personenbezogener Daten finden Sie in der ',
                style: bodyStyle,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, 'PrivacyPolicyPage');
                },
                child: Text(
                  'Datenschutzerklärung',
                  style: bodyStyle?.copyWith(
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text('.', style: bodyStyle),
            ],
          ),
        ],
      ),
    );
  }
}

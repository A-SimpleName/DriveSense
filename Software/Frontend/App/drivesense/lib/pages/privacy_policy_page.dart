import 'package:flutter/material.dart';
import 'package:drivesense/widgets/ds_app_bar.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const List<String> _dataCategories = <String>[
    'Accountdaten: Vorname, Nachname, E-Mail-Adresse, Passwort-Hash, Verifizierungsstatus, optionales Geburtsdatum, Erstellungs- und Löschzeitpunkte.',
    'Profildaten: Profilname, Rolle und Zuordnung zum Account.',
    'Fahrzeugdaten: Modell, Kennzeichen, Kilometerstand, Rollen und Zuordnungen zu Profilen.',
    'Fahrtdaten: Start- und Endzeit, Strecke, Kilometerstände, Start-, Ziel- und entferntester Punkt, Fahrbahnbedingungen, Fahrtart sowie Momentaufnahmen von Fahrzeug, Kennzeichen und Profilname.',
    'Standort- und Bewegungsdaten: GPS-Koordinaten, Genauigkeit, Geschwindigkeit, Richtung und Zeitstempel der Trackingpunkte während einer aufgezeichneten Fahrt.',
    'Gruppen-, Protokoll- und Einladungsdaten: Gruppenname, Mitgliederrollen, Protokollname, eingeladene Accounts, einladende Profile, Einladungscodes als Hash, Status und Ablaufzeitpunkte.',
    'Sicherheits- und Kommunikationsdaten: E-Mail-Verifizierungscodes und Passwort-Zurücksetzen-Codes jeweils als Hash, Ablaufzeitpunkt und Nutzungsstatus.',
  ];

  static const List<String> _rights = <String>[
    'Auskunft über die gespeicherten personenbezogenen Daten',
    'Berichtigung unrichtiger Daten',
    'Löschung oder Einschränkung der Verarbeitung',
    'Datenübertragbarkeit, soweit technisch und rechtlich anwendbar',
    'Widerspruch gegen Verarbeitungen auf Grundlage berechtigter Interessen',
    'Beschwerde bei der zuständigen Datenschutzaufsichtsbehörde',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(title: 'Datenschutzerklärung'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'DriveSense',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Datenschutzerklärung',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Diese Datenschutzerklärung informiert darüber, welche personenbezogenen Daten DriveSense verarbeitet, wenn die App zur Fahrtenprotokollierung genutzt wird.',
                  ),
                  const _PrivacySection(
                    title: '1. Verantwortlicher und Kontakt',
                    body:
                        'Verantwortlich für die Datenverarbeitung ist DriveSense. Fragen zum Datenschutz können per E-Mail an at.drivesense@gmail.com gerichtet werden.',
                  ),
                  _ListSection(
                    title: '2. Verarbeitete personenbezogene Daten',
                    body:
                        'DriveSense verarbeitet nur Daten, die für Registrierung, Anmeldung, Profilverwaltung, Fahrzeugverwaltung, Fahrtenaufzeichnung, Fahrtenprotokolle, Gruppenfunktionen, Einladungen und Sicherheitsfunktionen erforderlich sind.',
                    items: _dataCategories,
                  ),
                  const _PrivacySection(
                    title: '3. Zwecke der Verarbeitung',
                    body:
                        'Die Daten werden verwendet, um Accounts bereitzustellen, Nutzer zu authentifizieren, Profile und Rollen zu verwalten, Fahrzeuge und Gruppen zu organisieren, Fahrten mit Standortpunkten aufzuzeichnen, Fahrtenprotokolle zu erstellen, PDF-Exporte zu ermöglichen, Einladungen zu versenden und Missbrauch zu verhindern.',
                  ),
                  const _PrivacySection(
                    title: '4. Rechtsgrundlagen',
                    body:
                        'Die Verarbeitung erfolgt, soweit sie für die Nutzung von DriveSense notwendig ist, auf Grundlage von Art. 6 Abs. 1 lit. b DSGVO. Sicherheitsrelevante Verarbeitungen, Protokollierung und Missbrauchsschutz erfolgen auf Grundlage von Art. 6 Abs. 1 lit. f DSGVO. Soweit gesetzliche Aufbewahrungspflichten bestehen, erfolgt die Verarbeitung auf Grundlage von Art. 6 Abs. 1 lit. c DSGVO.',
                  ),
                  const _PrivacySection(
                    title: '5. Standortdaten und Fahrtenaufzeichnung',
                    body:
                        'Standortdaten werden nur im Zusammenhang mit einer aufgezeichneten Fahrt verarbeitet. Dabei werden Koordinaten, Genauigkeit, Geschwindigkeit, Richtung und Zeitstempel gespeichert, um die Fahrt nachvollziehbar zu dokumentieren. Ohne diese Daten kann die automatische Fahrtenprotokollierung nicht vollständig genutzt werden.',
                  ),
                  const _PrivacySection(
                    title: '6. Empfänger und externe Dienste',
                    body:
                        'Innerhalb von DriveSense erhalten nur berechtigte Nutzer Zugriff auf Daten, etwa Mitglieder gemeinsamer Gruppen oder berechtigte Fahrzeugnutzer entsprechend ihrer Rolle. Für Funktionen wie Geocoding, Karten, E-Mail-Versand oder Fahrbahn-/Wetterdaten können technische Dienstleister eingebunden werden. An diese Dienste werden nur die Daten übermittelt, die für die jeweilige Funktion erforderlich sind.',
                  ),
                  const _PrivacySection(
                    title: '7. Speicherdauer und Löschung',
                    body:
                        'Daten werden gespeichert, solange sie für die Nutzung des Accounts und die Fahrtenprotokollierung erforderlich sind. Nicht verifizierte Accounts können automatisch gelöscht werden. Tokens für E-Mail-Verifizierung, Passwort-Zurücksetzung und Einladungen haben Ablaufzeitpunkte. Beim Löschen von Accounts, Profilen, Fahrzeugen, Gruppen, Protokollen oder Fahrten werden Daten je nach technischer und rechtlicher Notwendigkeit gelöscht, anonymisiert oder mit Löschzeitpunkt gesperrt.',
                  ),
                  const _PrivacySection(
                    title: '8. Sicherheit',
                    body:
                        'Passwörter, Verifizierungs-, Einladungs- und Passwort-Zurücksetzen-Codes werden nicht im Klartext gespeichert, sondern als Hash. Der Zugriff auf geschützte Bereiche erfolgt über Authentifizierungstokens und rollenbasierte Berechtigungen.',
                  ),
                  _ListSection(
                    title: '9. Betroffenenrechte',
                    body:
                        'Betroffene Personen haben nach Maßgabe der DSGVO insbesondere folgende Rechte:',
                    items: _rights,
                  ),
                  const Text(
                    'Anfragen können an at.drivesense@gmail.com gesendet werden.',
                  ),
                  const _PrivacySection(
                    title: '10. Aktualität',
                    body:
                        'Diese Datenschutzerklärung kann angepasst werden, wenn sich Funktionen, Datenverarbeitungen oder rechtliche Anforderungen ändern.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String title;
  final String body;

  const _PrivacySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(body),
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  final String title;
  final String body;
  final List<String> items;

  const _ListSection({
    required this.title,
    required this.body,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(body),
          const SizedBox(height: 8),
          ...items.map(
            (String item) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('- '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

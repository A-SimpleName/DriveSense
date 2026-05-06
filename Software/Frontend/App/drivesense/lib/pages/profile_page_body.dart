import 'package:drivesense/services/profile_service.dart';
import 'package:drivesense/widgets/vehicle_widgets.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ProfilePageBody
// ═══════════════════════════════════════════════════════════════════════════
//
// StatefulWidget weil wir den Profilnamen vom Server laden müssen.
// Beim ersten Rendern steht noch nichts drin → Ladeanzeige → dann Daten.
//
class ProfilePageBody extends StatefulWidget {
  const ProfilePageBody({super.key});

  @override
  State<ProfilePageBody> createState() => _ProfilePageBodyState();
}

class _ProfilePageBodyState extends State<ProfilePageBody> {
  // Der Name und die Rolle des aktuell eingeloggten Profils.
  // "?" (noch nicht geladen).
  String? _profileName;
  String? _profileRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // ProfileService.fetchProfiles() holt alle Profile des Accounts vom Server.
    // Wir nehmen das erste — das ist das aktive Profil.
    final profiles = await ProfileService.fetchProfiles();

    if (!mounted) return;

    setState(() {
      if (profiles.isNotEmpty) {
        _profileName = profiles.first.name;
        _profileRole = profiles.first.role ?? 'Fahrschüler';
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // SafeArea: stellt sicher dass der Inhalt nicht hinter der Statusleiste
    // oder dem Notch liegt
    return SafeArea(
      // SingleChildScrollView: macht die ganze Seite scrollbar wenn der
      // Inhalt nicht reinpasst (z.B. viele Fahrzeuge)
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profil-Infos ───────────────────────────────────────────────
            _buildProfileHeader(),

            const SizedBox(height: 24), // vertikaler Abstand

            // ── Fahrzeug-Tabelle ───────────────────────────────────────────
            // VehicleTableWidget ist ein eigenes Widget das sich selbst um
            // Laden, Anzeigen, Bearbeiten und Löschen kümmert.
            // Wir müssen hier nichts weiter tun als es einzubinden.
            const VehicleTableWidget(),
          ],
        ),
      ),
    );
  }

  // Baut den oberen Bereich mit Name und Rolle.
  // Ausgelagert in eine eigene Methode damit build() übersichtlich bleibt.
  Widget _buildProfileHeader() {
    if (_isLoading) {
      // Solange Daten laden: Ladekreis + Text
      return const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Profil wird geladen...'),
        ],
      );
    }

    // Card: eine Karte mit leichtem Schatten — gut zum Gruppieren von Infos
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: Icon und Text nebeneinander
            Row(
              children: [
                // CircleAvatar: runder Kreis mit einem Icon oder Buchstaben drin
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    // Ersten Buchstaben des Namens anzeigen, oder "?" wenn leer
                    _profileName?.isNotEmpty == true
                        ? _profileName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 16),
                // Expanded: nimmt den restlichen horizontalen Platz ein
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profileName ?? 'Unbekannt',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profileRole ?? '',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
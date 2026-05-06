import 'package:drivesense/services/profile_service.dart';
import 'package:drivesense/widgets/vehicle_widgets.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/model/profile.dart';

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
    final profiles = await ProfileService.fetchProfiles();

    if (!mounted) return;

    final int? currentId = RuntimeStore.currentProfileId;

    Profile? selectedProfile;

    if (currentId != null) {
      try {
        selectedProfile = profiles.firstWhere((p) => p.id == currentId);
      } catch (_) {
        selectedProfile = null;
      }
    }

    // Fallback (wenn nichts gefunden wurde)
    selectedProfile ??= profiles.isNotEmpty ? profiles.first : null;

    setState(() {
      if (selectedProfile != null) {
        _profileName = selectedProfile.name;
        _profileRole = selectedProfile.role ?? 'Fahrschüler';
      } else {
        _profileName = 'Unbekannt';
        _profileRole = '';
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
      child: InkWell(
        onTap: () {
          debugPrint('Clicked');
          Navigator.pushNamed(
            context,
            'ProfileSelectPage',
          ).then((_) => _loadProfile()); 
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(
                      _profileName?.isNotEmpty == true
                          ? _profileName![0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 16),
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
      ),
    );
  }
}

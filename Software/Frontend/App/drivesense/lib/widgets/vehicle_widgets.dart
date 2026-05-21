import 'package:drivesense/model/vehicle.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/vehicle_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════
// VehicleTableWidget
// ═══════════════════════════════════════════════════════════════════════════
//
// Ein StatefulWidget hält sich einen eigenen "State" — also veränderliche
// Daten die sich während der Laufzeit ändern können (z.B. die Fahrzeugliste).
// Ein StatelessWidget kann das nicht, der ist immer gleich.
//
// Hier brauchen wir State weil:
//   1. Wir Fahrzeuge vom Server laden müssen (async, dauert eine Weile)
//   2. Die Liste sich ändert wenn man hinzufügt/bearbeitet/löscht
//
class VehicleTableWidget extends StatefulWidget {
  const VehicleTableWidget({super.key});

  @override
  State<VehicleTableWidget> createState() => _VehicleTableWidgetState();
}

class _VehicleTableWidgetState extends State<VehicleTableWidget> {
  // _vehicles: die aktuell angezeigte Liste. Startet leer.
  List<Vehicle> _vehicles = [];

  // _isLoading: true solange wir auf den Server warten → zeigt Ladekreis
  bool _isLoading = true;

  // initState() wird genau einmal aufgerufen wenn das Widget zum ersten Mal
  // eingeblendet wird — perfekt für initiale Datenbankabfragen.
  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  // Fahrzeuge vom Server holen und in den State speichern.
  // "async" bedeutet: diese Funktion kann warten (auf den Server)
  // ohne die App einzufrieren.
  Future<void> _loadVehicles() async {
    // setState() sagt Flutter: "bau dieses Widget neu auf"
    setState(() => _isLoading = true);

    // "await" bedeutet: warte hier bis die Antwort da ist
    final vehicles = await VehicleService.fetchVehicles();

    // mounted prüft ob das Widget noch existiert (könnte zwischenzeitlich
    // weggescrollt worden sein) — verhindert einen Crash
    if (!mounted) return;

    setState(() {
      _vehicles = vehicles;
      RuntimeStore.setVehicles(vehicles);
      _isLoading = false;
    });
  }

  // Zeigt einen Dialog zum Hinzufügen/Bearbeiten eines Fahrzeugs.
  // [vehicle] ist null wenn wir ein neues anlegen, sonst das zu bearbeitende.
  Future<void> _openVehicleDialog({Vehicle? vehicle}) async {
    // showDialog() blendet ein Popup ein und wartet bis es geschlossen wird.
    // Das Ergebnis (true/false) sagt uns ob gespeichert wurde.
    final bool? saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // kein Schließen durch Danebentippen
      builder: (ctx) => _VehicleDialog(vehicle: vehicle),
    );

    // Wenn gespeichert wurde, Liste neu laden damit die Änderung sichtbar wird
    if (saved == true) {
      await _loadVehicles();
    }
  }

  // Zeigt einen Bestätigungs-Dialog und entfernt die Fahrzeug-Verknuepfung.
  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fahrzeug entfernen'),
        content: Text(
          'Moechtest du "${vehicle.model}" (${vehicle.licensePlate}) aus diesem Profil entfernen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final VehicleActionResult result =
        await VehicleService.deleteVehicleWithResult(vehicle.id);
    if (!mounted) return;

    // ScaffoldMessenger zeigt kurze Info-Meldungen unten am Bildschirm (SnackBar)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );

    if (result.isSuccess) await _loadVehicles();
  }

  @override
  Widget build(BuildContext context) {
    // Solange geladen wird: Ladekreis anzeigen
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Column: ordnet Kinder vertikal untereinander an
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Kopfzeile: Titel + "Hinzufügen"-Button nebeneinander ──────────
        // Row: ordnet Kinder horizontal nebeneinander an
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fahrzeuge',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _openVehicleDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Hinzufügen'),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (_vehicles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Keine Fahrzeuge vorhanden.'),
          )
        else
          // SingleChildScrollView macht die Tabelle horizontal scrollbar
          // falls der Bildschirm zu schmal ist
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
              children: [
                // ── Kopfzeile der Tabelle ──────────────────────────────
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: const [
                    _HeaderCell('Modell'),
                    _HeaderCell('Kennzeichen'),
                    _HeaderCell('Kilometerstand'),
                    _HeaderCell('Aktionen'),
                  ],
                ),

                // ── Eine Zeile pro Fahrzeug ────────────────────────────
                // .map() verwandelt jedes Vehicle-Objekt in eine TableRow
                ..._vehicles.map(
                  (vehicle) => TableRow(
                    children: [
                      _DataCell(vehicle.model),
                      _DataCell(vehicle.licensePlate),
                      _DataCell('${vehicle.mileage} km'),
                      // Aktionen: Bearbeiten + Entfernen Icons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Bearbeiten',
                              onPressed: () =>
                                  _openVehicleDialog(vehicle: vehicle),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                                color: Colors.red,
                              ),
                              tooltip: 'Entfernen',
                              onPressed: () => _deleteVehicle(vehicle),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Hilfwidgets für die Tabellenzellen
// ═══════════════════════════════════════════════════════════════════════════
//
// Kleine wiederverwendbare private Widgets — damit wir nicht überall den
// gleichen Padding/Style copy-pasten müssen.

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  const _DataCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(text),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _VehicleDialog — Popup zum Anlegen / Bearbeiten eines Fahrzeugs
// ═══════════════════════════════════════════════════════════════════════════
//
// Privates Widget (Unterstrich _) → nur in dieser Datei sichtbar.
// vehicle == null → neues anlegen
// vehicle != null → bestehendes bearbeiten
//
class _VehicleDialog extends StatefulWidget {
  final Vehicle? vehicle;
  const _VehicleDialog({this.vehicle});

  @override
  State<_VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends State<_VehicleDialog> {
  // TextEditingController: verknüpft ein Textfeld mit einer Variable
  // sodass wir den eingetippten Text jederzeit auslesen können
  late final TextEditingController _modelCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _mileageCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Felder vorausfüllen wenn wir ein bestehendes Fahrzeug bearbeiten
    _modelCtrl = TextEditingController(text: widget.vehicle?.model ?? '');
    _plateCtrl = TextEditingController(
      text: widget.vehicle?.licensePlate ?? '',
    );
    _mileageCtrl = TextEditingController(
      text: widget.vehicle != null ? widget.vehicle!.mileage.toString() : '',
    );
  }

  @override
  void dispose() {
    // Controller freigeben wenn Dialog geschlossen wird (verhindert Memory Leak)
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String model = _modelCtrl.text.trim();
    final String plate = _plateCtrl.text.trim();
    final int? mileage = int.tryParse(_mileageCtrl.text.trim());

    // Validierung
    if (model.isEmpty || plate.isEmpty || mileage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte alle Felder korrekt ausfüllen.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    bool success;

    if (widget.vehicle == null) {
      // ── Neues Fahrzeug anlegen ─────────────────────────────────────────
      final Vehicle? created = await VehicleService.createVehicle(
        model: model,
        licensePlate: plate,
        mileage: mileage,
      );
      success = created != null;
    } else {
      // ── Bestehendes Fahrzeug updaten ───────────────────────────────────
      // Wir erstellen ein neues Vehicle-Objekt mit den geänderten Werten
      // aber der gleichen ID wie das Original
      final Vehicle updated = Vehicle(
        id: widget.vehicle!.id,
        userId: widget.vehicle!.userId,
        model: model,
        licensePlate: plate,
        mileage: mileage,
      );
      success = await VehicleService.updateVehicle(updated);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      // Navigator.pop() schließt den Dialog
      // true = "wurde gespeichert" → VehicleTableWidget lädt neu
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speichern fehlgeschlagen.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.vehicle == null;

    return AlertDialog(
      title: Text(isNew ? 'Fahrzeug hinzufügen' : 'Fahrzeug bearbeiten'),
      content: Column(
        mainAxisSize: MainAxisSize.min, // Dialog nur so groß wie nötig
        children: [
          TextField(
            controller: _modelCtrl,
            decoration: const InputDecoration(labelText: 'Modell'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _plateCtrl,
            decoration: const InputDecoration(labelText: 'Kennzeichen'),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _mileageCtrl,
            decoration: const InputDecoration(labelText: 'Kilometerstand'),
            keyboardType: TextInputType.number, // zeigt Zahlentastatur
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ], // nur Ziffern
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save, // null deaktiviert den Button
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Speichern'),
        ),
      ],
    );
  }
}

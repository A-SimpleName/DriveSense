import { useState } from "react"
import "../../styles/addForms.css"
import { createVehicle } from "../../services/vehicleService";

interface Props {
    onClose: () => void;
    onSuccess: () => void;
}

export function VehicleAddForm({ onClose, onSuccess }: Props) {
    const [model, setModel] = useState("");
    const [licensePlate, setLicensePlate] = useState("");
    const [mileage, setMileage] = useState(0);
    const [error, setError] = useState<string | null>(null);
    const [saving, setSaving] = useState(false);

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        if (!model || !licensePlate) {
            setError("Bitte alle Felder ausfüllen");
            return;
        }

        setSaving(true);
        setError(null);

        try {
            await createVehicle({ model, licensePlate, mileage });
            onSuccess(); // Tabelle neu laden
            onClose();   // Form schließen
        } catch (err: any) {
            setError(err?.message || "Fehler beim Erstellen");
        } finally {
            setSaving(false);
        }
    }

    return (
        <div className="vehicleAddForm">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <h2>Fahrzeug hinzufügen</h2>
                <button type="button" onClick={onClose} style={{ cursor: "pointer" }}>✕</button>
            </div>

            {error && <p style={{ color: "red" }}>{error}</p>}

            <form onSubmit={handleSubmit}>
                <table>
                    <tbody>
                        <tr>
                            <td><label>Modell</label></td>
                            <td><input
                                type="text"
                                value={model}
                                onChange={(e) => setModel(e.target.value)}
                            /></td>
                        </tr>
                        <tr>
                            <td><label>Kennzeichen</label></td>
                            <td><input
                                type="text"
                                value={licensePlate}
                                onChange={(e) => setLicensePlate(e.target.value)}
                            /></td>
                        </tr>
                        <tr>
                            <td><label>Kilometerstand</label></td>
                            <td><input
                                type="number"
                                value={mileage}
                                onChange={(e) => setMileage(Number(e.target.value))}
                            /></td>
                        </tr>
                    </tbody>
                </table>
                <button type="submit" disabled={saving}>
                    {saving ? "Wird gespeichert..." : "Hinzufügen"}
                </button>
            </form>
        </div>
    )
}

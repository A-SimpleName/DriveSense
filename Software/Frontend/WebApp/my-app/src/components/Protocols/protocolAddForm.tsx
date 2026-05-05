import { useState } from "react"
import "../../styles/addForms.css"
import { createProtocol } from "../../services/protocolService";

interface Props {
    onClose: () => void;
    onSuccess: () => void;
}

export function ProtocolAddForm({ onClose, onSuccess }: Props) {
    const [name, setName] = useState("");
    const [error, setError] = useState<string | null>(null);
    const [saving, setSaving] = useState(false);

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        if (!name) {
            setError("Bitte alle Felder ausfüllen");
            return;
        }

        setSaving(true);
        setError(null);

        try {
            await createProtocol({ name });
            onSuccess(); 
            onClose(); 
        } catch (err: any) {
            setError(err?.message || "Fehler beim Erstellen");
        } finally {
            setSaving(false);
        }
    }

    return (
        <div className="protocolAddForm">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <h2>Protokoll hinzufügen</h2>
                <button type="button" onClick={onClose} style={{ cursor: "pointer" }}>✕</button>
            </div>

            {error && <p style={{ color: "red" }}>{error}</p>}

            <form onSubmit={handleSubmit}>
                <table>
                    <tbody>
                        <tr>
                            <td><label>Name</label></td>
                            <td><input
                                type="text"
                                value={name}
                                onChange={(e) => setName(e.target.value)}
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
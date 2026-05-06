import { useState } from "react"
import "../../styles/addForms.css"
import { createGroup } from "../../services/groupService";
import type { UserGroup } from "../../model/usergroup";

interface Props {
    onClose: () => void;
    onCreated: (group: UserGroup) => void;
}

export function GroupAddForm({ onClose, onCreated }: Props) {
    const [name, setName] = useState("");
    const [error, setError] = useState<string | null>(null);
    const [saving, setSaving] = useState(false);

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        if (!name.trim()) {
            setError("Bitte einen Gruppennamen eingeben");
            return;
        }

        setSaving(true);
        setError(null);

        try {
            const newGroup = await createGroup(name.trim());
            onCreated(newGroup);
            onClose();
        } catch (err: any) {
            setError(err?.message || "Fehler beim Erstellen");
        } finally {
            setSaving(false);
        }
    }

    return (
        <div className="vehicleAddForm">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <h2>Gruppe erstellen</h2>
                <button type="button" onClick={onClose} style={{ cursor: "pointer" }}>✕</button>
            </div>

            {error && <p style={{ color: "red" }}>{error}</p>}

            <form onSubmit={handleSubmit}>
                <table>
                    <tbody>
                        <tr>
                            <td><label>Gruppenname</label></td>
                            <td><input
                                type="text"
                                value={name}
                                onChange={(e) => setName(e.target.value)}
                                autoFocus
                            /></td>
                        </tr>
                    </tbody>
                </table>
                <button type="submit" disabled={saving}>
                    {saving ? "Wird gespeichert..." : "Erstellen"}
                </button>
            </form>
        </div>
    )
}
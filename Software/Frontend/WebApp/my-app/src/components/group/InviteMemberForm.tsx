import { useState } from "react";
import { inviteMember } from "../../services/groupService";
import "../../styles/addForms.css";

interface Props {
    groupId: number;
    onClose: () => void;
}

export function InviteMemberForm({ groupId, onClose }: Props) {
    const [email, setEmail] = useState("");
    const [error, setError] = useState<string | null>(null);
    const [saving, setSaving] = useState(false);
    const [success, setSuccess] = useState(false);

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        if (!email.trim()) {
            setError("Bitte eine Email-Adresse eingeben");
            return;
        }

        setSaving(true);
        setError(null);

        try {
            await inviteMember(groupId, email.trim());
            setSuccess(true);
        } catch (err: any) {
            setError(err?.message || "Fehler beim Senden der Einladung");
        } finally {
            setSaving(false);
        }
    }

    return (
        <div className="vehicleAddForm">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <h2>Mitglied einladen</h2>
                <button type="button" onClick={onClose} style={{ cursor: "pointer" }}>✕</button>
            </div>

            {success ? (
                <div>
                    <p style={{ color: "green" }}>Einladung wurde an {email} gesendet!</p>
                    <div style={{ display: "flex", justifyContent: "flex-end" }}>
                        <button type="button" onClick={onClose}>Schließen</button>
                    </div>
                </div>
            ) : (
                <form onSubmit={handleSubmit}>
                    <table>
                        <tbody>
                            <tr>
                                <td><label>Email</label></td>
                                <td>
                                    <input
                                        type="email"
                                        value={email}
                                        onChange={e => setEmail(e.target.value)}
                                        placeholder="beispiel@email.com"
                                        autoFocus
                                    />
                                </td>
                            </tr>
                        </tbody>
                    </table>

                    {error && <p style={{ color: "red" }}>{error}</p>}

                    <button type="submit" disabled={saving}>
                        {saving ? "Wird gesendet..." : "Einladung senden"}
                    </button>
                </form>
            )}
        </div>
    );
}
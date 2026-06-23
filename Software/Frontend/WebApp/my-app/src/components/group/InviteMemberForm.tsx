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
            setError("Bitte eine E-Mail-Adresse eingeben");
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
        <div className="addForm">
            <div className="addForm-header">
                <h2>Mitglied einladen</h2>
                <button type="button" className="addForm-close" onClick={onClose} aria-label="Schließen">✕</button>
            </div>

            {success ? (
                <>
                    <div className="addForm-body">
                        <div className="addForm-field">
                            <p style={{ color: "#16a34a", margin: 0 }}>
                                Einladung wurde an <strong>{email}</strong> gesendet!
                            </p>
                        </div>
                    </div>
                    <div className="addForm-footer">
                        <button type="button" className="addForm-submit" onClick={onClose}>Schließen</button>
                    </div>
                </>
            ) : (
                <form onSubmit={handleSubmit}>
                    {error && <p className="addForm-error">{error}</p>}

                    <div className="addForm-body">
                        <div className={`addForm-field ${error ? "addForm-field--error" : ""}`}>
                            <label htmlFor="invite-email">E-Mail</label>
                            <input
                                id="invite-email"
                                type="email"
                                value={email}
                                onChange={e => { setEmail(e.target.value); setError(null); }}
                                placeholder="beispiel@email.com"
                                autoFocus
                            />
                        </div>
                    </div>

                    <div className="addForm-footer">
                        <button type="button" className="addForm-cancel" onClick={onClose}>Abbrechen</button>
                        <button type="submit" className="addForm-submit" disabled={saving}>
                            {saving ? "Wird gesendet…" : "Einladung senden"}
                        </button>
                    </div>
                </form>
            )}
        </div>
    );
}
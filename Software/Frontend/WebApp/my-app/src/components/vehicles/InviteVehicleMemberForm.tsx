import { useState } from "react";
import { createPortal } from "react-dom";
import { inviteToVehicle } from "../../services/vehicleService";
import "../../styles/addForms.css";

interface Props {
    vehicleId: number;
    vehicleLabel: string;
    canInviteCoOwner: boolean;
    onClose: () => void;
    onInvited?: () => void;
}

const ROLE_OPTIONS: { label: string; value: "DRIVER" | "CO_OWNER" }[] = [
    { label: "Fahrer", value: "DRIVER" },
    { label: "Mitbesitzer", value: "CO_OWNER" }
];

export function InviteVehicleMemberForm({ vehicleId, vehicleLabel, canInviteCoOwner, onClose, onInvited }: Props) {
    const [email, setEmail] = useState("");
    const [role, setRole] = useState<"DRIVER" | "CO_OWNER">("DRIVER");
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
            await inviteToVehicle(vehicleId, email.trim(), role);
            setSuccess(true);
            onInvited?.();
        } catch (err: any) {
            setError(err?.message || "Fehler beim Senden der Einladung");
        } finally {
            setSaving(false);
        }
    }

    if (typeof document === "undefined") return null;

    return createPortal(
        <div className="addForm-overlay">
            <div className="addForm">
                <div className="addForm-header">
                    <h2>Mitglied zu {vehicleLabel} einladen</h2>
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
                                <label htmlFor="vehicle-invite-email">E-Mail</label>
                                <input
                                    id="vehicle-invite-email"
                                    type="email"
                                    value={email}
                                    onChange={e => { setEmail(e.target.value); setError(null); }}
                                    placeholder="beispiel@email.com"
                                    autoFocus
                                />
                                <span style={{ fontSize: "0.85rem", color: "var(--text-secondary)" }}>
                                    Du kannst auch deine eigene E-Mail einladen.
                                </span>
                            </div>

                            {canInviteCoOwner && (
                                <div className="addForm-field">
                                    <label htmlFor="vehicle-invite-role">Rolle</label>
                                    <select
                                        id="vehicle-invite-role"
                                        value={role}
                                        onChange={e => setRole(e.target.value as "DRIVER" | "CO_OWNER")}
                                    >
                                        {ROLE_OPTIONS.map(o => (
                                            <option key={o.value} value={o.value}>{o.label}</option>
                                        ))}
                                    </select>
                                </div>
                            )}
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
        </div>,
        document.body
    );
}

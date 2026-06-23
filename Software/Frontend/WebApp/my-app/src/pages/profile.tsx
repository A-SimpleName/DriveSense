import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { Button } from "../components/button";
import { ConfirmationDialog } from "../components/ConfirmationDialog";
import { useAuth } from "../context/authContext";
import { updateProfile, deleteProfile } from "../services/profileService";
import InfoRow from "../components/infoRow";
import { Check, X, Edit2, Trash2, ArrowLeftRight } from "lucide-react";

const ROLE_LABELS: Record<string, string> = {
    PRIVAT: "Privat",
    FAHRSCHUELER: "Fahrschüler",
    BERUFSFAHRER: "Berufsfahrer"
};

function roleLabel(role?: string) {
    if (!role) return "Nicht verfügbar";
    return ROLE_LABELS[role] || role;
}

export default function ProfilePage() {
    const navigate = useNavigate();
    const { profile, setProfile, setProfileSelected, switchProfile } = useAuth();

    const [isEditing, setIsEditing] = useState(false);
    const [editName, setEditName] = useState(profile?.name || "");
    const [editRole, setEditRole] = useState(profile?.role || "");
    const [confirmDelete, setConfirmDelete] = useState(false);
    const [saving, setSaving] = useState(false);
    const [saveError, setSaveError] = useState<string | null>(null);
    const [deleteError, setDeleteError] = useState<string | null>(null);

    useEffect(() => {
        if (profile) {
            setEditName(profile.name);
            setEditRole(profile.role);
        }
    }, [profile]);

    const handleSwitch = async () => {
        await switchProfile();
        navigate("/");
    };

    const handleSave = async () => {
        if (!profile?.id) return;
        setSaving(true);
        setSaveError(null);
        try {
            const updated = await updateProfile(profile.id, { name: editName, role: editRole });
            setProfile(updated);
            setIsEditing(false);
        } catch (err: any) {
            setSaveError(err?.message || "Speichern fehlgeschlagen");
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async () => {
        if (!profile?.id) return;
        setDeleteError(null);
        try {
            await deleteProfile(profile.id);
            setProfile(null);
            setProfileSelected(false);
            navigate("/");
        } catch (err: any) {
            setDeleteError(err?.message || "Löschen fehlgeschlagen");
            setConfirmDelete(false);
        }
    };

    return (
        <div>
            <h1>Mein Profil</h1>

            {deleteError && (
                <p className="error-text" style={{ marginBottom: "1rem" }}>{deleteError}</p>
            )}

            <div style={{ marginBottom: "2rem" }}>
                <h2>Profil-Informationen</h2>
                <div style={{ display: "grid", gap: "0.75rem", maxWidth: "420px" }}>
                    {isEditing ? (
                        <>
                            <label style={{ display: "grid", gap: "0.4rem" }}>
                                <span style={{ fontWeight: 700 }}>Profilname</span>
                                <input
                                    value={editName}
                                    onChange={e => setEditName(e.target.value)}
                                    style={{ width: "100%", padding: "10px 12px", borderRadius: "10px", border: "1px solid var(--border)" }}
                                />
                            </label>
                            <label style={{ display: "grid", gap: "0.4rem" }}>
                                <span style={{ fontWeight: 700 }}>Rolle</span>
                                <select
                                    value={editRole}
                                    onChange={e => setEditRole(e.target.value)}
                                    style={{ width: "100%", padding: "10px 12px", borderRadius: "10px", border: "1px solid var(--border)" }}
                                >
                                    <option value="PRIVAT">Privat</option>
                                    <option value="FAHRSCHUELER">Fahrschüler</option>
                                    <option value="BERUFSFAHRER">Berufsfahrer</option>
                                </select>
                            </label>

                            {/* Speichern-Fehler direkt unter den Feldern */}
                            {saveError && (
                                <p className="error-text" style={{ fontSize: "0.875rem", margin: 0 }}>{saveError}</p>
                            )}

                            <div style={{ display: "flex", gap: "0.75rem", alignItems: "center" }}>
                                <Button label={saving ? "Speichert..." : "Speichern"} loading={saving} type="button" onClick={handleSave} icon={<Check size={18} />} />
                                <Button label="Abbrechen" className="secondary" type="button" onClick={() => { setIsEditing(false); setSaveError(null); }} icon={<X size={18} />} />
                            </div>
                        </>
                    ) : (
                        <>
                            <InfoRow label="Profilname" value={profile?.name || "Nicht verfügbar"}/>
                            <InfoRow label="Rolle" value={roleLabel(profile?.role)}/>
                        </>
                    )}
                </div>
            </div>

            <div style={{ display: "flex", gap: "1rem", flexWrap: "wrap" }}>
                <Button label="Benutzer wechseln" type="button" onClick={handleSwitch} icon={<ArrowLeftRight size={18} />} />
                <Button label={isEditing ? "Bearbeitung abbrechen" : "Profil bearbeiten"} type="button" onClick={() => { setIsEditing(prev => !prev); setSaveError(null); }} icon={<Edit2 size={18} />} />
                <Button label="Profil löschen" type="button" onClick={() => setConfirmDelete(true)} icon={<Trash2 size={18} />} />
            </div>

            <ConfirmationDialog
                open={confirmDelete}
                title="Profil löschen"
                message="Möchtest du dieses Profil wirklich löschen?"
                confirmLabel="Ja, löschen"
                cancelLabel="Abbrechen"
                onConfirm={handleDelete}
                onCancel={() => setConfirmDelete(false)}
            />
        </div>
    );
}
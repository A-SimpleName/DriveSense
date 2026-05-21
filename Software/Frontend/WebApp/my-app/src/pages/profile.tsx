import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { Button } from "../components/button";
import { ConfirmationDialog } from "../components/ConfirmationDialog";
import { useAuth } from "../context/authContext";
import { updateProfile, deleteProfile } from "../services/profileService";

export default function ProfilePage() {
    const navigate = useNavigate();
    const { profile, account, setProfile, setProfileSelected, switchProfile } = useAuth();

    const [isEditing, setIsEditing] = useState(false);
    const [editName, setEditName] = useState(profile?.name || "");
    const [editRole, setEditRole] = useState(profile?.role || "");
    const [confirmDelete, setConfirmDelete] = useState(false);
    const [saving, setSaving] = useState(false);

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
        try {
            const updated = await updateProfile(profile.id, {
                name: editName,
                role: editRole,
            });
            setProfile(updated);
            setIsEditing(false);
        } catch (error) {
            console.error("Profile update failed", error);
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async () => {
        if (!profile?.id) return;
        try {
            await deleteProfile(profile.id);
            setProfile(null);
            setProfileSelected(false);
            navigate("/");
        } catch (error) {
            console.error("Profile deletion failed", error);
        }
    };

    return (
        <div>
            <h1>Mein Profil</h1>

            <div style={{ marginBottom: '2rem' }}>
                <h2>Profil-Informationen</h2>
                <div style={{ display: 'grid', gap: '0.75rem', maxWidth: '420px' }}>
                    {isEditing ? (
                        <>
                            <label style={{ display: 'grid', gap: '0.4rem' }}>
                                <span style={{ fontWeight: 700 }}>Profilname</span>
                                <input
                                    value={editName}
                                    onChange={e => setEditName(e.target.value)}
                                    style={{ width: '100%', padding: '10px 12px', borderRadius: '10px', border: '1px solid var(--border)' }}
                                />
                            </label>
                            <label style={{ display: 'grid', gap: '0.4rem' }}>
                                <span style={{ fontWeight: 700 }}>Rolle</span>
                                <select
                                    value={editRole}
                                    onChange={e => setEditRole(e.target.value)}
                                    style={{ width: '100%', padding: '10px 12px', borderRadius: '10px', border: '1px solid var(--border)' }}
                                >
                                    <option value="PRIVAT">PRIVAT</option>
                                    <option value="FAHRSCHÜLER">FAHRSCHÜLER</option>
                                    <option value="BERUFSFAHRER">BERUFSFAHRER</option>
                                </select>
                            </label>
                            <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
                                <Button label="Speichern" type="button" onClick={handleSave} />
                                <Button label="Abbrechen" className="secondary" type="button" onClick={() => setIsEditing(false)} />
                            </div>
                        </>
                    ) : (
                        <>
                            <p><strong>Profilname:</strong> {profile?.name || 'Nicht verfügbar'}</p>
                            <p><strong>Rolle:</strong> {profile?.role || 'Nicht verfügbar'}</p>
                        </>
                    )}
                </div>
            </div>

            <div style={{ marginBottom: '2rem' }}>
                <h2>Konto-Informationen</h2>
                <div style={{ display: 'grid', gap: '0.5rem', maxWidth: '400px' }}>
                    <p><strong>Vorname:</strong> {account?.fName || 'Nicht verfügbar'}</p>
                    <p><strong>Nachname:</strong> {account?.lName || 'Nicht verfügbar'}</p>
                    <p><strong>E-Mail:</strong> {account?.email || 'Nicht verfügbar'}</p>
                </div>
            </div>

            <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
                <Button label="Benutzer wechseln" type="button" onClick={handleSwitch} />
                <Button label={isEditing ? "Bearbeitung abbrechen" : "Profil bearbeiten"} type="button" onClick={() => setIsEditing(prev => !prev)} />
                <Button label="Profil löschen" type="button" onClick={() => setConfirmDelete(true)} />
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
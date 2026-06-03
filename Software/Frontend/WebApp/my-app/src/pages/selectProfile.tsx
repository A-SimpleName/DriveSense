import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "../components/button";
import { useAuth } from "../context/authContext";
import type { Profile } from "../model/profile";
import { logout, selectProfile } from "../services/auth";
import { createProfile } from "../services/profileService";
import "../styles/selectProfile.css";

export default function SelectProfilePage({
    profiles,
    setProfiles,
    onSelect
}: {
    profiles: Profile[];
    setProfiles: React.Dispatch<React.SetStateAction<Profile[]>>;
    onSelect: () => void;
}) {
    const navigate = useNavigate();
    const { setProfile, setIsAuth, setProfileSelected } = useAuth();
    const [newName, setNewName] = useState("");
    const [newRole, setNewRole] = useState("PRIVAT");
    const [createError, setCreateError] = useState<string | null>(null);
    const [logoutError, setLogoutError] = useState<string | null>(null);
    const [selectError, setSelectError] = useState<string | null>(null);
    const [creating, setCreating] = useState(false);

    const ROLE_OPTIONS = ["PRIVAT", "FAHRSCHÜLER", "BERUFSFAHRER"];

    const handleSelect = async (id: number) => {
        setSelectError(null);
        try {
            const selectedProfile = profiles.find(p => p.id === id);
            if (!selectedProfile) throw new Error("Profil nicht gefunden");
            setProfile(selectedProfile);
            await selectProfile(id);
            setProfileSelected(true);
            onSelect();
            navigate("/");
        } catch (err: any) {
            setSelectError(err?.message || "Profil konnte nicht ausgewählt werden");
        }
    };

    const handleCreate = async () => {
        if (!newName.trim()) {
            setCreateError("Bitte einen Profilnamen eingeben");
            return;
        }

        setCreating(true);
        setCreateError(null);

        try {
            const profile = await createProfile({ name: newName, role: newRole });
            setProfiles([...profiles, profile]);
            setProfile(profile);
            await selectProfile(profile.id!);
            setProfileSelected(true);
            onSelect();
            navigate("/");
        } catch (err: any) {
            setCreateError(err?.message || "Profil konnte nicht erstellt werden");
        } finally {
            setCreating(false);
        }
    };

    const handleLogout = async () => {
        setLogoutError(null);
        try {
            await logout();
            setIsAuth(false);
            setProfileSelected(false);
            navigate("/login");
        } catch (err: any) {
            setLogoutError(err?.message || "Logout fehlgeschlagen");
        }
    };

    return (
        <div className="selectProfile-page">
            <div className="selectProfile-hero">
                <div>
                    <span className="selectProfile-label">Willkommen zurück</span>
                    <h2>Wähle dein Profil</h2>
                    <p>Wähle ein Profil für deine Fahrt, oder erstelle ein neues.</p>
                </div>
                <div className="selectProfile-heroActions">
                    <Button className="secondary" label="Logout" type="button" onClick={handleLogout} />
                </div>
            </div>

            {logoutError && <p style={{ color: "#dc2626" }}>{logoutError}</p>}
            {selectError && <p style={{ color: "#dc2626" }}>{selectError}</p>}

            <section className="selectProfile-section">
                <h3>Bestehende Profile</h3>
                {profiles.length > 0 ? (
                    <div className="selectProfile-grid">
                        {profiles.map(p => (
                            <button key={p.id} className="selectProfile-card" onClick={() => handleSelect(p.id!)}>
                                <div className="selectProfile-cardContent">
                                    <span className="selectProfile-name">{p.name}</span>
                                    <span className="selectProfile-role">{p.role}</span>
                                </div>
                            </button>
                        ))}
                    </div>
                ) : (
                    <p className="selectProfile-empty">Noch keine Profile vorhanden. Erstelle jetzt dein erstes Profil.</p>
                )}
            </section>

            <section className="selectProfile-section selectProfile-formSection">
                <h3>Neues Profil erstellen</h3>
                <div className="selectProfile-form">
                    <input
                        placeholder="Profilname"
                        value={newName}
                        onChange={e => { setNewName(e.target.value); setCreateError(null); }}
                        style={{ borderColor: createError ? "#dc2626" : undefined }}
                    />
                    <select value={newRole} onChange={e => setNewRole(e.target.value)}>
                        {ROLE_OPTIONS.map(r => <option key={r} value={r}>{r}</option>)}
                    </select>

                    {createError && (
                        <p style={{ color: "#dc2626", fontSize: "0.875rem", margin: 0 }}>{createError}</p>
                    )}

                    <button className="selectProfile-btn" onClick={handleCreate} disabled={creating}>
                        {creating ? "Wird erstellt..." : "Profil erstellen"}
                    </button>
                </div>
            </section>
        </div>
    );
}

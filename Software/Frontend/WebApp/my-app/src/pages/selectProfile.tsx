import { useNavigate } from "react-router-dom";
import { createProfile } from "../services/profileService";
import type { Profile } from "../model/profile";
import { logout, selectProfile } from "../services/auth";
import { Button } from "../components/button";
import { useAuth } from "../context/authContext";
import { useState } from "react";
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
    const { setProfile, setIsAuth, setProfileSelected} = useAuth();
    const [newName, setNewName] = useState("");
    const [newRole, setNewRole] = useState("PRIVAT");
    const ROLE_OPTIONS = ["PRIVAT", "FAHRSCHÜLER", "BERUFSFAHRER"];

    const handleSelect = async (id: number) => {
        const selectedProfile = profiles.find(p => p.id === id);
        if (selectedProfile) {
            setProfile(selectedProfile);
        }
        await selectProfile(id);

        const selected = profiles.find(p => p.id === id);
        
        setProfile(selected);

        setProfileSelected(true);

        onSelect();
        navigate("/");
    };

    const handleCreate = async () => {
        if (!newName) return;

        const profile = await createProfile({
            name: newName,
            role: newRole
        });

        setProfiles([...profiles, profile]);

        setProfile(profile);
        await selectProfile(profile.id!);

        setProfile(profile);
        setProfileSelected(true);

        onSelect();
        navigate("/");
    };

    const handleLogout = async () => {
        try {
            await logout();
            setIsAuth(false);
            navigate("/login");
        } catch (error) {
            console.error("Logout failed:", error);
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

            <section className="selectProfile-section">
                <h3>Bestehende Profile</h3>
                {profiles.length > 0 ? (
                    <div className="selectProfile-grid">
                        {profiles.map(p => (
                            <button
                                key={p.id}
                                className="selectProfile-card"
                                onClick={() => handleSelect(p.id!)}
                            >
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
                        onChange={e => setNewName(e.target.value)}
                    />
                    <select value={newRole} onChange={e => setNewRole(e.target.value)}>
                        {ROLE_OPTIONS.map(r => (
                            <option key={r} value={r}>{r}</option>
                        ))}
                    </select>
                    <button className="selectProfile-btn" onClick={handleCreate}>
                        Profil erstellen
                    </button>
                </div>
            </section>
        </div>
    );
}

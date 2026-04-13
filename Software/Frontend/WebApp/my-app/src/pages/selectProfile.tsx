import { useEffect, useState } from "react";
import "./SelectProfile.css";
import type { Profile } from "../model/profile";
import { getAllProfiles, createProfile } from "../services/userService";

const SelectProfile = () => {
    const [profiles, setProfiles] = useState<Profile[]>([]);

    useEffect(() => {
        loadProfiles();
    }, []);

    const loadProfiles = async () => {
        try {
            const data = await getAllProfiles();
            setProfiles(data);
        } catch (err) {
            console.error("Fehler beim Laden:", err);
        }
    };

    const handleSelect = (profile: Profile) => {
        localStorage.setItem("selectedProfile", JSON.stringify(profile));
        window.location.href = "/dashboard";
    };

    const handleAdd = async () => {
        const name = prompt("Name:");
        if (!name) return;

        const role = prompt("Rolle (Privat/Beruflich/Fahrlehrer):") || "Privat";

        const newProfile = {
            name,
            role,
            account_id: 1, // später aus Login
            group_id: 1
        };

        try {
            await createProfile(newProfile);
            loadProfiles(); // neu laden
        } catch (err) {
            console.error("Fehler beim Erstellen:", err);
        }
    };

    return (
        <div className="container">
            <h1>Wer fährt heute?</h1>

            <div className="profile-grid">
                {profiles.map((p) => (
                    <div key={p.id} className="profile-card" onClick={() => handleSelect(p)}>
                        <div className="avatar">🚗</div>
                        <div className="name">{p.name}</div>
                        <div className="type">{p.role}</div>
                    </div>
                ))}

                <div className="profile-card add" onClick={handleAdd}>
                    <div className="avatar">➕</div>
                    <div className="name">Profil hinzufügen</div>
                </div>
            </div>
        </div>
    );
};

export default SelectProfile;
import { useNavigate } from "react-router-dom";
import { createProfile } from "../services/profileService";
import type { Profile } from "../model/profile";
import { selectProfile } from "../services/auth";
import { useState } from "react";

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
    const [newName, setNewName] = useState("");
    const [newRole, setNewRole] = useState("PRIVAT");

    const ROLE_OPTIONS = ["PRIVAT", "FAHRSCHÜLER", "BERUFSFAHRER"];

    const handleSelect = async (id: number) => {
        await selectProfile(id);
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

        await selectProfile(profile.id!);

        onSelect();
        navigate("/");
    };

    return (
        <div>
            <h2>Profile auswählen</h2>

            {profiles.length > 0 ? (
                profiles.map(p => (
                    <button key={p.id} onClick={() => handleSelect(p.id!)}>
                        {p.name} ({p.role})
                    </button>
                ))
            ) : (
                <p>Keine Profile vorhanden → bitte erstellen</p>
            )}

            <h3>Neues Profil</h3>

            <input
                placeholder="Name"
                value={newName}
                onChange={e => setNewName(e.target.value)}
            />

            <select value={newRole} onChange={e => setNewRole(e.target.value)}>
                {ROLE_OPTIONS.map(r => (
                    <option key={r}>{r}</option>
                ))}
            </select>

            <button onClick={handleCreate}>
                Profil erstellen
            </button>
        </div>
    );
}

import { useNavigate } from "react-router-dom";
import { Button } from "../components/button";
import { useAuth } from "../context/authContext";
import { useState, useEffect } from "react";
import { updateProfile } from "../services/profileService";

export default function ProfilePage() {
    const navigate = useNavigate();
    const { profile, switchProfile, setProfile } = useAuth();

    const [showProfileEditor, setShowProfileEditor] = useState(false);
    const [newName, setNewName] = useState("");

    useEffect(() => {
        setNewName(profile?.name || "");
    }, [profile]);

    const handleSwitch = async () => {
        await switchProfile();
        navigate("/");
    };

    const handleUpdate = async () => {
        if (!profile) return;

        try {
            const updated = await updateProfile(profile.id, {
                name: newName,
                role: profile.role
            });

            setProfile(updated); // Context updaten → UI updated automatisch
            setShowProfileEditor(false);
        } catch (err) {
            console.error("Update failed:", err);
        }
    };

    const isChanged = newName !== profile?.name;

    return (
        <div>
            <h1>Mein Profil</h1>

            <h2>Profil</h2>
            <p>Eingeloggtes Profil: {profile?.name}</p>

            {showProfileEditor && (
                <div style={{ marginTop: "10px" }}>
                    <input
                        value={newName}
                        onChange={(e) => setNewName(e.target.value)}
                        placeholder="Neuer Name"
                    />

                    <div style={{ marginTop: "10px" }}>
                        <Button
                            label="Speichern"
                            onClick={handleUpdate}
                            disabled={!isChanged}
                        />
                        <Button
                            label="Abbrechen"
                            onClick={() => setShowProfileEditor(false)}
                        />
                    </div>
                </div>
            )}

            <div style={{ marginTop: "20px" }}>
                <Button
                    label="Benutzer wechseln"
                    type="button"
                    onClick={handleSwitch}
                />

                <Button
                    label="Profil bearbeiten"
                    type="button"
                    onClick={() => setShowProfileEditor(true)}
                />

                <Button
                    label="Profil löschen"
                    type="button"
                    // später implementieren
                />
            </div>
        </div>
    );
}
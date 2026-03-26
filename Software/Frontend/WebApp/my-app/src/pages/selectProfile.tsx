import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { getProfilesByAccount, createProfile } from "../services/profileService";
import { selectProfile } from "../services/auth";
import type { Profile } from "../model/profile";

export default function SelectProfilePage({ onSelect }: any) {
  const navigate = useNavigate();
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [loading, setLoading] = useState(true);
  const [newName, setNewName] = useState("");
  const [newRole, setNewRole] = useState("PRIVAT");

  const ROLE_OPTIONS = ["PRIVAT", "FAHRSCHÜLER", "BERUFSFAHRER"];  
  
  useEffect(() => {
    async function fetchProfiles() {
      try {
        const data = await getProfilesByAccount();
        setProfiles(data);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    }
    fetchProfiles();
  }, []);

  const handleSelect = async (profileId: number) => {
    await selectProfile(profileId);
    onSelect();
    navigate("/");
  };

  const handleCreate = async () => {
  if (!newName || !newRole) return;

  try {
    const profileData: Omit<Profile, "id" | "account_id"> = {
      name: newName,
      role: newRole,
      group_id: undefined
    };

    const profile = await createProfile(profileData);

    setProfiles([...profiles, profile]);
    setNewName("");
    setNewRole("PRIVAT");
  } catch (err) {
    console.error(err);
  }
};

  if (loading) return <p>Lade Profile...</p>;

  return (
    <div>
      {profiles.length > 0 ? (
        profiles.map((p) => (
          <button key={p.id} onClick={() => handleSelect(p.id!)}>
            {p.name} ({p.role})
          </button>
        ))
      ) : (
        <p>Keine Profile vorhanden. Bitte erstelle ein neues.</p>
      )}

      <div style={{ marginTop: "1rem" }}>
        <h3>Neues Profil erstellen</h3>
        <input
          placeholder="Name"
          value={newName}
          onChange={(e) => setNewName(e.target.value)}
        />
        <select value={newRole} onChange={(e) => setNewRole(e.target.value)}>
          {ROLE_OPTIONS.map((role) => (
            <option key={role} value={role}>
              {role.charAt(0) + role.slice(1).toLowerCase()}
            </option>
          ))}
        </select>
        <button onClick={handleCreate}>Profil erstellen</button>
      </div>
    </div>
  );
}
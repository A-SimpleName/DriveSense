import { useNavigate } from "react-router";
import { Button } from "../components/button";
import { useAuth } from "../context/authContext";

export default function ProfilePage() {
    const navigate = useNavigate();
    const { profile, switchProfile } = useAuth();

    const handleSwitch = async () => {
        await switchProfile();
        navigate("/");
    };

    return (
        <div>
            <h1>Mein Profil</h1>
            <h2>Profil</h2>
            <p>Eingeloggtes Profil: {profile?.name}</p>
            {/* weiß ned ob relevant hier*/}
            <Button label="Benutzer wechseln" type="button" onClick={handleSwitch} />
            <Button label="Profil bearbeiten" type="button" /*onClick={() => navigate("/edit-profile")}*/ />
            <Button label="Profil löschen" type="button" /*onClick={() => navigate("/delete-profile")}*/ />
        </div>
    );
}
import { useNavigate } from "react-router-dom";
import { logoutProfile } from "../services/auth";
import { getCurrentProfile } from "../services/profileService";
import type { Profile } from "../model/profile";
import { useEffect, useState } from "react";

export default function Settings({ onSwitchProfile }: { onSwitchProfile: () => void }) {
    const navigate = useNavigate();
    const [currentUser,setCurrentUser] = useState<Profile | null>(null);    

    useEffect(() => {
        const fetchProfile = async () => {
            const profile = await getCurrentProfile();
            setCurrentUser(profile);
        };
        fetchProfile();
    }, []);

    const handleSwitch = async () => {
        await logoutProfile();
        onSwitchProfile();   
        navigate("/");      
    };


    return (
        <>
         <h1>Einstellungen</h1>
            <span>Eingeloggtes Profil: {currentUser?.name}</span>
            <div>  
                <button onClick={handleSwitch}>Benutzer wechseln</button>
            </div>
            <div>
                <button>Passwort ändern</button>
            </div>
        </>
    );
}
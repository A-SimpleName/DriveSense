import { useState } from "react";
import { logout, logoutProfile } from "../services/auth";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/authContext";
import { Button } from "./button";

import "../styles/usermeu.css";

function UserMenu() {
    const [open, setOpen] = useState(false);
    const navigate = useNavigate();

    const {
        account,
        setAccount,
        setIsAuth,
        setProfile,
        setProfileSelected
    } = useAuth();

    const initials =
        account?.fname?.[0]?.toUpperCase() +
        account?.lname?.[0]?.toUpperCase();

    const handleSwitch = async () => {
        await logoutProfile();
        setProfile(null);
        setProfileSelected(false);
        navigate("/");
    };

    return (
        <div className="user-menu">
            <div
                className="avatar"
                onClick={() => setOpen(!open)}
            >
                {initials || "?"}
            </div>

            {open && (
                <div className="dropdown">

                    <div className="user-info">
                        <div>{account?.fname} {account?.lname}</div>
                        <div>{account?.email}</div>
                    </div>

                    <Button className="userMenu-btn" label="Mein Profil" onClick={() => navigate("/profile")} />
                    <Button className="userMenu-btn" label="Einstellungen" onClick={() => navigate("/settings")} />
          
                    <Button className="userMenu-btn" label="Logout" onClick={async () => {
                            await logout();
                            setAccount(null);
                            setProfile(null);
                            setProfileSelected(false);
                            setIsAuth(false);
                        }} />

                    <Button className="userMenu-btn" label="Benutzer wechseln" onClick={handleSwitch} />
                </div>
            )}
        </div>
    );
}

export default UserMenu;
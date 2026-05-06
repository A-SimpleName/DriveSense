import { useState, useRef, useEffect } from "react";
import { logout, logoutProfile } from "../services/auth";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/authContext";
import { Button } from "./button";

import "../styles/usermeu.css";

function UserMenu() {
    const [open, setOpen] = useState(false);
    const menuRef = useRef<HTMLDivElement>(null);
    const navigate = useNavigate();

    const {
        account,
        setAccount,
        setIsAuth,
        setProfile,
        setProfileSelected
    } = useAuth();

    const initials =
        account?.fName?.[0]?.toUpperCase() +
        account?.lName?.[0]?.toUpperCase();

    const handleSwitch = async () => {
        await logoutProfile();
        setProfile(null);
        setProfileSelected(false);
        navigate("/");
    };

    // Schließe das Dropdown wenn außerhalb geklickt wird
    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
                setOpen(false);
            }
        };

        if (open) {
            document.addEventListener("click", handleClickOutside);
        }

        return () => {
            document.removeEventListener("click", handleClickOutside);
        };
    }, [open]);

    return (
        <div className="user-menu" ref={menuRef}>
            <div
                className="avatar"
                onClick={() => setOpen(!open)}
            >
                {initials || "?"}
            </div>

            {open && (
                <div className="dropdown">

                    <div className="user-info">
                        <div>{account?.fName} {account?.lName}</div>
                        <div>{account?.email}</div>
                    </div>

                    <Button className="userMenu-btn" label="Mein Profil" onClick={() => { navigate("/profile"); setOpen(false); }} />
                    <Button className="userMenu-btn" label="Einstellungen" onClick={() => { navigate("/settings"); setOpen(false); }} />
          
                    <Button className="userMenu-btn" label="Logout" onClick={async () => {
                            await logout();
                            setAccount(null);
                            setProfile(null);
                            setProfileSelected(false);
                            setIsAuth(false);
                            setOpen(false);
                        }} />

                    <Button className="userMenu-btn" label="Benutzer wechseln" onClick={() => { handleSwitch(); setOpen(false); }} />
                </div>
            )}
        </div>
    );
}

export default UserMenu;
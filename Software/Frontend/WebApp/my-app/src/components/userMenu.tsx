import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/authContext";
import { logout, logoutProfile } from "../services/auth";
import { Button } from "./button";
import { ConfirmationDialog } from "./ConfirmationDialog";

import "../styles/usermenu.css";

function UserMenu() {
    const [open, setOpen] = useState(false);
    const [confirmLogout, setConfirmLogout] = useState(false);
    const menuRef = useRef<HTMLDivElement>(null);
    const navigate = useNavigate();

    const {
        account,
        profile,
        setAccount,
        setIsAuth,
        setProfile,
        setProfileSelected
    } = useAuth();

    const handleSwitch = async () => {
        await logoutProfile();
        setProfile(null);
        setProfileSelected(false);
        navigate("/");
    };

    const handleConfirmLogout = async () => {
        await logout();
        setAccount(null);
        setProfile(null);
        setProfileSelected(false);
        setIsAuth(false);
        setOpen(false);
        setConfirmLogout(false);
    };

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

    const profileInitial = profile?.name?.[0]?.toUpperCase() || account?.firstName?.[0]?.toUpperCase() || "?";

    return (
        <div className="user-menu" ref={menuRef}>
            <div
                className="avatar"
                onClick={() => setOpen(!open)}
            >
                {profileInitial}
            </div>

            {open && (
                <div className="dropdown">
                    <div className="user-info">
                        <div>{account?.firstName} {account?.lastName}</div>
                        <div>{account?.email}</div>
                    </div>

                    <Button className="userMenu-btn" label="Mein Profil" onClick={() => navigate("/profile")} />
                    <Button className="userMenu-btn" label="Einstellungen" onClick={() => navigate("/settings")} />
                    <Button className="userMenu-btn" label="Logout" onClick={() => setConfirmLogout(true)} />
                    <Button className="userMenu-btn" label="Benutzer wechseln" onClick={handleSwitch} />
                </div>
            )}

            <ConfirmationDialog
                open={confirmLogout}
                title="Logout bestätigen"
                message="Möchtest du dich wirklich abmelden?"
                confirmLabel="Ja, abmelden"
                cancelLabel="Abbrechen"
                onConfirm={handleConfirmLogout}
                onCancel={() => setConfirmLogout(false)}
            />
        </div>
    );
}

export default UserMenu;

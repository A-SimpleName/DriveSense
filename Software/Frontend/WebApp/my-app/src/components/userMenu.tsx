import { useState } from "react";
import { logout, logoutProfile } from "../services/auth";
import { useNavigate } from "react-router-dom";
import "../styles/usermeu.css";

type UserMenuProps = {
    setAccount: React.Dispatch<React.SetStateAction<any>>;
    account: any;
    onProfileSelect: () => void;
    setIsAuth: React.Dispatch<React.SetStateAction<boolean>>;
};

function UserMenu({ setAccount, account, onProfileSelect, setIsAuth }: UserMenuProps) {
    const [open, setOpen] = useState(false);
    const navigate = useNavigate();
    
    const initials =
        account?.fname?.[0]?.toUpperCase() + account?.lname?.[0]?.toUpperCase();

    const handleSwitch = async () => {
        await logoutProfile();  
        onProfileSelect();
        navigate("/");      
    };

    return (
        // man kan irgendiwe kein button in table deswegen vllt keinen oder nur teilweise oder ein link tag
        <div className="user-menu">
            {/* Avatar */}
            <div
                className="avatar"
                onClick={() => setOpen(!open)}
            >
                {initials || "?"}
            </div>

            {/* Dropdown */}
            {open && (
                <div className="dropdown">
                    <table>
                        <tbody>
                            <tr>
                                <td>{account?.fname} {account?.lname}</td>
                            </tr>
                            <tr>
                                <td>{account?.email}</td>
                            </tr>
                        </tbody>
                    </table>
                    <div className="user-info">
                        <div>{account?.fname} {account?.lname}</div>
                        <div>{account?.email}</div>
                    </div>

                    <button onClick={() => navigate("/profile")}>
                        Mein Profil
                    </button>

                    <button onClick={() => navigate("/settings")}>
                        Einstellungen
                    </button>

                    <button
                        onClick={async () => {
                            await logout();
                            setAccount(null);
                            setIsAuth(false);
                            navigate("/login");
                        }}
                    >
                        Logout
                    </button>
                    <button onClick={handleSwitch}>Benutzer wechseln</button>
                </div>
            )}
        </div>
    );
}

export default UserMenu;
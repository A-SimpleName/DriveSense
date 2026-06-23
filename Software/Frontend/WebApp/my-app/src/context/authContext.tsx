import { createContext, useContext, useState } from "react";
import { logoutProfile } from "../services/auth";

type AuthContextType = {
    isAuth: boolean;
    setIsAuth: (v: boolean) => void;

    account: any;
    setAccount: (a: any) => void;

    profile: any;
    setProfile: (p: any) => void;

    profileSelected: boolean;
    setProfileSelected: (v: boolean) => void;

    switchProfile: () => Promise<void>;
};

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
    const [isAuth, setIsAuth] = useState(false);
    const [account, setAccount] = useState<any>(null);
    const [profile, setProfile] = useState<any>(null);
    const [profileSelected, setProfileSelected] = useState(false);

    const switchProfile = async () => {
        await logoutProfile();
        setProfileSelected(false);
    };

    return (
        <AuthContext.Provider value={{
            isAuth,
            setIsAuth,
            account,
            setAccount,
            profile,
            setProfile,
            profileSelected,
            setProfileSelected,
            switchProfile
        }}>
            {children}
        </AuthContext.Provider>
    );
}

export function useAuth() {
    const ctx = useContext(AuthContext);
    if (!ctx) throw new Error("useAuth must be used inside AuthProvider");
    return ctx;
}
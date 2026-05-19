import { useState } from "react";
import { Link } from "react-router-dom";
import { login } from "../services/auth";
import { Button } from "../components/button";

interface Props {
    onLoginSuccess: () => void;
    onNeedsVerification: () => void;
}

export default function LoginPage({ onLoginSuccess, onNeedsVerification }: Props) {
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [error, setError] = useState<string | null>(null);
    const [show, setShow] = useState(false);

    const handleLogin = async () => {
        setError(null);
        try {
            await login(email, password);
            sessionStorage.removeItem("profileSelected");
            onLoginSuccess();
        } catch (err: any) {
            if (err?.status === 403 || err?.message?.includes("403")) {
                // Email nicht verifiziert
                sessionStorage.setItem("pendingVerificationEmail", email);
                onNeedsVerification();
            } else {
                setError("Login fehlgeschlagen");
            }
        }
    };

    return (
        <div>
            <h1>Login</h1>
            <input
                type="email"
                placeholder="Email"
                value={email}
                onChange={e => setEmail(e.target.value)}
            />
            <input
                type={show ? "text" : "password"}
                placeholder="Passwort"
                value={password}
                onChange={e => setPassword(e.target.value)}
            />
            <Button
                label={show ? "Verbergen" : "Anzeigen"}
                type="button"
                onClick={() => setShow(prev => !prev)}
            />
            {error && <p style={{ color: "red" }}>{error}</p>}
            <button onClick={handleLogin}>Login</button>
            <br />
            <Link to="/forgot-password">Passwort vergessen?</Link>
            <br />
            <p>Noch keinen Account? <Link to="/signUp">Registrieren</Link></p>
        </div>
    );
}
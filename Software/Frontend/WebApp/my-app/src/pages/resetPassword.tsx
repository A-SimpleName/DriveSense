import { useState } from "react";
import { resetPassword } from "../services/auth";
import { useNavigate, useLocation } from "react-router-dom";
import { Link } from "react-router-dom";
import { Button } from "../components/button";

export default function ResetPasswordPage() {
    const navigate = useNavigate();
    const location = useLocation();
    const prefillEmail = location.state?.email ?? "";

    const [email, setEmail] = useState(prefillEmail);
    const [code, setCode] = useState("");
    const [newPassword, setNewPassword] = useState("");
    const [error, setError] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);
    const [show, setShow] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!email.trim() || !code.trim() || !newPassword.trim()) return;
        setLoading(true);
        setError(null);
        try {
            await resetPassword(email.trim(), code.trim(), newPassword);
            navigate("/login");
        } catch (err: any) {
            setError(err?.message || "Fehler beim Zurücksetzen");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div>
            <h1>Neues Passwort setzen</h1>
            <form onSubmit={handleSubmit}>
                <input
                    type="email"
                    placeholder="Email"
                    value={email}
                    onChange={e => setEmail(e.target.value)}
                />
                <input
                    type="text"
                    placeholder="6-stelliger Code"
                    value={code}
                    onChange={e => setCode(e.target.value)}
                    maxLength={6}
                />
                <input
                    type={show ? "text" : "password"}
                    placeholder="Neues Passwort"
                    value={newPassword}
                    onChange={e => setNewPassword(e.target.value)}
                />
                <Button
                    label={show ? "Verbergen" : "Anzeigen"}
                    type="button"
                    onClick={() => setShow(prev => !prev)}
                />
                {error && <p style={{ color: "red" }}>{error}</p>}
                <button type="submit" disabled={loading}>
                    {loading ? "Wird gespeichert..." : "Passwort setzen"}
                </button>
            </form>
            <Link to="/login">Zurück zum Login</Link>
        </div>
    );
}
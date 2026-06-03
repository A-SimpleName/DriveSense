import { useState } from "react";
import { forgotPassword } from "../services/auth";
import { useNavigate } from "react-router-dom";
import { Link } from "react-router-dom";

export default function ForgotPasswordPage() {
    const [email, setEmail] = useState("");
    const [sent, setSent] = useState(false);
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!email.trim()) return;
        setLoading(true);
        try {
            await forgotPassword(email.trim());
            setSent(true);
        } catch {
            // immer success zeigen egal ob Email existiert
            setSent(true);
        } finally {
            setLoading(false);
        }
    };

    if (sent) {
        return (
            <div>
                <h1>Code gesendet</h1>
                <p>Falls ein Account mit dieser Email existiert, wurde ein Code gesendet.</p>
                <button onClick={() => navigate("/reset-password", { state: { email } })}>
                    Weiter zum Code eingeben
                </button>
            </div>
        );
    }

    return (
        <div>
            <h1>Passwort vergessen</h1>
            <form onSubmit={handleSubmit}>
                <input
                    type="email"
                    placeholder="Email"
                    value={email}
                    onChange={e => setEmail(e.target.value)}
                    autoFocus
                />
                <button type="submit" disabled={loading}>
                    {loading ? "Wird gesendet..." : "Code senden"}
                </button>
            </form>
            <Link to="/login">Zurück zum Login</Link>
        </div>
    );
}
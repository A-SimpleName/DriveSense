import { useState } from "react";
import { forgotPassword } from "../services/auth";
import { useNavigate } from "react-router-dom";
import { Link } from "react-router-dom";
import "../styles/forgotPassword.css";

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
            setSent(true);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="forgot-password-page">
            <div className="forgot-password-card">
                <div className="forgot-password-hero">
                    <div className="forgot-password-kicker">Drive Sense</div>
                    <h1 className="forgot-password-heading">Passwort zurücksetzen</h1>
                    <p className="forgot-password-copy">
                        Gib deine E-Mail-Adresse ein. Falls ein Konto existiert, senden wir dir einen Verifizierungs-Code zum Zurücksetzen deines Passworts.
                    </p>
                    <ul className="forgot-password-bullets">
                        <li>Sichere Verifizierung per E-Mail-Code</li>
                        <li>Kein zusätzliches Konto-Setup nötig</li>
                        <li>Direkt weiter zum neuen Passwort</li>
                    </ul>
                </div>

                <div className="forgot-password-panel">
                    <div className="forgot-password-panel-header">
                        <p className="forgot-password-panel-kicker">Sicherheit</p>
                        <h2 className="forgot-password-panel-title">Code anfordern</h2>
                        <p className="forgot-password-panel-copy">
                            Trage die E-Mail-Adresse deines Kontos ein, damit wir den Reset-Code senden können.
                        </p>
                    </div>

                    {sent ? (
                        <div className="forgot-password-success">
                            <h3>Code angefordert</h3>
                            <p>
                                Falls ein Konto mit dieser E-Mail existiert, wurde der Code versendet. Du kannst jetzt direkt zur Eingabe des Codes weitergehen.
                            </p>
                            <button
                                className="forgot-password-submit"
                                type="button"
                                onClick={() => navigate("/reset-password", { state: { email } })}
                            >
                                Weiter zum Code eingeben
                            </button>
                        </div>
                    ) : (
                        <form className="forgot-password-form" onSubmit={handleSubmit}>
                            <label className="forgot-password-field">
                                <span className="forgot-password-label">E-Mail</span>
                                <input
                                    className="forgot-password-input"
                                    type="email"
                                    placeholder="max@example.com"
                                    value={email}
                                    onChange={e => setEmail(e.target.value)}
                                    autoFocus
                                />
                            </label>

                            <button className="forgot-password-submit" type="submit" disabled={loading}>
                                {loading ? "Wird gesendet..." : "Code senden"}
                            </button>

                            <div className="forgot-password-footer">
                                <Link to="/login">Zurück zum Login</Link>
                            </div>
                        </form>
                    )}
                </div>
            </div>
        </div>
    );
}
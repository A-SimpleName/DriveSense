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
    const [confirmPassword, setConfirmPassword] = useState("");
    const [error, setError] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);
    const [showConfirmPassword, setShowConfirmPassword] = useState(false);

    const passwordRules = [
        { key: "length", label: "Mindestens 8 Zeichen", met: newPassword.length >= 8 },
        { key: "upper", label: "Ein Großbuchstabe", met: /[A-Z]/.test(newPassword) },
        { key: "lower", label: "Ein Kleinbuchstabe", met: /[a-z]/.test(newPassword) },
        { key: "number", label: "Eine Zahl", met: /\d/.test(newPassword) },
    ];

    const passwordMeetsPolicy = passwordRules.every((rule) => rule.met);
    const passwordMismatch = confirmPassword.length > 0 && newPassword !== confirmPassword;
    const submitDisabled = !email.trim() || !code.trim() || !newPassword || !confirmPassword || !passwordMeetsPolicy || passwordMismatch || loading;
    const [show, setShow] = useState(false);
    const [repeatPassword, setRepeatPassword] = useState("");

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!passwordMeetsPolicy) {
            setError("Das Passwort erfüllt die Anforderungen nicht.");
            return;
        }

        if (newPassword !== confirmPassword) {
            setError("Die Passwörter stimmen nicht überein.");
            return;
        }

        setLoading(true);
        setError(null);
        try {
            await resetPassword(
                email.trim(),
                code.trim(),
                newPassword
            );

            navigate("/login");
        } catch (err: any) {
            setError(err?.message || "Fehler beim Zurücksetzen");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="reset-password-page">
            <div className="reset-password-card">
                <div className="reset-password-hero">
                    <div className="reset-password-kicker">Drive Sense</div>
                    <h1 className="reset-password-heading">Neues Passwort setzen</h1>
                    <p className="reset-password-copy">
                        Prüfe den Code aus der Mail und sichere dein Konto mit einem starken neuen Passwort.
                    </p>
                    <ul className="reset-password-bullets">
                        <li>Verifizierungs-Code aus der E-Mail</li>
                        <li>Starkes Passwort mit Sicherheitspolice</li>
                        <li>Schnelle Rückkehr zum Login</li>
                    </ul>
                </div>

                <div className="reset-password-panel">
                    <div className="reset-password-panel-header">
                        <p className="reset-password-panel-kicker">Sicherheit</p>
                        <h2 className="reset-password-panel-title">Code eingeben</h2>
                        <p className="reset-password-panel-copy">
                            Gib die E-Mail, den erhaltenen Code und dein neues Passwort ein.
                        </p>
                    </div>

                    <form className="reset-password-form" onSubmit={handleSubmit}>
                        <label className="reset-password-field">
                            <span className="reset-password-label">E-Mail</span>
                            <input
                                className="reset-password-input"
                                type="email"
                                placeholder="max@example.com"
                                value={email}
                                onChange={e => setEmail(e.target.value)}
                            />
                        </label>

                        <label className="reset-password-field">
                            <span className="reset-password-label">Verifizierungs-Code</span>
                            <input
                                className="reset-password-input"
                                type="text"
                                inputMode="numeric"
                                pattern="[0-9]*"
                                placeholder="6-stelliger Code"
                                value={code}
                                onChange={e => setCode(e.target.value)}
                                maxLength={6}
                                autoFocus
                            />
                        </label>

                        <label className="reset-password-field">
                            <span className="reset-password-label">Neues Passwort</span>
                            <div className="password-input-wrapper">
                                <input
                                    className="reset-password-input reset-password-input-password"
                                    type={showPassword ? "text" : "password"}
                                    placeholder="Neues Passwort"
                                    value={newPassword}
                                    onChange={e => setNewPassword(e.target.value)}
                                />
                                <button
                                    type="button"
                                    className="password-toggle"
                                    onClick={() => setShowPassword(prev => !prev)}
                                    aria-label={showPassword ? "Passwort verbergen" : "Passwort anzeigen"}
                                >
                                    {showPassword ? (
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round">
                                            <path d="M2 12C3.5 16.5 7.5 19.5 12 19.5c4.5 0 8.5-3 10-7.5C20.5 7 16.5 4.5 12 4.5 7.5 4.5 3.5 7 2 12Z" />
                                            <path d="M9.5 9.5a2.5 2.5 0 0 0 5 0" />
                                            <path d="M1 1l22 22" />
                                        </svg>
                                    ) : (
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round">
                                            <path d="M1.42 12.93C2.73 16.47 6.14 19.5 12 19.5c5.86 0 9.27-3.03 10.58-6.57C21.27 8.53 17.86 5.5 12 5.5 6.14 5.5 2.73 8.53 1.42 12.93Z" />
                                            <circle cx="12" cy="12" r="3" />
                                        </svg>
                                    )}
                                </button>
                            </div>
                        </label>

                        <ul className="password-rules">
                            {passwordRules.map((rule) => (
                                <li className={`password-rule ${rule.met ? "is-valid" : ""}`} key={rule.key}>
                                    <span className="password-rule-marker">{rule.met ? "✓" : "•"}</span>
                                    <span>{rule.label}</span>
                                </li>
                            ))}
                        </ul>

                        <label className="reset-password-field">
                            <span className="reset-password-label">Passwort bestätigen</span>
                            <div className="password-input-wrapper">
                                <input
                                    className="reset-password-input reset-password-input-password"
                                    type={showConfirmPassword ? "text" : "password"}
                                    placeholder="Passwort wiederholen"
                                    value={confirmPassword}
                                    onChange={e => setConfirmPassword(e.target.value)}
                                />
                                <button
                                    type="button"
                                    className="password-toggle"
                                    onClick={() => setShowConfirmPassword(prev => !prev)}
                                    aria-label={showConfirmPassword ? "Passwort verbergen" : "Passwort anzeigen"}
                                >
                                    {showConfirmPassword ? (
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round">
                                            <path d="M2 12C3.5 16.5 7.5 19.5 12 19.5c4.5 0 8.5-3 10-7.5C20.5 7 16.5 4.5 12 4.5 7.5 4.5 3.5 7 2 12Z" />
                                            <path d="M9.5 9.5a2.5 2.5 0 0 0 5 0" />
                                            <path d="M1 1l22 22" />
                                        </svg>
                                    ) : (
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round">
                                            <path d="M1.42 12.93C2.73 16.47 6.14 19.5 12 19.5c5.86 0 9.27-3.03 10.58-6.57C21.27 8.53 17.86 5.5 12 5.5 6.14 5.5 2.73 8.53 1.42 12.93Z" />
                                            <circle cx="12" cy="12" r="3" />
                                        </svg>
                                    )}
                                </button>
                            </div>
                        </label>

                        {passwordMismatch && <p className="form-hint error">Die Passwörter stimmen nicht überein.</p>}
                        {error && <p className="form-hint error">{error}</p>}

                        <button className="reset-password-submit" type="submit" disabled={submitDisabled}>
                            {loading ? "Wird gespeichert..." : "Passwort speichern"}
                        </button>

                        <div className="reset-password-footer">
                            <Link to="/login">Zurück zum Login</Link>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
}
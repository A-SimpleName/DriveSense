import { useState } from "react";
import { verifyEmail, resendVerification } from "../services/auth";
import "../styles/verifyEmail.css";

interface Props {
    onVerified: () => void;
}

export default function VerifyEmailPage({ onVerified }: Props) {
    const [code, setCode] = useState("");
    const [error, setError] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);
    const [resendSuccess, setResendSuccess] = useState(false);
    const email = sessionStorage.getItem("pendingVerificationEmail") ?? "";

    const handleVerify = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!code.trim()) return;
        setLoading(true);
        setError(null);
        try {
            await verifyEmail(email, code.trim());
            sessionStorage.removeItem("pendingVerificationEmail");
            onVerified();
        } catch (err: any) {
            setError(err?.message || "Ungültiger Code");
        } finally {
            setLoading(false);
        }
    };

    const handleResend = async () => {
        setError(null);
        setResendSuccess(false);
        try {
            await resendVerification(email);
            setResendSuccess(true);
        } catch (err: any) {
            setError(err?.message || "Fehler beim Senden");
        }
    };

    return (
        <div className="verify-email-page">
            <div className="verify-email-card">
                <div className="verify-email-hero">
                    <div className="verify-email-kicker">Drive Sense</div>
                    <h1 className="verify-email-heading">Fast geschafft</h1>
                    <p className="verify-email-copy">
                        Bestätige deine E-Mail-Adresse mit dem Code aus deiner Mail, um dein Konto zu aktivieren.
                    </p>
                    <ul className="verify-email-bullets">
                        <li>Sichere Verifizierung per E-Mail-Code</li>
                        <li>Code nicht angekommen? Einfach erneut senden</li>
                        <li>Danach direkt einsatzbereit</li>
                    </ul>
                </div>

                <div className="verify-email-panel">
                    <div className="verify-email-panel-header">
                        <p className="verify-email-panel-kicker">Sicherheit</p>
                        <h2 className="verify-email-panel-title">Code eingeben</h2>
                        <p className="verify-email-panel-copy">
                            Wir haben einen Code an <strong>{email}</strong> gesendet. Bitte gib ihn unten ein.
                        </p>
                    </div>

                    <form className="verify-email-form" onSubmit={handleVerify}>
                        <label className="verify-email-field">
                            <span className="verify-email-label">Verifizierungs-Code</span>
                            <input
                                className="verify-email-input"
                                type="text"
                                inputMode="numeric"
                                pattern="[0-9]*"
                                placeholder="——— ———"
                                value={code}
                                onChange={e => setCode(e.target.value)}
                                maxLength={6}
                                autoFocus
                            />
                        </label>

                        {error && <p className="error-text">{error}</p>}
                        {resendSuccess && <p className="verify-email-success">Code wurde erneut gesendet!</p>}

                        <button className="verify-email-submit" type="submit" disabled={loading}>
                            {loading && (
                                <span style={{
                                    display: "inline-block", width: "12px", height: "12px",
                                    border: "2px solid rgba(255,255,255,0.35)", borderTopColor: "currentColor",
                                    borderRadius: "50%", animation: "spin 0.6s linear infinite",
                                    verticalAlign: "middle", marginRight: "6px",
                                }} />
                            )}
                            {loading ? "Wird überprüft..." : "Bestätigen"}
                        </button>

                        <button
                            type="button"
                            className="verify-email-resend"
                            onClick={handleResend}
                            disabled={loading}
                        >
                            Code erneut senden
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
}
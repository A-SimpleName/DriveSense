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
            await verifyEmail(email,code.trim());
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
                <div className="verify-email-header">
                    <span className="verify-email-kicker">Verifizierung</span>
                    <h1 className="verify-email-heading">Email bestätigen</h1>
                    <p className="verify-email-copy">
                        Wir haben einen Bestätigungscode an <strong>{email}</strong> gesendet. Bitte gib ihn hier ein.
                    </p>
                </div>

                <form className="verify-email-form" onSubmit={handleVerify}>
                    <div className="verify-email-field">
                        <label className="verify-email-label">Verifizierungscode</label>
                        <input
                            className="verify-email-input"
                            type="text"
                            placeholder="000000"
                            value={code}
                            onChange={e => setCode(e.target.value)}
                            maxLength={6}
                            autoFocus
                        />
                    </div>

                    {error && <p className="verify-email-error">{error}</p>}
                    {resendSuccess && <p className="verify-email-success">Code wurde erneut gesendet!</p>}

                    <button type="submit" className="verify-email-submit" disabled={loading}>
                        {loading ? "Wird überprüft..." : "Bestätigen"}
                    </button>
                </form>

                <div className="verify-email-footer">
                    <button type="button" className="verify-email-resend" onClick={handleResend}>
                        Code erneut senden
                    </button>
                </div>
            </div>
        </div>
    );
}
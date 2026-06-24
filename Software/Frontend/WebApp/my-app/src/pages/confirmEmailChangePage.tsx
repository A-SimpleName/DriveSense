import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "../components/button";
import "../styles/confirmEmailChangePage.css";
import { confirmEmailChange, requestEmailChange, cancelEmailChange } from "../services/accountService";

export default function ConfirmEmailChangePage() {
    const navigate = useNavigate();

    const [code, setCode] = useState("");
    const [error, setError] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);
    const [resendSuccess, setResendSuccess] = useState(false);

    const pendingEmail = sessionStorage.getItem("pendingEmailChange") ?? "";

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();

        if (!code.trim()) return;

        setLoading(true);
        setError(null);

        try {
            await confirmEmailChange(code.trim());

            sessionStorage.removeItem("pendingEmailChange");

            navigate("/settings");
            window.location.reload();
        } catch (err: any) {
            setError(err?.message || "Ungültiger Code");
        } finally {
            setLoading(false);
        }
    }

    async function handleResend() {
        setError(null);
        setResendSuccess(false);

        try {
            if (!pendingEmail) throw new Error("Keine ausstehende Email-Änderung gefunden");
            await requestEmailChange(pendingEmail);
            setResendSuccess(true);
        } catch (err: any) {
            setError(err?.message || "Fehler beim erneuten Senden");
        }
    }

    async function handleCancel() {
        setError(null);
        try {
            await cancelEmailChange();
            sessionStorage.removeItem("pendingEmailChange");
            navigate("/settings");
        } catch (err: any) {
            setError(err?.message || "Fehler beim Abbrechen");
        }
    }

    return (
        <div className="confirm-email-page">
            <div className="confirm-email-card">
                <div className="confirm-email-header">
                    <span className="confirm-email-kicker">Verifizierung</span>
                    <h1 className="confirm-email-heading">Änderung bestätigen</h1>
                    <p className="confirm-email-copy">
                        Wir haben einen Bestätigungscode an <strong>{pendingEmail}</strong> gesendet. Bitte gib ihn ein.
                    </p>
                </div>

                <form className="confirm-email-form" onSubmit={handleSubmit}>
                    <div className="confirm-email-field">
                        <label className="confirm-email-label">Verifizierungscode</label>
                        <input
                            className="confirm-email-input"
                            type="text"
                            placeholder="000000"
                            value={code}
                            onChange={e => setCode(e.target.value)}
                            maxLength={6}
                            autoFocus
                        />
                    </div>

                    {error && <p className="confirm-email-error">{error}</p>}
                    {resendSuccess && <p className="confirm-email-success">Code wurde erneut gesendet!</p>}

                    <button type="submit" className="confirm-email-submit" disabled={loading}>
                        {loading ? "Wird überprüft..." : "Bestätigen"}
                    </button>
                </form>

                <div className="confirm-email-actions">
                    <button type="button" className="confirm-email-resend" onClick={handleResend}>
                        Code erneut senden
                    </button>
                    <button type="button" className="confirm-email-cancel" onClick={handleCancel}>
                        Abbrechen
                    </button>
                </div>
            </div>
        </div>
    );
}
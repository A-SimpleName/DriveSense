import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "../components/button";
import { Mail, X } from "lucide-react";

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
        <div>
            <h1>Email Änderung bestätigen</h1>

            <p>Wir haben einen Code an {pendingEmail} gesendet.</p>

            <form onSubmit={handleSubmit}>
                <input
                    type="text"
                    placeholder="6-stelliger Code"
                    value={code}
                    onChange={e => setCode(e.target.value)}
                    maxLength={6}
                    autoFocus
                />

                {error && <p style={{ color: "red" }}>{error}</p>}

                {resendSuccess && <p style={{ color: "green" }}>Code wurde erneut gesendet!</p>}

                <button type="submit" disabled={loading}>
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
            </form>

            <Button label="Code erneut senden" onClick={handleResend} icon={<Mail size={18} />} />

            <Button label="Abbrechen" onClick={handleCancel} icon={<X size={18} />} />
        </div>
    );
}
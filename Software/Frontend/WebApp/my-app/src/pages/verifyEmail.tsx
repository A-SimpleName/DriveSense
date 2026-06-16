import { useState } from "react";
import { verifyEmail, resendVerification } from "../services/auth";

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
        <div>
            <h1>Email bestätigen</h1>
            <p>Wir haben einen Code an deine Email gesendet. Bitte gib ihn hier ein.</p>

            <form onSubmit={handleVerify}>
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

            <button type="button" onClick={handleResend}>
                Code erneut senden
            </button>
        </div>
    );
}
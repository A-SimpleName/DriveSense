import { Button } from "../components/button";
import { signUp } from "../services/auth";
import { useState } from "react";
import { getFieldErrors } from "../errorHandling/errorHandling";

interface Props {
    onNeedsVerification: () => void;
}

// Hilfsfunktion: Fehler für ein bestimmtes Feld anzeigen
function FieldError({ errors, field }: { errors: Record<string, string> | null; field: string }) {
    if (!errors?.[field]) return null;
    return <span style={{ fontSize: "0.8rem", color: "#dc2626", display: "block", marginTop: "4px" }}>{errors[field]}</span>;
}

function SignUpPage({ onNeedsVerification }: Props) {
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [firstName, setFirstName] = useState("");
    const [lastName, setLastName] = useState("");
    const [birthdate, setBirthdate] = useState("");
    const [error, setError] = useState<string | null>(null);
    const [fieldErrors, setFieldErrors] = useState<Record<string, string> | null>(null);

    const handleSignUp = async (e: React.FormEvent) => {
        e.preventDefault();
        setError(null);
        setFieldErrors(null);
        try {
            await signUp(firstName, lastName, email, password, birthdate);
            sessionStorage.setItem("pendingVerificationEmail", email);
            onNeedsVerification();
        } catch (err: any) {
            const fe = getFieldErrors(err);
            if (fe && Object.keys(fe).length > 0) {
                setFieldErrors(fe);
            } else {
                setError(err?.message || "Registrierung fehlgeschlagen");
            }
        }
    };

    const hasError = (field: string) => !!fieldErrors?.[field];

    return (
        <div>
            <h1>Registrierung</h1>
            {error && <p style={{ color: "#dc2626" }}>{error}</p>}
            <form onSubmit={handleSignUp}>
                <div style={{ marginBottom: "12px" }}>
                    <label htmlFor="firstName">Vorname</label>
                    <input
                        id="firstName" type="text" value={firstName}
                        onChange={e => { setFirstName(e.target.value); if (hasError("firstName")) setFieldErrors(p => { const n = { ...p }; delete n!.firstName; return n; }); }}
                        style={{ borderColor: hasError("firstName") ? "#dc2626" : undefined }}
                    />
                    <FieldError errors={fieldErrors} field="firstName" />
                </div>

                <div style={{ marginBottom: "12px" }}>
                    <label htmlFor="lastName">Nachname</label>
                    <input
                        id="lastName" type="text" value={lastName}
                        onChange={e => { setLastName(e.target.value); if (hasError("lastName")) setFieldErrors(p => { const n = { ...p }; delete n!.lastName; return n; }); }}
                        style={{ borderColor: hasError("lastName") ? "#dc2626" : undefined }}
                    />
                    <FieldError errors={fieldErrors} field="lastName" />
                </div>

                <div style={{ marginBottom: "12px" }}>
                    <label htmlFor="email">Email</label>
                    <input
                        id="email" type="email" value={email}
                        onChange={e => { setEmail(e.target.value); if (hasError("email")) setFieldErrors(p => { const n = { ...p }; delete n!.email; return n; }); }}
                        style={{ borderColor: hasError("email") ? "#dc2626" : undefined }}
                    />
                    <FieldError errors={fieldErrors} field="email" />
                </div>

                <div style={{ marginBottom: "12px" }}>
                    <label htmlFor="password">Passwort</label>
                    <input
                        id="password" type="password" value={password}
                        onChange={e => { setPassword(e.target.value); if (hasError("password")) setFieldErrors(p => { const n = { ...p }; delete n!.password; return n; }); }}
                        style={{ borderColor: hasError("password") ? "#dc2626" : undefined }}
                    />
                    <FieldError errors={fieldErrors} field="password" />
                </div>

                <div style={{ marginBottom: "12px" }}>
                    <label htmlFor="birthdate">Geburtsdatum</label>
                    <input
                        id="birthdate" type="date" value={birthdate}
                        onChange={e => setBirthdate(e.target.value)}
                    />
                </div>

                <Button label="Registrieren" type="submit" />
            </form>
        </div>
    );
}

export default SignUpPage;

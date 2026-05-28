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
    const [fName, setFname] = useState("");
    const [lName, setLName] = useState("");
    const [birthdate, setBirthdate] = useState("");
    const [error, setError] = useState<string | null>(null);
    const [fieldErrors, setFieldErrors] = useState<Record<string, string> | null>(null);

    const handleSignUp = async (e: React.FormEvent) => {
        e.preventDefault();
        setError(null);
        setFieldErrors(null);
        try {
            await signUp(fName, lName, email, password, birthdate);
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
                    <label htmlFor="fname">Vorname</label>
                    <input
                        id="fname" type="text" value={fName}
                        onChange={e => { setFname(e.target.value); if (hasError("fName")) setFieldErrors(p => { const n = { ...p }; delete n!.fName; return n; }); }}
                        style={{ borderColor: hasError("fName") ? "#dc2626" : undefined }}
                    />
                    <FieldError errors={fieldErrors} field="fName" />
                </div>

                <div style={{ marginBottom: "12px" }}>
                    <label htmlFor="lname">Nachname</label>
                    <input
                        id="lname" type="text" value={lName}
                        onChange={e => { setLName(e.target.value); if (hasError("lName")) setFieldErrors(p => { const n = { ...p }; delete n!.lName; return n; }); }}
                        style={{ borderColor: hasError("lName") ? "#dc2626" : undefined }}
                    />
                    <FieldError errors={fieldErrors} field="lName" />
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
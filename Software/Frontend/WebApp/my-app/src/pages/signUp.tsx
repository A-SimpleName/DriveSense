// SignUpPage — nach Registrierung zu Verifizierung weiterleiten
import Label from "../components/label";
import { Button } from "../components/button";
import { signUp } from "../services/auth";
import { useState } from "react";

interface Props {
    onNeedsVerification: () => void;
}

function SignUpPage({ onNeedsVerification }: Props) {
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [firstName, setFirstName] = useState("");
    const [lastName, setLastName] = useState("");
    const [birthdate, setBirthdate] = useState("");
    const [error, setError] = useState<string | null>(null);

    const handleSignUp = async (e: React.FormEvent) => {
        e.preventDefault();
        setError(null);
        try {
            await signUp(firstName, lastName, email, password, birthdate);
            sessionStorage.setItem("pendingVerificationEmail", email);
            onNeedsVerification();
        } catch (err: any) {
            setError(err?.message || "Registrierung fehlgeschlagen");
        }
    };

    return (
        <div>
            <h1>Registrierung</h1>
            <form onSubmit={handleSignUp}>
                <Label type="text" name="firstName" text="Vorname" value={firstName} onchange={e => setFirstName(e.target.value)} />
                <Label type="text" name="lastName" text="Nachname" value={lastName} onchange={e => setLastName(e.target.value)} />
                <Label type="email" name="email" text="Email" value={email} onchange={e => setEmail(e.target.value)} />
                <Label type="password" name="password" text="Password" value={password} onchange={e => setPassword(e.target.value)} />
                <Label type="date" name="birthdate" text="Geburtsdatum" value={birthdate} onchange={e => setBirthdate(e.target.value)} />
                {error && <p style={{ color: "red" }}>{error}</p>}
                <Button label="Registrieren" type="submit" />
            </form>
        </div>
    );
}

export default SignUpPage;
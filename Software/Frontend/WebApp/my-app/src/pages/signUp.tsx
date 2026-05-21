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
    const [fName, setFname] = useState("");
    const [lName, setLName] = useState("");
    const [birthdate, setBirthdate] = useState("");
    const [error, setError] = useState<string | null>(null);

    const handleSignUp = async (e: React.FormEvent) => {
        e.preventDefault();
        setError(null);
        try {
            await signUp(fName, lName, email, password, birthdate);
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
                <Label type="text" name="fname" text="Vorname" value={fName} onchange={e => setFname(e.target.value)} />
                <Label type="text" name="lname" text="Nachname" value={lName} onchange={e => setLName(e.target.value)} />
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
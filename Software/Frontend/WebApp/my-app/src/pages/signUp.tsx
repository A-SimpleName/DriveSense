import Label from "../components/label";
import { Button } from "../components/button";
import { useNavigate } from "react-router-dom";
import { signUp } from "../services/auth";
import { useState } from "react";

function SignUpPage() {
    const navigate = useNavigate();
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [firstName, setFirstName] = useState("");
    const [lastName, setLastName] = useState("");
    const [birthdate, setBirthdate] = useState("");

    const handleSignUp = () => {
        signUp(firstName, lastName, email, password, birthdate);
        navigate("/login");
    };

    return (
        <div>
            <h1>Registrierung</h1> 
            <form onSubmit={(e)=>{
                e.preventDefault();
                 handleSignUp();
                }}>
                <Label type="text" name="firstName" text="Vorname" value={firstName} onchange={(e) => setFirstName(e.target.value)} />
                <Label type="text" name="lastName" text="Nachname" value={lastName} onchange={(e) => setLastName(e.target.value)} />
                <Label type="email" name="email" text="Email" value={email} onchange={(e) => setEmail(e.target.value)} />
                <Label type="password" name="password" text="Password" value={password} onchange={(e) => setPassword(e.target.value)} />
                <Label type="date" name="birthdate" text="Geburtsdatum" value={birthdate} onchange={(e) => setBirthdate(e.target.value)} />
                <Button label="Registrieren" type="submit" />
            </form>
        </div>
    );
}

export default SignUpPage;

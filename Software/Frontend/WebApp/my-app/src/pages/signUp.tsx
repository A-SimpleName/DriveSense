import Label from "../components/label";
import { Button } from "../components/button";
import { useNavigate } from "react-router-dom";
import { signUp } from "../services/auth";
import { useState } from "react";

function SignUpPage() {
    const navigate = useNavigate();
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [fname, setFname] = useState("");
    const [lname, setLname] = useState("");

    const handleSignUp = () => {
        signUp(fname, lname, email, password);
        navigate("/login");
    };

    return (
        <div>
            <h1>Registrierung</h1> 
            <form onSubmit={(e)=>{
                e.preventDefault();
                 handleSignUp();
                }}>
                <Label type="text" name="fname" text="Vorname" value={fname} onchange={(e) => setFname(e.target.value)} />
                <Label type="text" name="lname" text="Nachname" value={lname} onchange={(e) => setLname(e.target.value)} />
                <Label type="email" name="email" text="Email" value={email} onchange={(e) => setEmail(e.target.value)} />
                <Label type="password" name="password" text="Password" value={password} onchange={(e) => setPassword(e.target.value)} />
                <Button label="Registrieren" type="submit" />
            </form>
        </div>
    );
}

export default SignUpPage;
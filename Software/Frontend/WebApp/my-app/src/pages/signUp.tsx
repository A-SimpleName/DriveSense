import Label from "../components/label";
import { Button } from "../components/button";
import { useNavigate } from "react-router-dom";
import { SignUp } from "../services/auth";

function SignUpPage() {
    const navigate = useNavigate();

    const handleSignUp = () => {
        SignUp();
        navigate("/login");
    };

    return (
        <div>
            <h1>Registrierung</h1> 
            <Label type="email" name="email" text="Email" />
            <Label type="password" name="password" text="Password" />
            <Button label="Registrieren" onClick={handleSignUp} />
        </div>
    );
}

export default SignUpPage;
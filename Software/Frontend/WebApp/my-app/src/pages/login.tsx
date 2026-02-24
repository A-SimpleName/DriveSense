import { Link, useNavigate } from "react-router-dom";
import Label from "../components/label";
import { login } from "../services/auth";
import { useState } from "react";
import { Button } from "../components/button";


function Login({onLoginSuccess}: {onLoginSuccess: () => void}) {
    const navigate = useNavigate();
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");

    const handleLogin = () => {
        login(email, password);
        onLoginSuccess();
        navigate("/");
    };
  
    return (
        <div>
            <h1>Login</h1>
            <form onSubmit={(e)=>{
                e.preventDefault();
                 handleLogin();
                }}>
                <Label type="email" name="email" text="Email" value={email} onchange={(e) => setEmail(e.target.value)} />
                <Label type="password" name="password" text="Password" value={password} onchange={(e) => setPassword(e.target.value)} />
                <Button label="Einloggen" type="submit" />
            </form>
            <Link to="/registrieren">Noch keinen Account? Registrieren</Link>
        </div>
    );
}

export default Login;
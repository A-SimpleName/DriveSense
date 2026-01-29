import { Link, useNavigate } from "react-router-dom";
import { Button } from "../components/button";
import Label from "../components/label";
import { login } from "../services/auth";


function Login({onLoginSuccess}: {onLoginSuccess: () => void}) {
    const navigate = useNavigate();

    const handleLogin = () => {
        login();
        onLoginSuccess();
        navigate("/");
    };
  
    return (
        <div>
            <h1>Login</h1>
            <Label type="email" name="email" text="Email" />
            <Label type="password" name="password" text="Password" />
            <Button label="Einloggen" onClick={handleLogin} />
            <Link to="/signUp">Noch keinen Account? Registrieren</Link>
        </div>
    );
}

export default Login;
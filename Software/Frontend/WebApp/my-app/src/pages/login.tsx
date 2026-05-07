import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { login } from "../services/auth";
import { Button } from "../components/button";

export default function Login({ onLoginSuccess }: { onLoginSuccess: () => void }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const navigate = useNavigate();
  const [show, setShow] = useState(false);

  const handleLogin = async () => {
    try {
      await login(email, password);

      sessionStorage.removeItem("profileSelected");
      onLoginSuccess();
      navigate("/select-profile");
    } catch (err) {
      alert("Login fehlgeschlagen");
    }
  };

  return (
    <div>
      <h1>Login</h1>

      <input
        type="email"
        placeholder="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
      />

      <input
        type={show ? "text" : "password"}
        placeholder="Passwort"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
      />
      
     <Button
        label={show ? "Verbergen" : "Anzeigen"}
        type="button"
        onClick={() => setShow(prev => !prev)}
      />

      <button onClick={handleLogin}>Login</button>
      <br></br>
      <p>
        Noch keinen Account?{" "}
        <Link to="/signUp">Registrieren</Link>
      </p>
    </div>
  );
}

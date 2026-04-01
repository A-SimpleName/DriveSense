import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { login } from "../services/auth";

export default function Login({ onLoginSuccess }: { onLoginSuccess: () => void }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const navigate = useNavigate();

  const handleLogin = async () => {
    try {
      await login(email, password);

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
        type="password"
        placeholder="Passwort"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
      />

      <button onClick={handleLogin}>Login</button>
      <br></br>
      <p>
        Noch keinen Account?{" "}
        <Link to="/registrieren">Registrieren</Link>
      </p>
    </div>
  );
}
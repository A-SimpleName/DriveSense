import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { login } from "../services/auth";
import { Button } from "../components/button";
import "../styles/login.css";

interface Props {
  onLoginSuccess: () => void;
  onNeedsVerification: () => void;
}

export default function LoginPage({
  onLoginSuccess,
  onNeedsVerification,
}: Props) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [show, setShow] = useState(false);

  const navigate = useNavigate();

  const handleLogin = async () => {
    setError(null);

    try {
      await login(email, password);

      sessionStorage.removeItem("profileSelected");

      onLoginSuccess();
      navigate("/select-profile");
    } catch (err: any) {
      if (err?.status === 403 || err?.message?.includes("403")) {
        sessionStorage.setItem("pendingVerificationEmail", email);
        onNeedsVerification();
      } else {
        setError("Login fehlgeschlagen");
      }
    }
  };

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="login-header">
          <span className="login-title">Drive Sense</span>

          <h1 className="login-heading">Melde dich an</h1>

          <p className="login-subtitle">
            Nutze dein Profil, um auf deine Fahrzeuge, Fahrten und Protokolle
            zuzugreifen.
          </p>
        </div>

        <div className="login-form">
          <input
            className="login-input"
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />

          <div className="password-input-wrapper">
            <input
              className="login-input login-input-password"
              type={show ? "text" : "password"}
              placeholder="Passwort"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />

            <button
              type="button"
              className="password-toggle"
              onClick={() => setShow((prev) => !prev)}
              aria-label={
                show ? "Passwort verbergen" : "Passwort anzeigen"
              }
            >
              {show ? (
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M2 12C3.5 16.5 7.5 19.5 12 19.5c4.5 0 8.5-3 10-7.5C20.5 7 16.5 4.5 12 4.5 7.5 4.5 3.5 7 2 12Z" />
                  <path d="M9.5 9.5a2.5 2.5 0 0 0 5 0" />
                  <path d="M1 1l22 22" />
                </svg>
              ) : (
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M1.42 12.93C2.73 16.47 6.14 19.5 12 19.5c5.86 0 9.27-3.03 10.58-6.57C21.27 8.53 17.86 5.5 12 5.5 6.14 5.5 2.73 8.53 1.42 12.93Z" />
                  <circle cx="12" cy="12" r="3" />
                </svg>
              )}
            </button>
          </div>

          {error && <p style={{ color: "red" }}>{error}</p>}

          <div className="login-actions">
            <Button
              className="login-submit"
              label="Login"
              type="button"
              onClick={handleLogin}
            />
          </div>

          <Link to="/forgot-password">
            Passwort vergessen?
          </Link>
        </div>

        <div className="login-footer">
          Noch keinen Account?{" "}
          <Link to="/signUp">Registrieren</Link>
        </div>
      </div>
    </div>
  );
}
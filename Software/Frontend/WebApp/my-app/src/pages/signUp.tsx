// SignUpPage — nach Registrierung zu Verifizierung weiterleiten
import React, { useState } from "react";
import { Link } from "react-router-dom";
import { signUp } from "../services/auth";
import { getFieldErrors } from "../errorHandling/errorHandling"; // ← deinen tatsächlichen Import-Pfad anpassen
import "../styles/signup.css";

interface Props {
    onNeedsVerification: () => void;
}

function FieldError({ errors, field }: { errors: Record<string, string> | null; field: string }) {
    if (!errors?.[field]) return null;
    return (
        <span className="error-text" style={{ fontSize: "0.8rem", display: "block", marginTop: "4px" }}>
            {errors[field]}
        </span>
    );
}

function SignUpPage({ onNeedsVerification }: Props) {
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");
    const [firstName, setFirstName] = useState("");
    const [lastName, setLastName] = useState("");
    const [birthdate, setBirthdate] = useState("");
    const [error, setError] = useState<string | null>(null);
    const [fieldErrors, setFieldErrors] = useState<Record<string, string> | null>(null);
    const [showPassword, setShowPassword] = useState(false);
    const [showConfirmPassword, setShowConfirmPassword] = useState(false);
    const [submitting, setSubmitting] = useState(false);

    const clearFieldError = (field: string) => {
        setFieldErrors(prev => {
            if (!prev?.[field]) return prev;
            const next = { ...prev };
            delete next[field];
            return Object.keys(next).length > 0 ? next : null;
        });
    };

    const passwordRules = [
        { key: "length", label: "Mindestens 8 Zeichen", met: password.length >= 8 },
        { key: "upper", label: "Ein Großbuchstabe", met: /[A-Z]/.test(password) },
        { key: "lower", label: "Ein Kleinbuchstabe", met: /[a-z]/.test(password) },
        { key: "number", label: "Eine Zahl", met: /\d/.test(password) },
    ];

    const passwordMeetsPolicy = passwordRules.every((rule) => rule.met);
    const passwordMismatch = confirmPassword.length > 0 && password !== confirmPassword;
    const submitDisabled =
        !firstName || !lastName || !email || !password || !confirmPassword ||
        !birthdate || passwordMismatch || !passwordMeetsPolicy;

    const hasError = (field: string) => !!fieldErrors?.[field];

    const handleSignUp = async (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        setError(null);
        setFieldErrors(null);
        setSubmitting(true);

        if (password !== confirmPassword) {
            setError("Die Passwörter stimmen nicht überein.");
            setSubmitting(false);
            return;
        }

        try {
            await signUp(firstName, lastName, email, password, birthdate);
            sessionStorage.setItem("pendingVerificationEmail", email);
            onNeedsVerification();
        } catch (err: any) {
            const fields = getFieldErrors(err);
            if (fields && Object.keys(fields).length > 0) {
                setFieldErrors(fields);
            } else {
                setError(err?.message || "Registrierung fehlgeschlagen");
            }
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <div className="signup-page">
            <div className="signup-card">
                <div className="signup-hero">
                    <div className="signup-hero-badge">Drive Sense</div>
                    <h1 className="signup-heading">Erstelle dein Profil</h1>
                    <p className="signup-copy">
                        Registriere dich, um Fahrten, Fahrzeuge und Protokolle zentral zu verwalten.
                    </p>
                    <ul className="signup-highlights">
                        <li>Dein persönliches Fahrzeug- und Protokoll-Setup</li>
                        <li>Schnelle Fahrtenverwaltung mit vollständigem Überblick</li>
                        <li>Sichere Anmeldung mit verifizierter E-Mail</li>
                    </ul>
                </div>

                <div className="signup-form-panel">
                    <div className="signup-panel-header">
                        <p className="signup-panel-kicker">Registrierung</p>
                        <h2 className="signup-panel-title">Neues Konto anlegen</h2>
                        <p className="signup-panel-copy">Fülle die Details aus und sichere dein Konto mit einem zweiten Passwort-Eintrag ab.</p>
                    </div>

                    <form className="signup-form" onSubmit={handleSignUp}>
                        <div className="signup-grid-two">
                            <label className="signup-field">
                                <span className="signup-label">Vorname</span>
                                <input
                                    className={`signup-input ${hasError("firstName") ? "input-error" : ""}`}
                                    type="text"
                                    id="firstName"
                                    value={firstName}
                                    onChange={(e) => {
                                        setFirstName(e.target.value);
                                        clearFieldError("firstName");
                                    }}
                                    placeholder="Max"
                                />
                                <FieldError errors={fieldErrors} field="firstName" />
                            </label>

                            <label className="signup-field">
                                <span className="signup-label">Nachname</span>
                                <input
                                    className={`signup-input ${hasError("lastName") ? "input-error" : ""}`}
                                    type="text"
                                    id="lastName"
                                    value={lastName}
                                    onChange={(e) => {
                                        setLastName(e.target.value);
                                        clearFieldError("lastName");
                                    }}
                                    placeholder="Mustermann"
                                />
                                <FieldError errors={fieldErrors} field="lastName" />
                            </label>
                        </div>

                        <label className="signup-field">
                            <span className="signup-label">E-Mail</span>
                            <input
                                className={`signup-input ${hasError("email") ? "input-error" : ""}`}
                                type="email"
                                id="email"
                                value={email}
                                onChange={(e) => {
                                    setEmail(e.target.value);
                                    clearFieldError("email");
                                }}
                                placeholder="max@example.com"
                            />
                            <FieldError errors={fieldErrors} field="email" />
                        </label>

                        <label className="signup-field">
                            <span className="signup-label">Geburtsdatum</span>
                            <input
                                className="signup-input"
                                type="date"
                                id="birthdate"
                                value={birthdate}
                                onChange={(e) => setBirthdate(e.target.value)}
                            />
                            <FieldError errors={fieldErrors} field="birthdate" />
                        </label>

                        <label className="signup-field">
                            <span className="signup-label">Passwort</span>
                            <div className="password-input-wrapper">
                                <input
                                    className={`signup-input password-input ${hasError("password") || (password.length > 0 && !passwordMeetsPolicy) ? "input-error" : ""}`}
                                    type={showPassword ? "text" : "password"}
                                    id="password"
                                    value={password}
                                    onChange={(e) => {
                                        setPassword(e.target.value);
                                        clearFieldError("password");
                                    }}
                                    placeholder="Passwort eingeben"
                                />
                                <button
                                    type="button"
                                    className="password-toggle"
                                    onClick={() => setShowPassword((prev) => !prev)}
                                    aria-label={showPassword ? "Passwort verbergen" : "Passwort anzeigen"}
                                >
                                    {showPassword ? (
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round">
                                            <path d="M2 12C3.5 16.5 7.5 19.5 12 19.5c4.5 0 8.5-3 10-7.5C20.5 7 16.5 4.5 12 4.5 7.5 4.5 3.5 7 2 12Z" />
                                            <path d="M9.5 9.5a2.5 2.5 0 0 0 5 0" />
                                            <path d="M1 1l22 22" />
                                        </svg>
                                    ) : (
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round">
                                            <path d="M1.42 12.93C2.73 16.47 6.14 19.5 12 19.5c5.86 0 9.27-3.03 10.58-6.57C21.27 8.53 17.86 5.5 12 5.5 6.14 5.5 2.73 8.53 1.42 12.93Z" />
                                            <circle cx="12" cy="12" r="3" />
                                        </svg>
                                    )}
                                </button>
                            </div>
                            <FieldError errors={fieldErrors} field="password" />
                            <ul className="password-requirements">
                                {passwordRules.map((rule) => (
                                    <li
                                        key={rule.key}
                                        className={`password-rule ${rule.met ? "is-valid" : "is-invalid"}`}
                                    >
                                        <span className="password-rule-marker">{rule.met ? "✓" : "•"}</span>
                                        <span>{rule.label}</span>
                                    </li>
                                ))}
                            </ul>
                        </label>

                        <label className="signup-field">
                            <span className="signup-label">Passwort bestätigen</span>
                            <div className="password-input-wrapper">
                                <input
                                    className={`signup-input password-input ${passwordMismatch ? "input-error" : ""}`}
                                    type={showConfirmPassword ? "text" : "password"}
                                    value={confirmPassword}
                                    onChange={(e) => setConfirmPassword(e.target.value)}
                                    placeholder="Passwort erneut eingeben"
                                />
                                <button
                                    type="button"
                                    className="password-toggle"
                                    onClick={() => setShowConfirmPassword((prev) => !prev)}
                                    aria-label={showConfirmPassword ? "Passwort verbergen" : "Passwort anzeigen"}
                                >
                                    {showConfirmPassword ? (
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round">
                                            <path d="M2 12C3.5 16.5 7.5 19.5 12 19.5c4.5 0 8.5-3 10-7.5C20.5 7 16.5 4.5 12 4.5 7.5 4.5 3.5 7 2 12Z" />
                                            <path d="M9.5 9.5a2.5 2.5 0 0 0 5 0" />
                                            <path d="M1 1l22 22" />
                                        </svg>
                                    ) : (
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round">
                                            <path d="M1.42 12.93C2.73 16.47 6.14 19.5 12 19.5c5.86 0 9.27-3.03 10.58-6.57C21.27 8.53 17.86 5.5 12 5.5 6.14 5.5 2.73 8.53 1.42 12.93Z" />
                                            <circle cx="12" cy="12" r="3" />
                                        </svg>
                                    )}
                                </button>
                            </div>
                            {passwordMismatch && (
                                <span className="signup-error-text">Die Passwörter stimmen nicht überein.</span>
                            )}
                        </label>

                        {error && <p className="signup-error-banner">{error}</p>}

                        <button className="signup-submit full" type="submit" disabled={submitDisabled || submitting}>
                            {submitting && (
                                <span style={{
                                    display: "inline-block", width: "12px", height: "12px",
                                    border: "2px solid rgba(255,255,255,0.35)", borderTopColor: "currentColor",
                                    borderRadius: "50%", animation: "spin 0.6s linear infinite",
                                    verticalAlign: "middle", marginRight: "6px",
                                }} />
                            )}
                            {submitting ? "Wird registriert..." : "Konto erstellen"}
                        </button>
                    </form>

                    <div className="signup-footer">
                        <span>Bereits registriert?</span>
                        <Link to="/login">Zur Anmeldung</Link>
                        <Link to="/datenschutz">Datenschutzerklärung</Link>
                    </div>
                </div>
            </div>
        </div>
    );
}

export default SignUpPage;

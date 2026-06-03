// Settings.tsx

import { useState } from "react";
import { useNavigate } from "react-router-dom";

import { useAuth } from "../context/authContext";
import { Button } from "../components/button";
import { AddForm } from "../components/addForm";

import { updateAccount } from "../services/accountService";
import { changePassword } from "../services/auth";

export default function Settings() {
    const { account } = useAuth();
    const navigate = useNavigate();
    const [error, setError] =useState<string | null>(null);

    const [editOpen, setEditOpen] = useState(false);
    const [showPasswordForm, setShowPasswordForm] = useState(false);

    async function handleUpdateAccount(values: Record<string, string | number>) {
        await updateAccount(
            String(values.firstName),
            String(values.lastName),
            String(values.email)
        ).then(() => {
            // Email geändert
            if (String(values.email) !== account?.email) {
                sessionStorage.setItem(
                    "pendingEmailChange",
                    String(values.email)
                )

                navigate("/confirm-email-change")
            } else {
                window.location.reload()
            }
        })
        .catch(err => {
            setError(err?.message || "Fehler beim Aktualisieren des Accounts");
        })
    }

    async function handleChangePassword(values: Record<string, string | number>) {
        const oldPassword = String(values.oldPassword);
        const newPassword = String(values.newPassword);
        const repeatPassword = String(values.repeatPassword);

        if (newPassword !== repeatPassword) {
            throw new Error("Passwörter stimmen nicht überein");
        }

        await changePassword(oldPassword, newPassword);

        setShowPasswordForm(false);
    }

    if (error) return <p style={{ color: "#dc2626" }}>Fehler: {error}</p>
    
    return (
        <>
            <h1>Einstellungen</h1>

            <h2>Account</h2>

            <p>
                Angemeldeter Account: {account?.firstName} {account?.lastName}
            </p>
            <p>Email: {account?.email}</p>

            <Button
                label="Passwort ändern"
                type="button"
                onClick={() => setShowPasswordForm(true)}
            />

            <Button
                label="Account löschen"
                type="button"
            />

            <Button
                label="Account bearbeiten"
                type="button"
                onClick={() => setEditOpen(true)}
            />

            {editOpen && (
                <AddForm
                    title="Account bearbeiten"
                    submitLabel="Speichern"
                    onClose={() => setEditOpen(false)}
                    onSubmit={handleUpdateAccount}
                    fields={[
                        {
                            type: "text",
                            key: "firstName",
                            label: "Vorname",
                            defaultValue: account?.firstName
                        },
                        {
                            type: "text",
                            key: "lastName",
                            label: "Nachname",
                            defaultValue: account?.lastName
                        },
                        {
                            type: "text",
                            key: "email",
                            label: "Email",
                            defaultValue: account?.email
                        }
                    ]}
                />
            )}
            {showPasswordForm && (
                <AddForm
                    title="Passwort ändern"
                    submitLabel="Speichern"
                    onClose={() => setShowPasswordForm(false)}
                    onSubmit={handleChangePassword}
                    fields={[
                        {
                            type: "text",
                            key: "oldPassword",
                            label: "Altes Passwort"
                        },
                        {
                            type: "text",
                            key: "newPassword",
                            label: "Neues Passwort"
                        },
                        {
                            type: "text",
                            key: "repeatPassword",
                            label: "Neues Passwort wiederholen"
                        }
                    ]}
                />
            )}
        </>
    );
}

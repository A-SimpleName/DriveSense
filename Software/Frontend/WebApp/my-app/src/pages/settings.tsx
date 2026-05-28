// Settings.tsx

import { useState } from "react";
import { useNavigate } from "react-router-dom";

import { useAuth } from "../context/authContext";
import { Button } from "../components/button";
import { AddForm } from "../components/addForm";

import { updateAccount } from "../services/accountService";

export default function Settings() {
    const { account } = useAuth();
    const navigate = useNavigate();
    const [error, setError] =useState<string | null>(null);

    const [editOpen, setEditOpen] = useState(false);

    async function handleUpdateAccount(values: Record<string, string | number>) {
        await updateAccount(
            String(values.fName),
            String(values.lName),
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

    if (error) return <p style={{ color: "#dc2626" }}>Fehler: {error}</p>
    
    return (
        <>
            <h1>Einstellungen</h1>

            <h2>Account</h2>

            <p>
                Angemeldeter Account: {account?.fName} {account?.lName}
            </p>

            <p>Email: {account?.email}</p>

            <Button
                label="Passwort ändern"
                type="button"
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
                            key: "fName",
                            label: "Vorname",
                            defaultValue: account?.fName
                        },
                        {
                            type: "text",
                            key: "lName",
                            label: "Nachname",
                            defaultValue: account?.lName
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
        </>
    );
}
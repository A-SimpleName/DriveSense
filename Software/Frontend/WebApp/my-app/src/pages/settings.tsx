// Settings.tsx

import { useState } from "react";
import { useNavigate } from "react-router-dom";

import { useAuth } from "../context/authContext";
import { Button } from "../components/button";
import { AddForm } from "../components/addForm";
import { ConfirmationDialog } from "../components/ConfirmationDialog";

import { deleteAccount, updateAccount, requestEmailChange } from "../services/accountService";
import { changePassword } from "../services/auth";
import StatCard from "../components/statCard";

export default function Settings() {
    const { account, setAccount,setProfile } = useAuth();
    const navigate = useNavigate();
    const [error, setError] = useState<string | null>(null);
    const [confirmDelete, setConfirmDelete] = useState(false);
    const [deleting, setDeleting] = useState(false);
    const [editOpen, setEditOpen] = useState(false);
    const [editEmailOpen, setEditEmailOpen] = useState(false);
    const [showPasswordForm, setShowPasswordForm] = useState(false);

    async function handleUpdateAccount(values: Record<string, string | number>) {
        try {
            await updateAccount(
                String(values.firstName),
                String(values.lastName)
            );
            window.location.reload();
        } catch (err: any) {
            setError(err?.message || "Fehler beim Aktualisieren des Accounts");
        }
    }

    async function handleRequestEmailChange(values: Record<string, string | number>) {
        const newEmail = String(values.email);
        try {
            await requestEmailChange(newEmail);
            sessionStorage.setItem("pendingEmailChange", newEmail);
            navigate("/confirm-email-change");
        } catch (err: any) {
            setError(err?.message || "Fehler beim Ändern der E-Mail");
        }
    }

    async function handleDelete() {
        setError(null);
        setDeleting(true);
        try {
            await deleteAccount();
            setAccount(null);
            setProfile(null);
            navigate("/login");
        } catch (err: any) {
            setError(err?.message || "Löschen fehlgeschlagen");
            setConfirmDelete(false);
        } finally {
            setDeleting(false);
        }
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

    if (error) return <p style={{ color: "#dc2626" }}>Fehler: {error}</p>;

    return (
        <>
            <h1>Einstellungen</h1>

            <h2>Account</h2>

            <StatCard title="Angemeldeter Account:" value={`${account?.firstName} ${account?.lastName}`} />
            <StatCard title="Email:" value={account?.email} />

            <Button
                label="Name bearbeiten"
                type="button"
                onClick={() => setEditOpen(true)}
            />

            <Button
                label="E-Mail ändern"
                type="button"
                onClick={() => setEditEmailOpen(true)}
            />

            <Button
                label="Passwort ändern"
                type="button"
                onClick={() => setShowPasswordForm(true)}
            />

            <Button
                label="Account löschen"
                type="button"
                onClick={() => setConfirmDelete(true)}
            />

            {editOpen && (
                <AddForm
                    title="Name bearbeiten"
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
                        }
                    ]}
                />
            )}

            {editEmailOpen && (
                <AddForm
                    title="E-Mail ändern"
                    submitLabel="Code senden"
                    onClose={() => setEditEmailOpen(false)}
                    onSubmit={handleRequestEmailChange}
                    fields={[
                        {
                            type: "text",
                            key: "email",
                            label: "Neue E-Mail",
                            defaultValue: ""
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

            <ConfirmationDialog
                open={confirmDelete}
                title="Account löschen"
                message="Möchtest du diesen Account wirklich löschen?"
                confirmLabel="Ja, löschen"
                cancelLabel="Abbrechen"
                confirmLoading={deleting}
                onConfirm={handleDelete}
                onCancel={() => setConfirmDelete(false)}
            />
        </>
    );
}
import { useEffect, useState } from "react";
import { useAuth } from "../context/authContext";
import { useNavigate } from "react-router-dom";
import {
    adminGetAllAccounts, adminDeleteAccount,
    adminGetAllProfiles, adminDeleteProfile,
    adminGetAllGroups, adminDeleteGroup,
    adminGetGroupMembers, adminRemoveMember
} from "../services/adminService";
import type { AccountResponse } from "../model/account";
import type { Profile } from "../model/profile";
import type { UserGroup, GroupMember } from "../model/usergroup";
import { ConfirmationDialog } from "../components/ConfirmationDialog";
import "../styles/admin.css";

type Tab = "accounts" | "profile" | "gruppen";

function AdminPage() {
    const { profile } = useAuth();
    const navigate = useNavigate();
    const [activeTab, setActiveTab] = useState<Tab>("accounts");
    const [loading, setLoading] = useState(false);

    // Getrennte Fehler: Laden vs. Aktionen
    const [loadError, setLoadError] = useState<string | null>(null);
    const [actionError, setActionError] = useState<string | null>(null);

    const [accounts, setAccounts] = useState<AccountResponse[]>([]);
    const [profiles, setProfiles] = useState<Profile[]>([]);
    const [groups, setGroups] = useState<UserGroup[]>([]);
    const [groupMembers, setGroupMembers] = useState<{ [groupId: number]: GroupMember[] }>({});
    const [expandedGroupId, setExpandedGroupId] = useState<number | null>(null);

    // ConfirmationDialog State
    const [confirmAction, setConfirmAction] = useState<{ label: string; onConfirm: () => void } | null>(null);

    useEffect(() => {
        if (profile?.role !== "ADMIN") navigate("/");
    }, [profile]);

    useEffect(() => {
        setLoading(true);
        setLoadError(null);
        setActionError(null);

        const load =
            activeTab === "accounts" ? adminGetAllAccounts().then(d => setAccounts(d)) :
            activeTab === "profile"  ? Promise.all([adminGetAllProfiles(), adminGetAllAccounts()]).then(([p, a]) => { setProfiles(p); setAccounts(a); }) :
                                      adminGetAllGroups().then(d => setGroups(d));

        load.catch(err => setLoadError(err?.message || "Laden fehlgeschlagen"))
            .finally(() => setLoading(false));
    }, [activeTab]);

    const confirm = (label: string, fn: () => Promise<void>) => {
        setConfirmAction({
            label,
            onConfirm: () => {
                setActionError(null);
                fn().catch(err => setActionError(err?.message || "Aktion fehlgeschlagen"));
                setConfirmAction(null);
            }
        });
    };

    const handleDeleteAccount = (id: number) =>
        confirm("Account wirklich löschen?", () =>
            adminDeleteAccount(id).then(() => setAccounts(prev => prev.filter(a => a.id !== id))));

    const handleDeleteProfile = (id: number) =>
        confirm("Profil wirklich löschen?", () =>
            adminDeleteProfile(id).then(() => setProfiles(prev => prev.filter(p => p.id !== id))));

    const handleDeleteGroup = (id: number) =>
        confirm("Gruppe wirklich löschen?", () =>
            adminDeleteGroup(id).then(() => { setGroups(prev => prev.filter(g => g.id !== id)); setExpandedGroupId(null); }));

    const handleExpandGroup = (groupId: number) => {
        if (expandedGroupId === groupId) { setExpandedGroupId(null); return; }
        setExpandedGroupId(groupId);
        if (!groupMembers[groupId]) {
            adminGetGroupMembers(groupId)
                .then(members => setGroupMembers(prev => ({ ...prev, [groupId]: members })))
                .catch(err => setActionError(err?.message || "Mitglieder konnten nicht geladen werden"));
        }
    };

    const handleRemoveMember = (groupId: number, profileId: number) =>
        confirm("Mitglied wirklich entfernen?", () =>
            adminRemoveMember(groupId, profileId).then(() =>
                setGroupMembers(prev => ({ ...prev, [groupId]: prev[groupId].filter(m => m.profileId !== profileId) }))));

    if (loading) return <p>Laden...</p>;
    if (loadError) return (
        <div>
            <p style={{ color: "#dc2626" }}>Fehler: {loadError}</p>
            <button onClick={() => setActiveTab(activeTab)}>Erneut versuchen</button>
        </div>
    );

    return (
        <div>
            <h1>Admin Panel</h1>

            {/* Aktionsfehler — bleibt sichtbar bis nächste Aktion */}
            {actionError && (
                <p style={{ color: "#dc2626", marginBottom: "1rem" }}>{actionError}</p>
            )}

            <div className="admin-tabs">
                {(["accounts", "profile", "gruppen"] as Tab[]).map(tab => (
                    <button key={tab} className={`admin-tab-btn ${activeTab === tab ? "active" : ""}`}
                        onClick={() => setActiveTab(tab)}>
                        {tab.charAt(0).toUpperCase() + tab.slice(1)}
                    </button>
                ))}
            </div>

            {activeTab === "accounts" && (
                <table className="admin-table">
                    <thead><tr><th>ID</th><th>Vorname</th><th>Nachname</th><th>Email</th><th>Aktionen</th></tr></thead>
                    <tbody>
                        {accounts.map(account => (
                            <tr key={account.id}>
                                <td>{account.id}</td>
                                <td>{account.firstName}</td>
                                <td>{account.lastName}</td>
                                <td>{account.email}</td>
                                <td className="admin-actions">
                                    <button className="admin-delete-btn" onClick={() => handleDeleteAccount(account.id)}>Löschen</button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            )}

            {activeTab === "profile" && (
                <table className="admin-table">
                    <thead><tr><th>Account</th><th>Profil ID</th><th>Name</th><th>Rolle</th><th>Aktionen</th></tr></thead>
                    <tbody>
                        {accounts.map(account => {
                            const accountProfiles = profiles.filter(p => p.account_id === account.id);
                            if (accountProfiles.length === 0) return null;
                            return (
                                <>
                                    <tr key={`account-${account.id}`} style={{ background: "rgb(126, 132, 218)", color: "white" }}>
                                        <td colSpan={5} style={{ textAlign: "left", paddingLeft: "8px", fontWeight: "bold" }}>
                                            {account.firstName} {account.lastName} — {account.email}
                                        </td>
                                    </tr>
                                    {accountProfiles.map(p => (
                                        <tr key={p.id} className="admin-member-row">
                                            <td></td><td>{p.id}</td><td>{p.name}</td><td>{p.role}</td>
                                            <td className="admin-actions">
                                                <button className="admin-delete-btn" onClick={() => handleDeleteProfile(p.id!)}>Löschen</button>
                                            </td>
                                        </tr>
                                    ))}
                                </>
                            );
                        })}
                    </tbody>
                </table>
            )}

            {activeTab === "gruppen" && (
                <table className="admin-table">
                    <thead><tr><th>ID</th><th>Name</th><th>Owner</th><th>Aktionen</th></tr></thead>
                    <tbody>
                        {groups.map(group => (
                            <>
                                <tr key={group.id}>
                                    <td>{group.id}</td><td>{group.name}</td><td>{group.owner}</td>
                                    <td className="admin-actions">
                                        <button className="admin-action-btn" onClick={() => handleExpandGroup(group.id)}>
                                            {expandedGroupId === group.id ? "Verbergen" : "Mitglieder"}
                                        </button>
                                        <button className="admin-delete-btn" onClick={() => handleDeleteGroup(group.id)}>Löschen</button>
                                    </td>
                                </tr>
                                {expandedGroupId === group.id && (groupMembers[group.id] ?? []).map(member => (
                                    <tr key={member.profileId} className="admin-member-row">
                                        <td></td><td>{member.name}</td><td>{member.groupRole}</td>
                                        <td className="admin-actions">
                                            <button className="admin-delete-btn" onClick={() => handleRemoveMember(group.id, member.profileId)}>Entfernen</button>
                                        </td>
                                    </tr>
                                ))}
                            </>
                        ))}
                    </tbody>
                </table>
            )}

            <ConfirmationDialog
                open={confirmAction !== null}
                title="Aktion bestätigen"
                message={confirmAction?.label ?? ""}
                confirmLabel="Ja, bestätigen"
                cancelLabel="Abbrechen"
                onConfirm={() => confirmAction?.onConfirm()}
                onCancel={() => setConfirmAction(null)}
            />
        </div>
    );
}

export default AdminPage;

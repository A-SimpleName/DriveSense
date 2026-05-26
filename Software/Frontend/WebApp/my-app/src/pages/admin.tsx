// pages/AdminPage.tsx
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
import "../styles/admin.css";

type Tab = "accounts" | "profile" | "gruppen";

function AdminPage() {
    const { profile } = useAuth();
    const navigate = useNavigate();
    const [activeTab, setActiveTab] = useState<Tab>("accounts");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const [accounts, setAccounts] = useState<AccountResponse[]>([]);
    const [profiles, setProfiles] = useState<Profile[]>([]);
    const [groups, setGroups] = useState<UserGroup[]>([]);
    const [groupMembers, setGroupMembers] = useState<{ [groupId: number]: GroupMember[] }>({});
    const [expandedGroupId, setExpandedGroupId] = useState<number | null>(null);

    useEffect(() => {
        if (profile?.role !== "ADMIN") {
            navigate("/");
        }
    }, [profile]);

    useEffect(() => {
        setLoading(true);
        setError(null);
        if (activeTab === "accounts") {
            adminGetAllAccounts()
                .then(data => setAccounts(data))
                .catch(err => setError(err.message))
                .finally(() => setLoading(false));
        } else if (activeTab === "profile") {
            Promise.all([adminGetAllProfiles(), adminGetAllAccounts()])
                .then(([profileData, accountData]) => {
                    setProfiles(profileData);
                    setAccounts(accountData);
                })
                .catch(err => setError(err.message))
                .finally(() => setLoading(false));
        } else if (activeTab === "gruppen") {
            adminGetAllGroups()
                .then(data => setGroups(data))
                .catch(err => setError(err.message))
                .finally(() => setLoading(false));
        }
    }, [activeTab]);

    const handleDeleteAccount = (id: number) => {
        adminDeleteAccount(id)
            .then(() => setAccounts(prev => prev.filter(a => a.id !== id)))
            .catch(err => setError(err.message));
    };

    const handleDeleteProfile = (id: number) => {
        adminDeleteProfile(id)
            .then(() => setProfiles(prev => prev.filter(p => p.id !== id)))
            .catch(err => setError(err.message));
    };

    const handleDeleteGroup = (id: number) => {
        adminDeleteGroup(id)
            .then(() => {
                setGroups(prev => prev.filter(g => g.id !== id));
                setExpandedGroupId(null);
            })
            .catch(err => setError(err.message));
    };

    const handleExpandGroup = (groupId: number) => {
        if (expandedGroupId === groupId) {
            setExpandedGroupId(null);
            return;
        }
        setExpandedGroupId(groupId);
        if (!groupMembers[groupId]) {
            adminGetGroupMembers(groupId)
                .then(members => setGroupMembers(prev => ({ ...prev, [groupId]: members })))
                .catch(err => setError(err.message));
        }
    };

    const handleRemoveMember = (groupId: number, profileId: number) => {
        adminRemoveMember(groupId, profileId)
            .then(() => setGroupMembers(prev => ({
                ...prev,
                [groupId]: prev[groupId].filter(m => m.profileId !== profileId)
            })))
            .catch(err => setError(err.message));
    };

    if (loading) return <p>Laden...</p>;
    if (error) return <p>Fehler: {error}</p>;

    return (
        <div>
            <h1>Admin Panel</h1>

            <div className="admin-tabs">
                <button
                    className={`admin-tab-btn ${activeTab === "accounts" ? "active" : ""}`}
                    onClick={() => setActiveTab("accounts")}
                >
                    Accounts
                </button>
                <button
                    className={`admin-tab-btn ${activeTab === "profile" ? "active" : ""}`}
                    onClick={() => setActiveTab("profile")}
                >
                    Profile
                </button>
                <button
                    className={`admin-tab-btn ${activeTab === "gruppen" ? "active" : ""}`}
                    onClick={() => setActiveTab("gruppen")}
                >
                    Gruppen
                </button>
            </div>

            {/* Accounts Tab */}
            {activeTab === "accounts" && (
                <table className="admin-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Vorname</th>
                            <th>Nachname</th>
                            <th>Email</th>
                            <th>Aktionen</th>
                        </tr>
                    </thead>
                    <tbody>
                        {accounts.map(account => (
                            <tr key={account.id}>
                                <td>{account.id}</td>
                                <td>{account.fname}</td>
                                <td>{account.lname}</td>
                                <td>{account.email}</td>
                                <td className="admin-actions">
                                    <button
                                        className="admin-delete-btn"
                                        onClick={() => handleDeleteAccount(account.id)}
                                    >
                                        Löschen
                                    </button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            )}

            {/* Profile Tab */}
            {activeTab === "profile" && (
                <table className="admin-table">
                    <thead>
                        <tr>
                            <th>Account</th>
                            <th>Profil ID</th>
                            <th>Name</th>
                            <th>Rolle</th>
                            <th>Aktionen</th>
                        </tr>
                    </thead>
                    <tbody>
                        {accounts.map(account => {
                            const accountProfiles = profiles.filter(p => p.account_id === account.id);
                            if (accountProfiles.length === 0) return null;
                            return (
                                <>
                                    {/* Account Header Zeile */}
                                    <tr key={`account-${account.id}`} style={{ background: "rgb(126, 132, 218)", color: "white" }}>
                                        <td colSpan={5} style={{ textAlign: "left", paddingLeft: "8px", fontWeight: "bold" }}>
                                            {account.fname} {account.lname} — {account.email}
                                        </td>
                                    </tr>
                                    {/* Profile des Accounts */}
                                    {accountProfiles.map(p => (
                                        <tr key={p.id} className="admin-member-row">
                                            <td></td>
                                            <td>{p.id}</td>
                                            <td>{p.name}</td>
                                            <td>{p.role}</td>
                                            <td className="admin-actions">
                                                <button
                                                    className="admin-delete-btn"
                                                    onClick={() => handleDeleteProfile(p.id!)}
                                                >
                                                    Löschen
                                                </button>
                                            </td>
                                        </tr>
                                    ))}
                                </>
                            );
                        })}
                    </tbody>
                </table>
            )}
            {/* Gruppen Tab */}
            {activeTab === "gruppen" && (
                <table className="admin-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Name</th>
                            <th>Owner</th>
                            <th>Aktionen</th>
                        </tr>
                    </thead>
                    <tbody>
                        {groups.map(group => (
                            <>
                                <tr key={group.id}>
                                    <td>{group.id}</td>
                                    <td>{group.name}</td>
                                    <td>{group.owner}</td>
                                    <td className="admin-actions">
                                        <button
                                            className="admin-action-btn"
                                            onClick={() => handleExpandGroup(group.id)}
                                        >
                                            {expandedGroupId === group.id ? "Verbergen" : "Mitglieder"}
                                        </button>
                                        <button
                                            className="admin-delete-btn"
                                            onClick={() => handleDeleteGroup(group.id)}
                                        >
                                            Löschen
                                        </button>
                                    </td>
                                </tr>
                                {expandedGroupId === group.id && (groupMembers[group.id] ?? []).map(member => (
                                    <tr key={member.profileId} className="admin-member-row">
                                        <td></td>
                                        <td>{member.name}</td>
                                        <td>{member.groupRole}</td>
                                        <td className="admin-actions">
                                            <button
                                                className="admin-delete-btn"
                                                onClick={() => handleRemoveMember(group.id, member.profileId)}
                                            >
                                                Entfernen
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </>
                        ))}
                    </tbody>
                </table>
            )}
        </div>
    );
}

export default AdminPage;
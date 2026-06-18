import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import type { GroupMember, UserGroup } from "../model/usergroup";
import { deleteMember, getGroupById, getGroupMembers, updateMemberRole } from "../services/groupService";
import { getCurrentProfile } from "../services/profileService";
import { Button } from "../components/button";
import { InviteMemberForm } from "../components/group/InviteMemberForm";
import { ProtocolAddForm } from "../components/Protocols/protocolAddForm";
import { ConfirmationDialog } from "../components/ConfirmationDialog";
import { TableSkeleton } from "../components/loadingSkeleton";
import "../styles/pageLayout.css";

const canRemove = (myRole: string, targetRole: string): boolean => {
    if (targetRole === "OWNER") return false;
    if (myRole === "OWNER") return true;
    if (myRole === "ADMIN") return targetRole === "MEMBER";
    return false;
};

const canChangeRole = (myRole: string, targetRole: string): boolean => {
    if (targetRole === "OWNER") return false;
    return myRole === "OWNER";
};

function GroupDetailPage() {
    const { id } = useParams();
    const navigate = useNavigate();
    const groupId = Number(id);

    const [loading, setLoading] = useState(true);
    const [loadError, setLoadError] = useState<string | null>(null);
    const [removeError, setRemoveError] = useState<string | null>(null);
    const [roleError, setRoleError] = useState<string | null>(null);

    const [group, setGroup] = useState<UserGroup | null>(null);
    const [members, setMembers] = useState<GroupMember[]>([]);
    const [currentProfileId, setCurrentProfileId] = useState<number | null>(null);
    const [showInviteForm, setShowInviteForm] = useState(false);
    const [showProtocolForm, setShowProtocolForm] = useState(false);
    const [confirmRemoveMember, setConfirmRemoveMember] = useState<{ profileId: number; message: string } | null>(null);

    useEffect(() => {
        setLoading(true);
        setLoadError(null);
        Promise.all([
            getGroupById(groupId),
            getGroupMembers(groupId),
            getCurrentProfile(),
        ])
            .then(([groupData, membersData, profile]) => {
                setGroup(groupData);
                setMembers(membersData);
                setCurrentProfileId(profile.id ?? null);
            })
            .catch(err => setLoadError(err?.message || "Fehler beim Laden"))
            .finally(() => setLoading(false));
    }, [groupId]);

    const myRole = members.find(m => m.profileId === currentProfileId)?.groupRole ?? "MEMBER";

    const handleRemove = (profileId: number) => {
        setRemoveError(null);
        deleteMember(groupId, profileId)
            .then(() => setMembers(prev => prev.filter(m => m.profileId !== profileId)))
            .catch(err => setRemoveError(err?.message || "Mitglied konnte nicht entfernt werden"));
    };

    const requestRemove = (profileId: number, message: string) => {
        setConfirmRemoveMember({ profileId, message });
    };

    const confirmRemove = () => {
        if (!confirmRemoveMember) return;
        handleRemove(confirmRemoveMember.profileId);
        setConfirmRemoveMember(null);
    };


    const handleUpdateRole = (profileId: number, currentRole: string) => {
        const groupRole = currentRole === "ADMIN" ? "MEMBER" : "ADMIN";
        setRoleError(null);
        updateMemberRole(groupId, profileId, groupRole)
            .then(() =>
                setMembers(prev =>
                    prev.map(m => m.profileId === profileId ? { ...m, groupRole } : m)
                )
            )
            .catch(err => setRoleError(err?.message || "Rolle konnte nicht geändert werden"));
    };

    if (loading) return <TableSkeleton rows={4} cols={3} />;

    if (loadError) return (
        <div>
            <div className="page-header">
                <h1>Gruppe</h1>
            </div>
            <p className="error-text">Fehler: {loadError}</p>
            <Button label="Erneut versuchen" onClick={() => window.location.reload()} />
        </div>
    );

    return (
        <div>
            <div className="page-header">
                <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                    <Button label="←" onClick={() => navigate("/groups")} title="Zurück zu Gruppen" />
                    <h1 style={{ margin: 0 }}>{group?.name}</h1>
                </div>
                <div className="page-header-actions">
                    {(myRole === "OWNER" || myRole === "ADMIN") && (
                        <Button label="Mitglied einladen" onClick={() => setShowInviteForm(true)} />
                    )}
                    <Button label="+ Gruppenprotokoll" onClick={() => setShowProtocolForm(true)} />
                </div>
            </div>

            {removeError && <p className="error-text" style={{ marginBottom: "8px" }}>{removeError}</p>}
            {roleError && <p className="error-text" style={{ marginBottom: "8px" }}>{roleError}</p>}

            <div className="page-toolbar">
                <span className="page-toolbar-left" style={{ fontSize: "13px", color: "var(--color-text-secondary)" }}>
                    {members.length} {members.length === 1 ? "Mitglied" : "Mitglieder"}
                </span>
            </div>

            <div>
                <table>
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Rolle</th>
                            <th>Aktionen</th>
                        </tr>
                    </thead>
                    <tbody>
                        {members.length === 0 ? (
                            <tr>
                                <td colSpan={3} className="page-empty">Keine Mitglieder vorhanden</td>
                            </tr>
                        ) : members.map(member => (
                            <tr key={member.profileId}>
                                <td>{member.name}</td>
                                <td>{member.groupRole}</td>
                                <td>
                                    <div style={{ display: "flex", gap: "8px" }}>
                                        {member.profileId !== currentProfileId && (
                                            <>
                                                {canRemove(myRole, member.groupRole) && (
                                                    <Button
                                                        label="Entfernen"
                                                        onClick={() => requestRemove(member.profileId, `Mitglied ${member.name} wirklich entfernen?`)}
                                                        stopPropagation
                                                    />
                                                )}
                                                {canChangeRole(myRole, member.groupRole) && (
                                                    <Button
                                                        label={member.groupRole === "ADMIN" ? "Zu Member" : "Zu Admin"}
                                                        onClick={() => handleUpdateRole(member.profileId, member.groupRole)}
                                                        stopPropagation
                                                    />
                                                )}
                                            </>
                                        )}
                                        {member.profileId === currentProfileId && myRole !== "OWNER" && (
                                            <Button
                                                label="Gruppe verlassen"
                                                onClick={() => requestRemove(member.profileId, "Gruppe wirklich verlassen?")}
                                                stopPropagation
                                            />
                                        )}
                                    </div>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            {showInviteForm && (
                <div
                    onClick={() => setShowInviteForm(false)}
                    style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.4)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 100 }}
                >
                    <div onClick={e => e.stopPropagation()}>
                        <InviteMemberForm groupId={groupId} onClose={() => setShowInviteForm(false)} />
                    </div>
                </div>
            )}

            {showProtocolForm && (
                <ProtocolAddForm
                    onClose={() => setShowProtocolForm(false)}
                    onSuccess={() => setShowProtocolForm(false)}
                    usergroupId={groupId}
                />
            )}

            <ConfirmationDialog
                open={confirmRemoveMember !== null}
                title="Löschen bestätigen"
                message={confirmRemoveMember?.message ?? "Soll die Aktion wirklich ausgeführt werden?"}
                confirmLabel="Ja, löschen"
                cancelLabel="Abbrechen"
                onConfirm={confirmRemove}
                onCancel={() => setConfirmRemoveMember(null)}
            />
        </div>
    );
}

export default GroupDetailPage;
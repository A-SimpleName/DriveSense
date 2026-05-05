import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import type { GroupMember, UserGroup } from "../model/usergroup";
import { deleteMember, getGroupById, getGroupMembers, updateMemberRole } from "../services/groupService";
import { getCurrentProfile } from "../services/profileService";
import { Button } from "../components/button";
import { InviteMemberForm } from "../components/group/InviteMemberForm";

// wer darf wen entfernen
const canRemove = (myRole: string, targetRole: string): boolean => {
    if (targetRole === "OWNER") return false;
    if (myRole === "OWNER") return true;
    if (myRole === "ADMIN") return targetRole === "MEMBER";
    return false;
};

// nur Owner darf Rollen ändern
const canChangeRole = (myRole: string, targetRole: string): boolean => {
    if (targetRole === "OWNER") return false;
    return myRole === "OWNER";
};
    
function GroupDetailPage() {
    const { id } = useParams();
    const groupId = Number(id);

    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [group, setGroup] = useState<UserGroup | null>(null);
    const [members, setMembers] = useState<GroupMember[]>([]);
    const [currentProfileId, setCurrentProfileId] = useState<number | null>(null);
    const [showInviteForm, setShowInviteForm] = useState(false);
    

    useEffect(() => {
        setLoading(true);
        setError(null);
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
            .catch(err => setError(err.message))
            .finally(() => setLoading(false));
    }, [groupId]);

    // eigene Rolle direkt aus Memberliste ableiten
    const myRole = members.find(m => m.profileId === currentProfileId)?.groupRole ?? "MEMBER";

    const handleRemove = (profileId: number) => {
        setError(null);
        deleteMember(profileId, groupId)
            .then(() => setMembers(prev => prev.filter(m => m.profileId !== profileId)))
            .catch(err => setError(err.message));
    };

    const handleUpdateRole = (profileId: number, currentRole: string) => {
        const newRole = currentRole === "ADMIN" ? "MEMBER" : "ADMIN";
        setError(null);
        updateMemberRole(profileId, groupId, newRole)
            .then(() =>
                setMembers(prev =>
                    prev.map(m =>
                        m.profileId === profileId ? { ...m, groupRole: newRole } : m
                    )
                )
            )
            .catch(err => setError(err.message));
    };

    if (loading) return <p>Laden...</p>;
    if (error) return <p>Fehler: {error}</p>;

    return (
        <div>
            <h2>{group?.name} - Mitglieder</h2>

            {(myRole === "OWNER" || myRole === "ADMIN") && (
                <Button label="Mitglied einladen" onClick={() => setShowInviteForm(true)} />
            )}

            {showInviteForm && (
                <div
                    onClick={() => setShowInviteForm(false)}
                    style={{
                        position: "fixed", inset: 0,
                        background: "rgba(0,0,0,0.4)",
                        display: "flex", alignItems: "center", justifyContent: "center",
                        zIndex: 100,
                    }}
                >
                    <div onClick={e => e.stopPropagation()}>
                        <InviteMemberForm
                            groupId={groupId}
                            onClose={() => setShowInviteForm(false)}
                        />
                    </div>
                </div>
            )}

            <table>
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Rolle</th>
                        <th>Aktionen</th>
                    </tr>
                </thead>
                <tbody>
                    {members.map(member => (
                        <tr key={member.profileId}>
                            <td>{member.name}</td>
                            <td>{member.groupRole}</td>
                            <td style={{ display: "flex", gap: "8px" }}>
                                {member.profileId !== currentProfileId && (
                                    <>
                                        {canRemove(myRole, member.groupRole) && (
                                            <Button
                                                label="Entfernen"
                                                onClick={() => handleRemove(member.profileId)}
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
                                        onClick={() => handleRemove(member.profileId)}
                                        stopPropagation
                                    />
                                )}
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
}

export default GroupDetailPage;
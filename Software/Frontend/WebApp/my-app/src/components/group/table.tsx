import { useEffect, useState } from "react";
import { deleteGroup, getGroups, updateGroup } from "../../services/groupService";
import { getCurrentProfile } from "../../services/profileService";
import type { UserGroup } from "../../model/usergroup";
import { useNavigate } from "react-router-dom";
import { Button } from "../button";
import { ConfirmationDialog } from "../ConfirmationDialog";
import { TableSkeleton } from "../loadingSkeleton";
import "../../styles/pageLayout.css";

interface Props {
    newGroup: UserGroup | null;
}

function GroupTable({ newGroup }: Props) {
    const navigate = useNavigate();
    const [groups, setGroups] = useState<UserGroup[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [currentProfileId, setCurrentProfileId] = useState<number | null>(null);
    const [editingGroupId, setEditingGroupId] = useState<number | null>(null);
    const [editName, setEditName] = useState("");
    const [saving, setSaving] = useState(false);
    const [confirmDeleteGroupId, setConfirmDeleteGroupId] = useState<number | null>(null);

    useEffect(() => {
        setLoading(true);
        Promise.all([getGroups(), getCurrentProfile()])
            .then(([groupsData, profile]) => {
                setGroups(groupsData);
                setCurrentProfileId(profile.id ?? null);
            })
            .catch(err => setError(err.message))
            .finally(() => setLoading(false));
    }, []);

    useEffect(() => {
        if (newGroup) setGroups(prev => [...prev, newGroup]);
    }, [newGroup]);

    const isOwner = (group: UserGroup) => group.ownerId === currentProfileId;

    const handleDelete = (groupId: number) => {
        setError(null);
        deleteGroup(groupId)
            .then(() => setGroups(prev => prev.filter(g => g.id !== groupId)))
            .catch(err => setError(err.message));
    };

    const confirmDelete = () => {
        if (confirmDeleteGroupId === null) return;
        handleDelete(confirmDeleteGroupId);
        setConfirmDeleteGroupId(null);
    };

    const handleEditStart = (group: UserGroup) => {
        setEditingGroupId(group.id);
        setEditName(group.name);
    };

    const handleEditSave = (groupId: number) => {
        if (!editName.trim()) return;
        setSaving(true);
        setError(null);
        updateGroup(groupId, editName.trim())
            .then(() => {
                setGroups(prev => prev.map(g => g.id === groupId ? { ...g, name: editName.trim() } : g));
                setEditingGroupId(null);
            })
            .catch(err => setError(err.message))
            .finally(() => setSaving(false));
    };

    const handleEditCancel = () => {
        setEditingGroupId(null);
        setEditName("");
    };

    if (loading) return <TableSkeleton rows={3} cols={3} />;

    return (
        <div>
            {error && <p style={{ color: "#dc2626", marginBottom: "12px" }}>{error}</p>}

            <div className="page-toolbar">
                <span className="page-toolbar-left" style={{ fontSize: "13px", color: "var(--color-text-secondary)" }}>
                    {groups.length} {groups.length === 1 ? "Gruppe" : "Gruppen"}
                </span>
            </div>

            <div className="page-table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Besitzer</th>
                            <th>Aktionen</th>
                        </tr>
                    </thead>
                    <tbody>
                        {groups.length === 0 ? (
                            <tr>
                                <td colSpan={3} className="page-empty">Keine Gruppen vorhanden</td>
                            </tr>
                        ) : groups.map(group => (
                            <tr
                                key={group.id}
                                onClick={() => editingGroupId !== group.id && navigate(`/groups/${group.id}`)}
                                style={{ cursor: editingGroupId !== group.id ? "pointer" : "default" }}
                            >
                                <td>
                                    {editingGroupId === group.id ? (
                                        <input
                                            type="text"
                                            value={editName}
                                            onChange={e => setEditName(e.target.value)}
                                            onKeyDown={e => {
                                                if (e.key === "Enter") handleEditSave(group.id);
                                                if (e.key === "Escape") handleEditCancel();
                                            }}
                                            onClick={e => e.stopPropagation()}
                                            autoFocus
                                        />
                                    ) : group.name}
                                </td>
                                <td>{group.owner}</td>
                                <td onClick={e => e.stopPropagation()}>
                                    {isOwner(group) && (
                                        <div style={{ display: "flex", gap: "8px" }}>
                                            {editingGroupId === group.id ? (
                                                <>
                                                    <Button label={saving ? "Speichern..." : "Speichern"} loading={saving} onClick={() => handleEditSave(group.id)} stopPropagation />
                                                    <Button label="Abbrechen" onClick={handleEditCancel} stopPropagation />
                                                </>
                                            ) : (
                                                <>
                                                    <Button label="Umbenennen" onClick={() => handleEditStart(group)} stopPropagation />
                                                    <Button label="Löschen" onClick={() => setConfirmDeleteGroupId(group.id)} stopPropagation />
                                                </>
                                            )}
                                        </div>
                                    )}
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            <ConfirmationDialog
                open={confirmDeleteGroupId !== null}
                title="Gruppe löschen"
                message="Soll diese Gruppe wirklich gelöscht werden? Diese Aktion kann nicht rückgängig gemacht werden."
                confirmLabel="Gruppe löschen"
                cancelLabel="Abbrechen"
                onConfirm={confirmDelete}
                onCancel={() => setConfirmDeleteGroupId(null)}
            />
        </div>
    );
}

export default GroupTable;
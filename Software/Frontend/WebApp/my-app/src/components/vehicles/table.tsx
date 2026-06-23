import { Fragment, useEffect, useState } from "react";
import { getAllVehicles, deleteVehicle, updateVehicle } from "../../services/vehicleService";
import type { CreateVehicle, Vehicle } from "../../model/vehicle";
import "../../styles/pageLayout.css";
import { Button } from "../button";
import { ActionMenu, type ActionMenuItem } from "../ActionMenu";
import { ConfirmationDialog } from "../ConfirmationDialog";
import { VehicleMembers } from "./VehicleMembers";
import { InviteVehicleMemberForm } from "./InviteVehicleMemberForm";
import { TableSkeleton } from "../loadingSkeleton";
import { Check, X } from "lucide-react";
import { useDragScroll } from "../../hooks/useDragScroll";

function VehiclesTable() {
    const [vehicles, setVehicles] = useState<Vehicle[]>([]);
    const [loading, setLoading] = useState(false);
    const [loadError, setLoadError] = useState<string | null>(null);

    const [editingId, setEditingId] = useState<number | null>(null);
    const [editData, setEditData] = useState<CreateVehicle | null>(null);
    const [saving, setSaving] = useState(false);
    const [saveError, setSaveError] = useState<{ id: number; message: string } | null>(null);

    const [deleteError, setDeleteError] = useState<string | null>(null);
    const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null);

    const [invitingVehicle, setInvitingVehicle] = useState<Vehicle | null>(null);

    const [membersVehicle, setMembersVehicle] = useState<Vehicle | null>(null);
    const [membersReloadKey, setMembersReloadKey] = useState(0);

    const dragScroll = useDragScroll<HTMLDivElement>();

    useEffect(() => {
        setLoading(true);
        getAllVehicles()
            .then(setVehicles)
            .catch(err => setLoadError(err?.message || "Fahrzeuge konnten nicht geladen werden"))
            .finally(() => setLoading(false));
    }, []);

    const handleEdit = (vehicle: Vehicle) => {
        setSaveError(null);
        setDeleteError(null);
        setInvitingVehicle(null);
        setEditingId(vehicle.id);
        setEditData({ model: vehicle.model, licensePlate: vehicle.licensePlate, mileage: vehicle.mileage });
    };

    const handleCancel = () => {
        setEditingId(null);
        setEditData(null);
        setSaveError(null);
    };

    const handleSave = (id: number) => {
        if (!editData) return;
        setSaving(true);
        setSaveError(null);
        updateVehicle(id, editData)
            .then(() => {
                setVehicles(prev => prev.map(v => v.id === id ? { ...v, ...editData } : v));
                handleCancel();
            })
            .catch(err => setSaveError({ id, message: err?.message || "Speichern fehlgeschlagen" }))
            .finally(() => setSaving(false));
    };

    const handleKeyDown = (e: React.KeyboardEvent, id: number) => {
        if (e.key === "Enter") handleSave(id);
        if (e.key === "Escape") handleCancel();
    };

    const handleDelete = (id: number) => {
        setDeleteError(null);
        deleteVehicle(id)
            .then(() => setVehicles(prev => prev.filter(v => v.id !== id)))
            .catch(err => setDeleteError(err?.message || "Löschen fehlgeschlagen"));
    };

    const confirmDelete = () => {
        if (confirmDeleteId === null) return;
        handleDelete(confirmDeleteId);
        setConfirmDeleteId(null);
    };

    const openInvite = (vehicle: Vehicle) => {
        setEditingId(null);
        setDeleteError(null);
        setInvitingVehicle(vehicle);
    };

    if (loading) return <TableSkeleton rows={3} cols={6} />;
    if (loadError) return <p className="error-text">{loadError}</p>;

    return (
        <div>
            {deleteError && <p className="error-text" style={{ marginBottom: "12px" }}>{deleteError}</p>}

            <div className="page-toolbar">
                <span className="page-toolbar-left" style={{ fontSize: "13px", color: "var(--color-text-secondary)" }}>
                    {vehicles.length} {vehicles.length === 1 ? "Fahrzeug" : "Fahrzeuge"}
                </span>
            </div>

            <div
                ref={dragScroll.ref}
                className="page-table-wrapper--scrollable"
                {...dragScroll.handlers}
            >
                <table>
                    <thead>
                        <tr>
                            <th>Modell</th>
                            <th>Profil</th>
                            <th>Account</th>
                            <th>Kennzeichen</th>
                            <th>Kilometerstand</th>
                            <th>Aktionen</th>
                        </tr>
                    </thead>
                    <tbody>
                        {vehicles.length === 0 ? (
                            <tr>
                                <td colSpan={6} className="page-empty">Keine Fahrzeuge vorhanden</td>
                            </tr>
                        ) : vehicles.map(vehicle => {
                            const canEdit = vehicle.myRole === "OWNER" || vehicle.myRole === "CO_OWNER";
                            const canDelete = vehicle.myRole === "OWNER";
                            const canInvite = vehicle.myRole === "OWNER" || vehicle.myRole === "CO_OWNER";
                            const canInviteCoOwner = vehicle.myRole === "OWNER";

                            return (
                                <Fragment key={vehicle.id}>
                                    <tr>
                                        <td>
                                            {editingId === vehicle.id ? (
                                                <input
                                                    value={editData?.model ?? ""}
                                                    onChange={e => setEditData(prev => prev ? { ...prev, model: e.target.value } : prev)}
                                                    onKeyDown={e => handleKeyDown(e, vehicle.id)}
                                                />
                                            ) : vehicle.model}
                                        </td>
                                        <td>{vehicle.ownerProfileName}</td>
                                        <td>{vehicle.ownerAccountName}</td>
                                        <td>
                                            {editingId === vehicle.id ? (
                                                <input
                                                    value={editData?.licensePlate ?? ""}
                                                    onChange={e => setEditData(prev => prev ? { ...prev, licensePlate: e.target.value } : prev)}
                                                    onKeyDown={e => handleKeyDown(e, vehicle.id)}
                                                />
                                            ) : vehicle.licensePlate}
                                        </td>
                                        <td>
                                            {editingId === vehicle.id ? (
                                                <input
                                                    type="number"
                                                    value={editData?.mileage ?? 0}
                                                    onChange={e => setEditData(prev => prev ? { ...prev, mileage: Number(e.target.value) } : prev)}
                                                    onKeyDown={e => handleKeyDown(e, vehicle.id)}
                                                />
                                            ) : `${vehicle.mileage} km`}
                                        </td>
                                        <td>
                                            {editingId === vehicle.id ? (
                                                <div style={{ display: "flex", gap: "8px" }}>
                                                    <Button label={saving ? "Speichert..." : "Speichern"} loading={saving} onClick={() => handleSave(vehicle.id)} icon={<Check size={18} />} />
                                                    <Button label="Abbrechen" onClick={handleCancel} icon={<X size={18} />} />
                                                </div>
                                            ) : (() => {
                                                const actions: ActionMenuItem[] = [
                                                    ...(canEdit ? [{ label: "Bearbeiten", onClick: () => handleEdit(vehicle) }] : []),
                                                    ...(canInvite ? [{ label: "Einladen", onClick: () => openInvite(vehicle) }] : []),
                                                    { label: "Mitglieder", onClick: () => setMembersVehicle(vehicle) },
                                                    ...(canDelete ? [{ label: "Löschen", onClick: () => setConfirmDeleteId(vehicle.id), danger: true }] : [])
                                                ];
                                                return <ActionMenu items={actions} />;
                                            })()}
                                        </td>
                                    </tr>

                                    {invitingVehicle?.id === vehicle.id && (
                                        <InviteVehicleMemberForm
                                            vehicleId={vehicle.id}
                                            vehicleLabel={vehicle.model}
                                            canInviteCoOwner={canInviteCoOwner}
                                            onClose={() => setInvitingVehicle(null)}
                                            onInvited={() => {
                                                // Falls die Mitgliederliste für genau dieses Fahrzeug
                                                // gerade offen ist, sofort neu laden statt erst beim
                                                // nächsten Öffnen
                                                if (membersVehicle?.id === vehicle.id) {
                                                    setMembersReloadKey(prev => prev + 1);
                                                }
                                            }}
                                        />
                                    )}

                                    {saveError?.id === vehicle.id && (
                                        <tr key={`${vehicle.id}-error`}>
                                            <td colSpan={6} className="error-text" style={{ fontSize: "0.85rem", padding: "4px 8px" }}>
                                                {saveError.message}
                                            </td>
                                        </tr>
                                    )}
                                </Fragment>
                            );
                        })}
                    </tbody>
                </table>
            </div>

            <ConfirmationDialog
                open={confirmDeleteId !== null}
                title="Fahrzeug löschen"
                message="Wirklich löschen?"
                confirmLabel="Löschen"
                cancelLabel="Abbrechen"
                onConfirm={confirmDelete}
                onCancel={() => setConfirmDeleteId(null)}
            />

            {membersVehicle && (
                <VehicleMembers
                    vehicle={membersVehicle}
                    onClose={() => setMembersVehicle(null)}
                    onLeft={() => setVehicles(prev => prev.filter(v => v.id !== membersVehicle.id))}
                    reloadToken={membersReloadKey}
                />
            )}
        </div>
    );
}

export default VehiclesTable;
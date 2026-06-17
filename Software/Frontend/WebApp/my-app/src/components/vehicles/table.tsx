import { Fragment, useEffect, useState } from "react";
import { getAllVehicles, deleteVehicle, updateVehicle, inviteToVehicle } from "../../services/vehicleService";
import type { CreateVehicle, Vehicle } from "../../model/vehicle";
import "../../styles/pageLayout.css";
import { Button } from "../button";
import { ConfirmationDialog } from "../ConfirmationDialog";
import { VehicleMembers } from "./VehicleMembers";
import { AddForm } from "../addForm";
import { TableSkeleton } from "../loadingSkeleton";

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
    const [inviteError, setInviteError] = useState<{ id: number; message: string } | null>(null);

    const [membersVehicle, setMembersVehicle] = useState<Vehicle | null>(null);

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
        setInviteError(null);
    };

    const handleInviteSend = async (vehicle: Vehicle, email: string, role: "DRIVER" | "CO_OWNER") => {
        if (!email.trim()) return;
        try {
            await inviteToVehicle(vehicle.id, email, role);
            setInvitingVehicle(null);
        } catch (err: any) {
            setInviteError({ id: vehicle.id, message: err?.message || "Einladung fehlgeschlagen" });
        }
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

            <div className="page-table-wrapper">
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
                                            <div style={{ display: "flex", gap: "8px" }}>
                                                {editingId === vehicle.id ? (
                                                    <>
                                                        <Button label={saving ? "Speichert..." : "Speichern"} loading={saving} onClick={() => handleSave(vehicle.id)} />
                                                        <Button label="Abbrechen" onClick={handleCancel} />
                                                    </>
                                                ) : (
                                                    <>
                                                        {canEdit && <Button label="Bearbeiten" onClick={() => handleEdit(vehicle)} />}
                                                        {canInvite && <Button label="Einladen" onClick={() => openInvite(vehicle)} />}
                                                        <Button label="Mitglieder" onClick={() => setMembersVehicle(vehicle)} />
                                                        {canDelete && <Button label="Löschen" onClick={() => setConfirmDeleteId(vehicle.id)} />}
                                                    </>
                                                )}
                                            </div>
                                        </td>
                                    </tr>

                                    {invitingVehicle?.id === vehicle.id && (
                                        <AddForm
                                            title={`Mitglied zu ${vehicle.model} einladen`}
                                            submitLabel="Einladung senden"
                                            onClose={() => setInvitingVehicle(null)}
                                            fields={[
                                                { type: "text", key: "email", label: "E-Mail", defaultValue: "" },
                                                ...(canInviteCoOwner ? [{
                                                    type: "select" as const,
                                                    key: "role",
                                                    label: "Rolle",
                                                    defaultValue: "DRIVER",
                                                    options: [
                                                        { label: "Driver", value: "DRIVER" },
                                                        { label: "Co Owner", value: "CO_OWNER" }
                                                    ]
                                                }] : [])
                                            ]}
                                            onSubmit={async values => {
                                                await handleInviteSend(vehicle, String(values.email), (values.role as "DRIVER" | "CO_OWNER") ?? "DRIVER");
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

                                    {inviteError?.id === vehicle.id && (
                                        <tr key={`${vehicle.id}-invite-error`}>
                                            <td colSpan={6} className="error-text" style={{ fontSize: "0.85rem", padding: "4px 8px" }}>
                                                {inviteError.message}
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
                <VehicleMembers vehicle={membersVehicle} onClose={() => setMembersVehicle(null)} />
            )}
        </div>
    );
}

export default VehiclesTable;
import { useEffect, useState } from "react"
import { getAllVehicles, deleteVehicle, updateVehicle, inviteToVehicle } from "../../services/vehicleService"
import type { CreateVehicle, Vehicle } from "../../model/vehicle"
import "../../styles/table.css"
import { Button } from "../button"
import { ConfirmationDialog } from "../ConfirmationDialog"
import { VehicleMembers } from "./VehicleMembers"

function VehiclesTable() {
    const [vehicles, setVehicles] = useState<Vehicle[]>([])
    const [loading, setLoading] = useState(false)
    const [loadError, setLoadError] = useState<string | null>(null)

    // Bearbeiten
    const [editingId, setEditingId] = useState<number | null>(null)
    const [editData, setEditData] = useState<CreateVehicle | null>(null)
    const [saving, setSaving] = useState(false)
    const [saveError, setSaveError] = useState<{ id: number; message: string } | null>(null)

    // Löschen
    const [deleteError, setDeleteError] = useState<string | null>(null)
    const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null)

    // Einladen
    const [invitingId, setInvitingId] = useState<number | null>(null)
    const [inviteEmail, setInviteEmail] = useState("")
    const [inviteRole, setInviteRole] = useState<"CO_OWNER" | "DRIVER">("DRIVER")
    const [inviting, setInviting] = useState(false)
    const [inviteError, setInviteError] = useState<{ id: number; message: string } | null>(null)

    // Mitglieder-Detailansicht
    const [membersVehicle, setMembersVehicle] = useState<Vehicle | null>(null)

    useEffect(() => {
        setLoading(true)
        getAllVehicles()
            .then(setVehicles)
            .catch(err => setLoadError(err?.message || "Fahrzeuge konnten nicht geladen werden"))
            .finally(() => setLoading(false))
    }, [])

    // ── Bearbeiten ───────────────────────────────────────────────────────────

    const handleEdit = (vehicle: Vehicle) => {
        setSaveError(null)
        setDeleteError(null)
        closeInvite()
        setEditingId(vehicle.id)
        setEditData({ model: vehicle.model, licensePlate: vehicle.licensePlate, mileage: vehicle.mileage })
    }

    const handleCancel = () => {
        setEditingId(null)
        setEditData(null)
        setSaveError(null)
    }

    const handleSave = (id: number) => {
        if (!editData) return
        setSaving(true)
        setSaveError(null)
        updateVehicle(id, editData)
            .then(() => {
                setVehicles(prev => prev.map(v => v.id === id ? { ...v, ...editData } : v))
                handleCancel()
            })
            .catch(err => setSaveError({ id, message: err?.message || "Speichern fehlgeschlagen" }))
            .finally(() => setSaving(false))
    }

    const handleKeyDown = (e: React.KeyboardEvent, id: number) => {
        if (e.key === "Enter") handleSave(id)
        if (e.key === "Escape") handleCancel()
    }

    // ── Löschen ──────────────────────────────────────────────────────────────

    const handleDelete = (id: number) => {
        setDeleteError(null)
        deleteVehicle(id)
            .then(() => setVehicles(prev => prev.filter(v => v.id !== id)))
            .catch(err => setDeleteError(err?.message || "Fahrzeug konnte nicht gelöscht werden"))
    }

    const confirmDelete = () => {
        if (confirmDeleteId === null) return
        handleDelete(confirmDeleteId)
        setConfirmDeleteId(null)
    }

    // ── Einladen ─────────────────────────────────────────────────────────────

    const openInvite = (vehicle: Vehicle) => {
        handleCancel()
        setDeleteError(null)
        setInvitingId(vehicle.id)
        setInviteEmail("")
        setInviteRole("DRIVER")
        setInviteError(null)
    }

    const closeInvite = () => {
        setInvitingId(null)
        setInviteEmail("")
        setInviteRole("DRIVER")
        setInviteError(null)
    }

    const handleInviteSend = (vehicle: Vehicle) => {
        if (!inviteEmail.trim()) return
        setInviting(true)
        setInviteError(null)
        inviteToVehicle(vehicle.id, inviteEmail, inviteRole)
            .then(() => closeInvite())
            .catch(err => setInviteError({ id: vehicle.id, message: err?.message || "Einladung fehlgeschlagen" }))
            .finally(() => setInviting(false))
    }

    const handleInviteKeyDown = (e: React.KeyboardEvent, vehicle: Vehicle) => {
        if (e.key === "Enter") handleInviteSend(vehicle)
        if (e.key === "Escape") closeInvite()
    }

    // ── Render ───────────────────────────────────────────────────────────────

    if (loading) return <p>Laden...</p>
    if (loadError) return <p style={{ color: "#dc2626" }}>Fehler: {loadError}</p>

    return (
        <div>
            {deleteError && (
                <p style={{ color: "#dc2626", marginBottom: "12px" }}>{deleteError}</p>
            )}

            <table>
                <thead>
                    <tr>
                        <th>Model</th>
                        <th>Profil</th>
                        <th>Account</th>
                        <th>Kennzeichen</th>
                        <th>Kilometerstand</th>
                        <th>Aktionen</th>
                    </tr>
                </thead>

                <tbody>
                    {vehicles.map(vehicle => {
                        const canEdit          = vehicle.myRole === "OWNER" || vehicle.myRole === "CO_OWNER"
                        const canDelete        = vehicle.myRole === "OWNER"
                        const canInvite        = vehicle.myRole === "OWNER" || vehicle.myRole === "CO_OWNER"
                        const canInviteCoOwner = vehicle.myRole === "OWNER"
                        // Mitglieder sehen dürfen OWNER und CO_OWNER
                        const canSeeMembers    = vehicle.myRole === "OWNER" || vehicle.myRole === "CO_OWNER"

                        return (
                            <>
                                <tr key={vehicle.id}>
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
                                            <>
                                                <Button label={saving ? "Speichert..." : "Speichern"} onClick={() => handleSave(vehicle.id)} />
                                                <Button label="Abbrechen" onClick={handleCancel} />
                                            </>
                                        ) : invitingId === vehicle.id ? (
                                            <>
                                                <Button label="Abbrechen" onClick={closeInvite} />
                                            </>
                                        ) : (
                                            <>
                                                {canEdit       && <Button label="Bearbeiten" stopPropagation onClick={() => handleEdit(vehicle)} />}
                                                {canInvite     && <Button label="Einladen"   stopPropagation onClick={() => openInvite(vehicle)} />}
                                                {canSeeMembers && <Button label="Mitglieder" stopPropagation onClick={() => setMembersVehicle(vehicle)} />}
                                                {canDelete     && <Button label="Löschen"    stopPropagation onClick={() => setConfirmDeleteId(vehicle.id)} />}
                                            </>
                                        )}
                                    </td>
                                </tr>

                                {/* Inline-Einladungsformular */}
                                {invitingId === vehicle.id && (
                                    <tr key={`${vehicle.id}-invite`}>
                                        <td colSpan={6} style={{ padding: "8px" }}>
                                            <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
                                                <input
                                                    type="email"
                                                    placeholder="E-Mail-Adresse"
                                                    value={inviteEmail}
                                                    onChange={e => setInviteEmail(e.target.value)}
                                                    onKeyDown={e => handleInviteKeyDown(e, vehicle)}
                                                    style={{ flex: 1, minWidth: 200 }}
                                                />
                                                {/* Rollenauswahl nur für OWNER – CO_OWNER kann nur DRIVER einladen */}
                                                {canInviteCoOwner && (
                                                    <select
                                                        value={inviteRole}
                                                        onChange={e => setInviteRole(e.target.value as "CO_OWNER" | "DRIVER")}
                                                    >
                                                        <option value="DRIVER">DRIVER</option>
                                                        <option value="CO_OWNER">CO_OWNER</option>
                                                    </select>
                                                )}
                                                <Button
                                                    label={inviting ? "Sende..." : "Einladung senden"}
                                                    onClick={() => handleInviteSend(vehicle)}
                                                />
                                            </div>
                                            {inviteError?.id === vehicle.id && (
                                                <p style={{ color: "#dc2626", fontSize: "0.85rem", margin: "4px 0 0" }}>
                                                    {inviteError.message}
                                                </p>
                                            )}
                                        </td>
                                    </tr>
                                )}

                                {/* Speichern-Fehler */}
                                {saveError?.id === vehicle.id && (
                                    <tr key={`${vehicle.id}-error`}>
                                        <td colSpan={6} style={{ color: "#dc2626", fontSize: "0.85rem", padding: "4px 8px" }}>
                                            {saveError.message}
                                        </td>
                                    </tr>
                                )}
                            </>
                        )
                    })}
                </tbody>
            </table>

            <ConfirmationDialog
                open={confirmDeleteId !== null}
                title="Fahrzeug löschen"
                message="Möchtest du dieses Fahrzeug wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden."
                confirmLabel="Fahrzeug löschen"
                cancelLabel="Abbrechen"
                onConfirm={confirmDelete}
                onCancel={() => setConfirmDeleteId(null)}
            />

            {membersVehicle && (
                <VehicleMembers
                    vehicle={membersVehicle}
                    onClose={() => setMembersVehicle(null)}
                />
            )}
        </div>
    )
}

export default VehiclesTable
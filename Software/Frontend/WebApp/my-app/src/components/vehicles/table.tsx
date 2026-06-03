import { useEffect, useState } from "react"
import { getAllVehicles, deleteVehicle, updateVehicle } from "../../services/vehicleService"
import type { CreateVehicle, Vehicle } from "../../model/vehicle"
import "../../styles/table.css"
import { Button } from "../button"
import { ConfirmationDialog } from "../ConfirmationDialog"

function VehiclesTable() {
    const [vehicles, setVehicles] = useState<Vehicle[]>([])
    const [editingId, setEditingId] = useState<number | null>(null)
    const [editData, setEditData] = useState<CreateVehicle | null>(null)
    const [loading, setLoading] = useState(false)
    const [saving, setSaving] = useState(false)
    const [loadError, setLoadError] = useState<string | null>(null)
    // Getrennte Fehler: Speichern pro Zeile, Löschen global
    const [saveError, setSaveError] = useState<{ id: number; message: string } | null>(null)
    const [deleteError, setDeleteError] = useState<string | null>(null)
    const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null)

    useEffect(() => {
        setLoading(true)
        getAllVehicles()
            .then(setVehicles)
            .catch(err => setLoadError(err?.message || "Fahrzeuge konnten nicht geladen werden"))
            .finally(() => setLoading(false))
    }, [])

    const handleEdit = (vehicle: Vehicle) => {
        setSaveError(null)
        setDeleteError(null)
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
            // Fehler direkt an die Zeile binden, nicht global
            .catch(err => setSaveError({ id, message: err?.message || "Speichern fehlgeschlagen" }))
            .finally(() => setSaving(false))
    }

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

    const handleKeyDown = (e: React.KeyboardEvent, id: number) => {
        if (e.key === "Enter") handleSave(id)
        if (e.key === "Escape") handleCancel()
    }

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
                        const canEdit = vehicle.myRole === "OWNER" || vehicle.myRole === "CO_OWNER"
                        const canDelete = vehicle.myRole === "OWNER"

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
                                        ) : (
                                            <>
                                                {canEdit && <Button label="Bearbeiten" stopPropagation onClick={() => handleEdit(vehicle)} />}
                                                {canDelete && <Button label="Löschen" stopPropagation onClick={() => setConfirmDeleteId(vehicle.id)} />}
                                            </>
                                        )}
                                    </td>
                                </tr>

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
        </div>
    )
}

export default VehiclesTable
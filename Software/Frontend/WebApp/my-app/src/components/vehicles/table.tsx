import { useEffect, useState } from "react"
import { getAllVehicles, deleteVehicle, updateVehicle } from "../../services/vehicleService"
import type { CreateVehicle, Vehicle } from "../../model/vehicle"
import "../../styles/table.css"
import { Button } from "../button"

function VehiclesTable() {
    const [vehicles, setVehicles] = useState<Vehicle[]>([])
    const [editingId, setEditingId] = useState<number | null>(null)
    const [editData, setEditData] = useState<CreateVehicle | null>(null)

    const [loading, setLoading] = useState(false)
    const [saving, setSaving] = useState(false)
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        setLoading(true)
        getAllVehicles()
            .then(setVehicles)
            .catch(err => setError(err.message))
            .finally(() => setLoading(false))
    }, [])

    const handleEdit = (vehicle: Vehicle) => {
        setError(null)
        setEditingId(vehicle.id)
        setEditData({
            model: vehicle.model,
            licensePlate: vehicle.licensePlate,
            mileage: vehicle.mileage
        })
    }

    const handleCancel = () => {
        setEditingId(null)
        setEditData(null)
    }

    const handleSave = (id: number) => {
        if (!editData) return

        setSaving(true)
        setError(null)

        updateVehicle(id, editData)
            .then(() => {
                setVehicles(prev =>
                    prev.map(v =>
                        v.id === id ? { ...v, ...editData } : v
                    )
                )
                handleCancel()
            })
            .catch(err => setError(err.message))
            .finally(() => setSaving(false))
    }

    const handleDelete = (id: number) => {
        setError(null)

        deleteVehicle(id)
            .then(() =>
                setVehicles(prev => prev.filter(v => v.id !== id))
            )
            .catch(err => setError(err.message))
    }

    const handleKeyDown = (e: React.KeyboardEvent, id: number) => {
        if (e.key === "Enter") {
            handleSave(id)
        }

        if (e.key === "Escape") {
            handleCancel()
        }
    }

    if (loading) return <p>Laden...</p>

    return (
        <div>
            {error && <p style={{ color: "red" }}>{error}</p>}

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
                        const canEdit =
                            vehicle.myRole === "OWNER" ||
                            vehicle.myRole === "CO_OWNER"

                        const canDelete =
                            vehicle.myRole === "OWNER"

                        return (
                            <tr key={vehicle.id}>
                                {/* MODEL */}
                                <td>
                                    {editingId === vehicle.id ? (
                                        <input
                                            value={editData?.model ?? ""}
                                            onChange={e =>
                                                setEditData(prev =>
                                                    prev
                                                        ? {
                                                            ...prev,
                                                            model: e.target.value
                                                        }
                                                        : prev
                                                )
                                            }
                                            onKeyDown={e =>
                                                handleKeyDown(e, vehicle.id)
                                            }
                                        />
                                    ) : (
                                        vehicle.model
                                    )}
                                </td>

                                {/* PROFILE */}
                                <td>{vehicle.ownerProfileName}</td>

                                {/* ACCOUNT */}
                                <td>{vehicle.ownerAccountName}</td>

                                {/* LICENSE */}
                                <td>
                                    {editingId === vehicle.id ? (
                                        <input
                                            value={editData?.licensePlate ?? ""}
                                            onChange={e =>
                                                setEditData(prev =>
                                                    prev
                                                        ? {
                                                            ...prev,
                                                            licensePlate:
                                                                e.target.value
                                                        }
                                                        : prev
                                                )
                                            }
                                            onKeyDown={e =>
                                                handleKeyDown(e, vehicle.id)
                                            }
                                        />
                                    ) : (
                                        vehicle.licensePlate
                                    )}
                                </td>

                                {/* MILEAGE */}
                                <td>
                                    {editingId === vehicle.id ? (
                                        <input
                                            type="number"
                                            value={editData?.mileage ?? 0}
                                            onChange={e =>
                                                setEditData(prev =>
                                                    prev
                                                        ? {
                                                            ...prev,
                                                            mileage: Number(
                                                                e.target.value
                                                            )
                                                        }
                                                        : prev
                                                )
                                            }
                                            onKeyDown={e =>
                                                handleKeyDown(e, vehicle.id)
                                            }
                                        />
                                    ) : (
                                        `${vehicle.mileage} km`
                                    )}
                                </td>

                                {/* ACTIONS */}
                                <td>
                                    {editingId === vehicle.id ? (
                                        <>
                                            <Button
                                                label={
                                                    saving
                                                        ? "Speichert..."
                                                        : "Speichern"
                                                }
                                                onClick={() =>
                                                    handleSave(vehicle.id)
                                                }
                                            />
                                            <Button
                                                label="Abbrechen"
                                                onClick={handleCancel}
                                            />
                                        </>
                                    ) : (
                                        <>
                                            {canEdit && (
                                                <Button
                                                    label="Bearbeiten"
                                                    stopPropagation={true}
                                                    onClick={() =>
                                                        handleEdit(vehicle)
                                                    }
                                                />
                                            )}

                                            {canDelete && (
                                                <Button
                                                    label="Löschen"
                                                    stopPropagation={true}
                                                    onClick={() =>
                                                        handleDelete(vehicle.id)
                                                    }
                                                />
                                            )}
                                        </>
                                    )}
                                </td>
                            </tr>
                        )
                    })}
                </tbody>
            </table>
        </div>
    )
}

export default VehiclesTable
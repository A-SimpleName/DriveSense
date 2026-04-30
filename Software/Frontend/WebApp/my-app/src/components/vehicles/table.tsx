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
            .then(data => setVehicles(data))
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
                    prev.map(v => (v.id === id ? { ...v, ...editData } : v))
                )
                handleCancel()
            })
            .catch(err => setError(err.message))
            .finally(() => setSaving(false))
    }

    const handleDelete = (id: number) => {
        setError(null)
        deleteVehicle(id)
            .then(() => setVehicles(prev => prev.filter(v => v.id !== id)))
            .catch(err => setError(err.message))
    }

    if (loading) return <p>Laden...</p>

    return (
        <div>
            {error && <p style={{ color: "red" }}>Fehler: {error}</p>}
            <table>
                <thead>
                    <tr>
                        <th>Model</th>
                        <th>Profil</th>
                        <th>Kennzeichen</th>
                        <th>Kilometerstand</th>
                        <th>Aktionen</th>
                    </tr>
                </thead>
                <tbody>
                    {vehicles.map(vehicle => (
                        <tr key={vehicle.id}>
                            <td>
                                {editingId === vehicle.id ? (
                                    <input
                                        value={editData?.model ?? ""}
                                        onChange={e =>
                                            setEditData(prev => prev ? { ...prev, model: e.target.value } : prev)
                                        }
                                    />
                                ) : (
                                    vehicle.model
                                )}
                            </td>

                            <td>{vehicle.profileName}</td>

                            <td>
                                {editingId === vehicle.id ? (
                                    <input
                                        value={editData?.licensePlate ?? ""}
                                        onChange={e =>
                                            setEditData(prev => prev ? { ...prev, licensePlate: e.target.value } : prev)
                                        }
                                    />
                                ) : (
                                    vehicle.licensePlate
                                )}
                            </td>

                            <td>
                                {editingId === vehicle.id ? (
                                    <input
                                        type="number"
                                        value={editData?.mileage ?? 0}
                                        onChange={e =>
                                            setEditData(prev => prev ? { ...prev, mileage: Number(e.target.value) } : prev)
                                        }
                                    />
                                ) : (
                                    `${vehicle.mileage} km`
                                )}
                            </td>

                            <td>
                                {editingId === vehicle.id ? (
                                    <>
                                        <Button
                                            label={saving ? "Speichert..." : "Speichern"}
                                            onClick={() => handleSave(vehicle.id)}
                                        />
                                        <Button label="Abbrechen" onClick={handleCancel} />
                                    </>
                                ) : (
                                    <>
                                        <Button
                                            label="Bearbeiten"
                                            stopPropagation={true}
                                            onClick={() => handleEdit(vehicle)}
                                        />
                                        <Button
                                            label="Löschen"
                                            stopPropagation={true}
                                            onClick={() => handleDelete(vehicle.id)}
                                        />
                                    </>
                                )}
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    )
}

export default VehiclesTable
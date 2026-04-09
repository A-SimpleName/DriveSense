import { useEffect, useState } from "react"
import { getAllVehicles, deleteVehicle, updateVehicle } from "../../services/vehicleService"
import type { CreateVehicle, Vehicle } from "../../model/vehicle"
import "../../styles/table.css"
import { Button } from "../button"

function VehiclesTable() {
    const [vehicles, setVehicles] = useState<Vehicle[]>([])
    const [editingId, setEditingId] = useState<number | null>(null)
    const [editData, setEditData] = useState<CreateVehicle | null>(null)

    const [loading, setLoading] = useState(true)
    const [saving, setSaving] = useState(false)
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        setLoading(true);
        getAllVehicles()
            .then(data => setVehicles(data))
            .catch(err => setError(err?.message || "Fehler beim Laden der Fahrzeuge"))
            .finally(() => setLoading(false));
    }, []);

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

    const handleSave = async (id: number) => {
        if (!editData) return;

        if (!editData.model || !editData.licensePlate) {
            setError("Bitte alle Felder ausfüllen");
            return;
        }

        setSaving(true);
        setError(null);

        try {
            await updateVehicle(id, editData);
            setVehicles(prev =>
                prev.map(v => (v.id === id ? { ...v, ...editData } : v))
            );
            handleCancel();
        } catch (err: any) {
            setError(err?.message || "Fehler beim Speichern");
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async (id: number) => {
        setError(null);

        try {
            await deleteVehicle(id);
            setVehicles(prev => prev.filter(v => v.id !== id));
        } catch (err: any) {
            setError(err?.message || "Fehler beim Löschen");
        }
    };

    if (loading) return <p>Laden...</p>

    return (
        <div>
            {error && <p>Fehler: {error}</p>}

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
                            {/* MODEL */}
                            <td>
                                {editingId === vehicle.id ? (
                                    <input
                                        value={editData?.model ?? ""}
                                        onChange={e =>
                                            setEditData(prev =>
                                                prev ? { ...prev, model: e.target.value } : prev
                                            )
                                        }
                                    />
                                ) : (
                                    vehicle.model
                                )}
                            </td>

                            <td>{vehicle.profileName}</td>

                            {/* LICENSE */}
                            <td>
                                {editingId === vehicle.id ? (
                                    <input
                                        value={editData?.licensePlate ?? ""}
                                        onChange={e =>
                                            setEditData(prev =>
                                                prev
                                                    ? { ...prev, licensePlate: e.target.value }
                                                    : prev
                                            )
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
                                                          mileage: Number(e.target.value)
                                                      }
                                                    : prev
                                            )
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
                                            label="Speichern"
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
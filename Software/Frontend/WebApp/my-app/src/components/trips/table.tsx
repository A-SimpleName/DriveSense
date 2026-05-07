import { useEffect, useState } from "react"
import { useNavigate } from "react-router-dom"
import { deleteTrip, getAllTrips, updateTrip } from "../../services/tripService"
import { getAllVehicles } from "../../services/vehicleService"
import { getAllProtocols } from "../../services/protocolService"
import type { TripSummary, TripSummaryDto } from "../../model/trip"
import type { Vehicle } from "../../model/vehicle"
import type { Protocol } from "../../model/protocol"
import "../../styles/table.css"
import { Button } from "../button"
import { useAuth } from "../../context/authContext"

interface EditValues {
    startTime: string;
    endTime: string;
    vehicleId: number;
    protocolId: number;
    roadSurfaceConditions: string;
    type: string;
}

function TripsTable() {
    const navigate = useNavigate()
    const { profile } = useAuth()
    const [trips, setTrips] = useState<TripSummaryDto[]>([])
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [editingTripId, setEditingTripId] = useState<number | null>(null)
    const [editValues, setEditValues] = useState<EditValues | null>(null)
    const [vehicles, setVehicles] = useState<Vehicle[]>([])
    const [protocols, setProtocols] = useState<Protocol[]>([])
    const [saving, setSaving] = useState(false)

    const role = profile?.role

    useEffect(() => {
        setLoading(true)
        getAllTrips()
            .then(data => setTrips(data))
            .catch(err => setError(err.message))
            .finally(() => setLoading(false))
    }, [])

    const handleEditStart = (trip: TripSummaryDto) => {
        setEditingTripId(trip.id)
        setEditValues({
            startTime: trip.startTime,
            endTime: trip.endTime,
            vehicleId: trip.vehicleId,
            protocolId: trip.protocolId,
            roadSurfaceConditions: trip.roadSurfaceConditions,
            type: trip.type,
        })
        Promise.all([getAllVehicles(), getAllProtocols()])
            .then(([v, p]) => {
                setVehicles(v)
                setProtocols(p)
            })
            .catch(err => setError(err.message))
    }

    const handleEditSave = (trip: TripSummaryDto) => {
        if (!editValues) return
        setSaving(true)
        setError(null)

        const updatedTrip: TripSummary = {
            id: trip.id,
            profileId: profile!.id,
            vehicleId: editValues.vehicleId,
            protocolId: editValues.protocolId,
            startTime: editValues.startTime,
            endTime: editValues.endTime,
            distance: trip.distance,
            roadSurfaceConditions: editValues.roadSurfaceConditions,
            type: editValues.type,
            startPoint: trip.startPoint,
            endPoint: trip.endPoint,
            furthestPoint: trip.furthestPoint,
            startMileage: trip.startMileage,
            endMileage: trip.endMileage,
        }

        updateTrip(trip.id, updatedTrip)
            .then(() => {
                const updatedVehicle = vehicles.find(v => v.id === editValues.vehicleId)
                const updatedProtocol = protocols.find(p => p.id === editValues.protocolId)
                setTrips(prev => prev.map(t => {
                    if (t.id !== trip.id) return t
                    return {
                        ...t,
                        startTime: editValues.startTime,
                        endTime: editValues.endTime,
                        vehicleId: editValues.vehicleId,
                        vehicleModel: updatedVehicle?.model ?? t.vehicleModel,
                        licensePlate: updatedVehicle?.licensePlate ?? t.licensePlate,
                        protocolId: editValues.protocolId,
                        protocolName: updatedProtocol?.name ?? t.protocolName,
                        roadSurfaceConditions: editValues.roadSurfaceConditions,
                        type: editValues.type,
                    }
                }))
                setEditingTripId(null)
                setEditValues(null)
            })
            .catch(err => setError(err.message))
            .finally(() => setSaving(false))
    }

    const handleEditCancel = () => {
        setEditingTripId(null)
        setEditValues(null)
    }

    const handleDelete = (id: number) => {
        deleteTrip(id)
            .then(() => setTrips(prev => prev.filter(t => t.id !== id)))
            .catch(err => setError(err.message))
    }

    const formatStrecke = (trip: TripSummaryDto) => {
        if (trip.furthestPoint && trip.furthestPoint.toLowerCase() !== trip.endPoint?.toLowerCase()) {
            return `${trip.startPoint} - ${trip.furthestPoint} - ${trip.endPoint}`
        }
        return `${trip.startPoint} - ${trip.endPoint}`
    }

    if (loading) return <p>Laden...</p>
    if (error) return <p>Fehler: {error}</p>

    const isEditing = (id: number) => editingTripId === id

    const roadConditions = ["Trocken", "Nass", "Schnee", "Eis"]

    return (
        <table className="ridesTable">
            <thead>
                <tr>
                    <th>Datum</th>
                    <th>Startzeit</th>
                    <th>Endzeit</th>
                    <th>Fahrer</th>
                    <th>Fahrzeug</th>
                    <th>Kennzeichen</th>
                    <th>Distanz</th>
                    <th>Strecke</th>
                    <th>Protokoll</th>

                    {role === "PRIVAT" && (
                        <>
                            <th colSpan={2}>Kilometerstand</th>
                            <th>Fahrbahnzustand</th>
                        </>
                    )}
                    {role === "FAHRSCHÜLER" && (
                        <>
                            <th colSpan={2}>Kilometerstand</th>
                            <th>Fahrbahnzustand</th>
                        </>
                    )}
                    {role === "BERUFSFAHRER" && (
                        <>
                            <th colSpan={2}>Kilometerstand</th>
                            <th>Tätigkeit</th>
                            <th>Fahrbahnzustand</th>
                        </>
                    )}

                    <th>Aktionen</th>
                </tr>

                <tr>
                    <th></th><th></th><th></th><th></th><th></th>
                    <th></th><th></th><th></th><th></th>
                    <th>Von</th><th>Bis</th>
                    {(role === "BERUFSFAHRER") && <th></th>}
                    <th></th>
                    <th></th>
                </tr>
            </thead>

            <tbody>
                {trips.map(trip => (
                    <tr
                        key={trip.id}
                        onClick={() => !isEditing(trip.id) && navigate(`/trips/${trip.id}`)}
                        style={{ cursor: isEditing(trip.id) ? "default" : "pointer" }}
                    >
                        <td>{new Date(trip.startTime).toLocaleDateString()}</td>

                        {/* Startzeit */}
                        <td onClick={e => e.stopPropagation()}>
                            {isEditing(trip.id) ? (
                                <input
                                    type="datetime-local"
                                    value={editValues!.startTime.slice(0, 16)}
                                    onChange={e => setEditValues(prev => ({ ...prev!, startTime: e.target.value }))}
                                />
                            ) : new Date(trip.startTime).toLocaleTimeString()}
                        </td>

                        {/* Endzeit */}
                        <td onClick={e => e.stopPropagation()}>
                            {isEditing(trip.id) ? (
                                <input
                                    type="datetime-local"
                                    value={editValues!.endTime.slice(0, 16)}
                                    onChange={e => setEditValues(prev => ({ ...prev!, endTime: e.target.value }))}
                                />
                            ) : new Date(trip.endTime).toLocaleTimeString()}
                        </td>

                        <td>{trip.accountFname} {trip.accountLname}</td>

                        {/* Fahrzeug Dropdown */}
                        <td onClick={e => e.stopPropagation()}>
                            {isEditing(trip.id) ? (
                                <select
                                    value={editValues!.vehicleId}
                                    onChange={e => setEditValues(prev => ({ ...prev!, vehicleId: Number(e.target.value) }))}
                                >
                                    {vehicles.map(v => (
                                        <option key={v.id} value={v.id}>{v.model}</option>
                                    ))}
                                </select>
                            ) : trip.vehicleModel}
                        </td>

                        <td>{trip.licensePlate}</td>
                        <td>{trip.distance} km</td>
                        <td>{formatStrecke(trip)}</td>

                        {/* Protokoll Dropdown */}
                        <td onClick={e => e.stopPropagation()}>
                            {isEditing(trip.id) ? (
                                <select
                                    value={editValues!.protocolId}
                                    onChange={e => setEditValues(prev => ({ ...prev!, protocolId: Number(e.target.value) }))}
                                >
                                    {protocols.map(p => (
                                        <option key={p.id} value={p.id}>{p.name}</option>
                                    ))}
                                </select>
                            ) : (
                                <span
                                    onClick={e => { e.stopPropagation(); navigate(`/protocols/${trip.protocolId}`) }}
                                    style={{ cursor: "pointer", textDecoration: "underline" }}
                                >
                                    {trip.protocolName}
                                </span>
                            )}
                        </td>

                        {/* Kilometerstand — alle Rollen */}
                        <td>{trip.startMileage} km</td>
                        <td>{trip.endMileage} km</td>

                        {/* Berufsfahrer: Tätigkeit */}
                        {role === "BERUFSFAHRER" && (
                            <td onClick={e => e.stopPropagation()}>
                                {isEditing(trip.id) ? (
                                    <input
                                        type="text"
                                        value={editValues!.type}
                                        onChange={e => setEditValues(prev => ({ ...prev!, type: e.target.value }))}
                                    />
                                ) : trip.type}
                            </td>
                        )}

                        {/* Fahrbahnzustand — alle Rollen */}
                        <td onClick={e => e.stopPropagation()}>
                            {isEditing(trip.id) ? (
                                <select
                                    value={editValues!.roadSurfaceConditions}
                                    onChange={e => setEditValues(prev => ({ ...prev!, roadSurfaceConditions: e.target.value }))}
                                >
                                    {roadConditions.map(c => (
                                        <option key={c} value={c}>{c}</option>
                                    ))}
                                </select>
                            ) : trip.roadSurfaceConditions}
                        </td>

                        {/* Aktionen */}
                        <td onClick={e => e.stopPropagation()} style={{ display: "flex", gap: "8px" }}>
                            {isEditing(trip.id) ? (
                                <>
                                    <Button
                                        label={saving ? "Speichern..." : "Speichern"}
                                        onClick={() => handleEditSave(trip)}
                                        stopPropagation
                                    />
                                    <Button
                                        label="Abbrechen"
                                        onClick={handleEditCancel}
                                        stopPropagation
                                    />
                                </>
                            ) : (
                                <>
                                    <Button
                                        label="Bearbeiten"
                                        onClick={() => handleEditStart( trip)}
                                        stopPropagation
                                    />
                                    <Button
                                        label="Löschen"
                                        onClick={() => handleDelete(trip.id)}
                                        stopPropagation
                                    />
                                </>
                            )}
                        </td>
                    </tr>
                ))}
            </tbody>
        </table>
    )
}

export default TripsTable
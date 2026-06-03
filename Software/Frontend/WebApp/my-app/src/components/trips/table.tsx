import { Fragment, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../context/authContext";
import type { Protocol } from "../../model/protocol";
import type { TripSummary, TripSummaryDto } from "../../model/trip";
import type { Vehicle } from "../../model/vehicle";
import { getAllProtocols } from "../../services/protocolService";
import { deleteTrip, getAllTrips, updateTrip } from "../../services/tripService";
import { getAllVehicles } from "../../services/vehicleService";
import "../../styles/table.css";
import { Button } from "../button";
import { ConfirmationDialog } from "../ConfirmationDialog";

interface EditValues {
    startTime: string;
    endTime: string;
    vehicleId: number;
    protocolId: number;
    roadSurfaceConditions: string;
    type: string;
}

function TripsTable() {
    const navigate = useNavigate();
    const { profile } = useAuth();
    const [trips, setTrips] = useState<TripSummaryDto[]>([]);
    const [loading, setLoading] = useState(false);
    const [loadError, setLoadError] = useState<string | null>(null);
    const [saveError, setSaveError] = useState<{ tripId: number; message: string } | null>(null);
    const [deleteError, setDeleteError] = useState<string | null>(null);
    const [editingTripId, setEditingTripId] = useState<number | null>(null);
    const [editValues, setEditValues] = useState<EditValues | null>(null);
    const [vehicles, setVehicles] = useState<Vehicle[]>([]);
    const [protocols, setProtocols] = useState<Protocol[]>([]);
    const [saving, setSaving] = useState(false);
    const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null);

    const role = profile?.role;

    useEffect(() => {
        setLoading(true);
        getAllTrips()
            .then(data => setTrips(data))
            .catch(err => setLoadError(err?.message || "Fahrten konnten nicht geladen werden"))
            .finally(() => setLoading(false));
    }, []);

    const handleEditStart = (trip: TripSummaryDto) => {
        setSaveError(null);
        Promise.all([getAllVehicles(), getAllProtocols()])
            .then(([v, p]) => {
                setVehicles(v);
                setProtocols(p);
                setEditingTripId(trip.id);
                setEditValues({
                    startTime: trip.startTime,
                    endTime: trip.endTime,
                    vehicleId: trip.vehicleId,
                    protocolId: trip.protocolId,
                    roadSurfaceConditions: trip.roadSurfaceConditions,
                    type: trip.type,
                });
            })
            .catch(err => setSaveError({
                tripId: trip.id,
                message: err?.message || "Fahrzeuge/Protokolle konnten nicht geladen werden",
            }));
    };

    const handleEditSave = (trip: TripSummaryDto) => {
        if (!editValues) return;

        const profileId = profile?.id;
        if (!profileId) {
            setSaveError({ tripId: trip.id, message: "Kein Profil ausgewaehlt" });
            return;
        }

        setSaving(true);
        setSaveError(null);

        const updatedTrip: TripSummary = {
            id: trip.id,
            profileId,
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
        };

        updateTrip(trip.id, updatedTrip)
            .then(() => {
                const updatedVehicle = vehicles.find(v => v.id === editValues.vehicleId);
                const updatedProtocol = protocols.find(p => p.id === editValues.protocolId);
                setTrips(prev => prev.map(t => {
                    if (t.id !== trip.id) return t;
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
                    };
                }));
                setEditingTripId(null);
                setEditValues(null);
            })
            .catch(err => setSaveError({
                tripId: trip.id,
                message: err?.message || "Speichern fehlgeschlagen",
            }))
            .finally(() => setSaving(false));
    };

    const handleEditCancel = () => {
        setEditingTripId(null);
        setEditValues(null);
        setSaveError(null);
    };

    const handleDelete = (id: number) => {
        setDeleteError(null);
        deleteTrip(id)
            .then(() => setTrips(prev => prev.filter(t => t.id !== id)))
            .catch(err => setDeleteError(err?.message || "Fahrt konnte nicht geloescht werden"));
    };

    const formatStrecke = (trip: TripSummaryDto) => {
        if (trip.furthestPoint && trip.furthestPoint.toLowerCase() !== trip.endPoint?.toLowerCase()) {
            return `${trip.startPoint} - ${trip.furthestPoint} - ${trip.endPoint}`;
        }
        return `${trip.startPoint} - ${trip.endPoint}`;
    };

    const confirmDelete = () => {
        if (confirmDeleteId === null) return;
        handleDelete(confirmDeleteId);
        setConfirmDeleteId(null);
    };

    if (loading) return <p>Laden...</p>;
    if (loadError) return <p style={{ color: "#dc2626" }}>Fehler: {loadError}</p>;

    const isEditing = (id: number) => editingTripId === id;
    const roadConditions = ["Trocken", "Nass", "Schnee", "Eis"];

    return (
        <>
            {deleteError && (
                <p style={{ color: "#dc2626", marginBottom: "12px" }}>{deleteError}</p>
            )}

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
                        {(role === "PRIVAT" || role === "FAHRSCHUELER" || role === "FAHRSCH\u00dcLER") && (
                            <>
                                <th colSpan={2}>Kilometerstand</th>
                                <th>Fahrbahnzustand</th>
                            </>
                        )}
                        {role === "BERUFSFAHRER" && (
                            <>
                                <th colSpan={2}>Kilometerstand</th>
                                <th>Taetigkeit</th>
                                <th>Fahrbahnzustand</th>
                            </>
                        )}
                        <th>Aktionen</th>
                    </tr>
                    <tr>
                        <th></th>
                        <th></th>
                        <th></th>
                        <th></th>
                        <th></th>
                        <th></th>
                        <th></th>
                        <th></th>
                        <th></th>
                        <th>Von</th>
                        <th>Bis</th>
                        {role === "BERUFSFAHRER" && <th></th>}
                        <th></th>
                        <th></th>
                    </tr>
                </thead>

                <tbody>
                    {trips.map(trip => (
                        <Fragment key={trip.id}>
                            <tr
                                onClick={() => !isEditing(trip.id) && navigate(`/trips/${trip.id}`)}
                                style={{ cursor: isEditing(trip.id) ? "default" : "pointer" }}
                            >
                                <td>{new Date(trip.startTime).toLocaleDateString()}</td>

                                <td onClick={e => e.stopPropagation()}>
                                    {isEditing(trip.id) ? (
                                        <input
                                            type="datetime-local"
                                            value={editValues!.startTime.slice(0, 16)}
                                            onChange={e => setEditValues(prev => ({
                                                ...prev!,
                                                startTime: e.target.value,
                                            }))}
                                        />
                                    ) : new Date(trip.startTime).toLocaleTimeString()}
                                </td>

                                <td onClick={e => e.stopPropagation()}>
                                    {isEditing(trip.id) ? (
                                        <input
                                            type="datetime-local"
                                            value={editValues!.endTime.slice(0, 16)}
                                            onChange={e => setEditValues(prev => ({
                                                ...prev!,
                                                endTime: e.target.value,
                                            }))}
                                        />
                                    ) : new Date(trip.endTime).toLocaleTimeString()}
                                </td>

                                <td>{trip.accountFirstName} {trip.accountLastName}</td>

                                <td onClick={e => e.stopPropagation()}>
                                    {isEditing(trip.id) ? (
                                        <select
                                            value={editValues!.vehicleId.toString()}
                                            onChange={e => setEditValues(prev => ({
                                                ...prev!,
                                                vehicleId: Number(e.target.value),
                                            }))}
                                        >
                                            {vehicles.map(v => (
                                                <option key={v.id} value={v.id.toString()}>{v.model}</option>
                                            ))}
                                        </select>
                                    ) : trip.vehicleModel}
                                </td>

                                <td>{trip.licensePlate}</td>
                                <td>{trip.distance} km</td>
                                <td>{formatStrecke(trip)}</td>

                                <td onClick={e => e.stopPropagation()}>
                                    {isEditing(trip.id) ? (
                                        <select
                                            value={editValues!.protocolId.toString()}
                                            onChange={e => setEditValues(prev => ({
                                                ...prev!,
                                                protocolId: Number(e.target.value),
                                            }))}
                                        >
                                            {protocols.map(p => (
                                                <option key={p.id} value={p.id.toString()}>{p.name}</option>
                                            ))}
                                        </select>
                                    ) : (
                                        <span
                                            onClick={e => {
                                                e.stopPropagation();
                                                navigate(`/protocols/${trip.protocolId}`);
                                            }}
                                            style={{ cursor: "pointer", textDecoration: "underline" }}
                                        >
                                            {trip.protocolName}
                                        </span>
                                    )}
                                </td>

                                <td>{trip.startMileage} km</td>
                                <td>{trip.endMileage} km</td>

                                {role === "BERUFSFAHRER" && (
                                    <td onClick={e => e.stopPropagation()}>
                                        {isEditing(trip.id) ? (
                                            <input
                                                type="text"
                                                value={editValues!.type}
                                                onChange={e => setEditValues(prev => ({
                                                    ...prev!,
                                                    type: e.target.value,
                                                }))}
                                            />
                                        ) : trip.type}
                                    </td>
                                )}

                                <td onClick={e => e.stopPropagation()}>
                                    {isEditing(trip.id) ? (
                                        <select
                                            value={editValues!.roadSurfaceConditions}
                                            onChange={e => setEditValues(prev => ({
                                                ...prev!,
                                                roadSurfaceConditions: e.target.value,
                                            }))}
                                        >
                                            {roadConditions.map(c => <option key={c} value={c}>{c}</option>)}
                                        </select>
                                    ) : trip.roadSurfaceConditions}
                                </td>

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
                                                onClick={() => handleEditStart(trip)}
                                                stopPropagation
                                            />
                                            <Button
                                                label="Loeschen"
                                                onClick={() => setConfirmDeleteId(trip.id)}
                                                stopPropagation
                                            />
                                        </>
                                    )}
                                </td>
                            </tr>

                            {saveError?.tripId === trip.id && (
                                <tr>
                                    <td colSpan={99} style={{ color: "#dc2626", fontSize: "0.85rem", padding: "4px 8px" }}>
                                        {saveError.message}
                                    </td>
                                </tr>
                            )}
                        </Fragment>
                    ))}
                </tbody>
            </table>

            <ConfirmationDialog
                open={confirmDeleteId !== null}
                title="Fahrt loeschen"
                message="Moechtest du diese Fahrt wirklich unwiderruflich loeschen?"
                confirmLabel="Ja, loeschen"
                cancelLabel="Abbrechen"
                onConfirm={confirmDelete}
                onCancel={() => setConfirmDeleteId(null)}
            />
        </>
    );
}

export default TripsTable;

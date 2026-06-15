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
import "../../styles/pageLayout.css";
import { Button } from "../button";
import { ConfirmationDialog } from "../ConfirmationDialog";
import { TableSkeleton } from "../loadingSkeleton";

interface EditValues {
    startTime: string;
    endTime: string;
    vehicleId: number;
    protocolId: number;
    roadSurfaceConditions: string;
    type: string;
}

type SortField = "date" | "distance";
type SortDir = "asc" | "desc";

const TRIPS_PER_PAGE = 20;

function TripsTable() {
    const navigate = useNavigate();
    const { profile } = useAuth();
    const [trips, setTrips] = useState<TripSummaryDto[]>([]);
    const [allVehicles, setAllVehicles] = useState<Vehicle[]>([]);
    const [loading, setLoading] = useState(false);
    const [loadError, setLoadError] = useState<string | null>(null);
    const [saveError, setSaveError] = useState<{ tripId: number; message: string } | null>(null);
    const [deleteError, setDeleteError] = useState<string | null>(null);
    const [editingTripId, setEditingTripId] = useState<number | null>(null);
    const [editValues, setEditValues] = useState<EditValues | null>(null);
    const [editVehicles, setEditVehicles] = useState<Vehicle[]>([]);
    const [protocols, setProtocols] = useState<Protocol[]>([]);
    const [saving, setSaving] = useState(false);
    const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null);
    const [currentPage, setCurrentPage] = useState(1);

    // Filter & Sort
    const [filterFrom, setFilterFrom] = useState("");
    const [filterTo, setFilterTo] = useState("");
    const [filterVehicleId, setFilterVehicleId] = useState<number | "">("");
    const [sortField, setSortField] = useState<SortField>("date");
    const [sortDir, setSortDir] = useState<SortDir>("desc");

    const role = profile?.role;

    useEffect(() => {
        setLoading(true);
        Promise.all([getAllTrips(), getAllVehicles()])
            .then(([tripsData, vehiclesData]) => {
                setTrips(tripsData);
                setAllVehicles(vehiclesData);
            })
            .catch(err => setLoadError(err?.message || "Daten konnten nicht geladen werden"))
            .finally(() => setLoading(false));
    }, []);

    // Filter + Sort + Pagination
    const filteredAndSorted = trips
        .filter(t => {
            if (filterFrom) {
                const from = new Date(filterFrom);
                if (new Date(t.startTime) < from) return false;
            }
            if (filterTo) {
                const to = new Date(filterTo);
                to.setHours(23, 59, 59);
                if (new Date(t.startTime) > to) return false;
            }
            if (filterVehicleId !== "") {
                if (t.vehicleId !== filterVehicleId) return false;
            }
            return true;
        })
        .sort((a, b) => {
            let diff = 0;
            if (sortField === "date") {
                diff = new Date(a.startTime).getTime() - new Date(b.startTime).getTime();
            } else {
                diff = (parseFloat(String(a.distance)) || 0) - (parseFloat(String(b.distance)) || 0);
            }
            return sortDir === "asc" ? diff : -diff;
        });

    const totalPages = Math.ceil(filteredAndSorted.length / TRIPS_PER_PAGE);
    const paginatedTrips = filteredAndSorted.slice(
        (currentPage - 1) * TRIPS_PER_PAGE,
        currentPage * TRIPS_PER_PAGE
    );

    const handleSortChange = (field: SortField) => {
        if (sortField === field) {
            setSortDir(prev => prev === "asc" ? "desc" : "asc");
        } else {
            setSortField(field);
            setSortDir("desc");
        }
        setCurrentPage(1);
    };

    const handleFilterChange = () => setCurrentPage(1);

    const handleResetFilters = () => {
        setFilterFrom("");
        setFilterTo("");
        setFilterVehicleId("");
        setSortField("date");
        setSortDir("desc");
        setCurrentPage(1);
    };

    const handlePageChange = (page: number) => {
        setCurrentPage(page);
        handleEditCancel();
    };

    const handleEditStart = (trip: TripSummaryDto) => {
        setSaveError(null);
        Promise.all([getAllVehicles(), getAllProtocols()])
            .then(([v, p]) => {
                setEditVehicles(v);
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
            setSaveError({ tripId: trip.id, message: "Kein Profil ausgewählt" });
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
                const updatedVehicle = editVehicles.find(v => v.id === editValues.vehicleId);
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
            .then(() => {
                setTrips(prev => prev.filter(t => t.id !== id));
                const newTotalPages = Math.ceil((trips.length - 1) / TRIPS_PER_PAGE);
                if (currentPage > newTotalPages && newTotalPages > 0) {
                    setCurrentPage(newTotalPages);
                }
            })
            .catch(err => setDeleteError(err?.message || "Fahrt konnte nicht gelöscht werden"));
    };

    const confirmDelete = () => {
        if (confirmDeleteId === null) return;
        handleDelete(confirmDeleteId);
        setConfirmDeleteId(null);
    };

    const formatStrecke = (trip: TripSummaryDto) => {
        if (trip.furthestPoint && trip.furthestPoint.toLowerCase() !== trip.endPoint?.toLowerCase()) {
            return `${trip.startPoint} - ${trip.furthestPoint} - ${trip.endPoint}`;
        }
        return `${trip.startPoint} - ${trip.endPoint}`;
    };

    const sortLabel = (field: SortField, label: string) => {
        if (sortField !== field) return label;
        return `${label} ${sortDir === "asc" ? "↑" : "↓"}`;
    };

    if (loading) return <TableSkeleton rows={5} cols={9} />;
    if (loadError) return <p style={{ color: "#dc2626" }}>Fehler: {loadError}</p>;

    const isEditing = (id: number) => editingTripId === id;
    const roadConditions = ["Trocken", "Nass", "Schnee", "Eis"];
    const hasActiveFilters = filterFrom || filterTo || filterVehicleId !== "";

    return (
        <>
            {deleteError && <p style={{ color: "#dc2626", marginBottom: "12px" }}>{deleteError}</p>}

            {/* Filter & Sort Toolbar */}
            <div className="page-toolbar" style={{ marginBottom: 0, borderRadius: "var(--border-radius-lg) var(--border-radius-lg) 0 0" }}>
                <div className="page-toolbar-left" style={{ flexWrap: "wrap", gap: "8px" }}>
                    <input
                        type="date"
                        value={filterFrom}
                        onChange={e => { setFilterFrom(e.target.value); handleFilterChange(); }}
                        title="Von Datum"
                    />
                    <input
                        type="date"
                        value={filterTo}
                        onChange={e => { setFilterTo(e.target.value); handleFilterChange(); }}
                        title="Bis Datum"
                    />
                    <select
                        value={filterVehicleId}
                        onChange={e => { setFilterVehicleId(e.target.value === "" ? "" : Number(e.target.value)); handleFilterChange(); }}
                    >
                        <option value="">Alle Fahrzeuge</option>
                        {allVehicles.map(v => (
                            <option key={v.id} value={v.id}>{v.model} ({v.licensePlate})</option>
                        ))}
                    </select>
                    {hasActiveFilters && (
                        <Button label="Filter zurücksetzen" onClick={handleResetFilters} />
                    )}
                </div>
                <div className="page-toolbar-right">
                    <Button label={sortLabel("date", "Datum")} onClick={() => handleSortChange("date")} />
                    <Button label={sortLabel("distance", "Distanz")} onClick={() => handleSortChange("distance")} />
                    <span style={{ fontSize: "13px", color: "var(--color-text-secondary)" }}>
                        {filteredAndSorted.length} Fahrten
                    </span>
                </div>
            </div>

            <div
                className="ridesTable"
                onWheel={(e) => {
                    const el = e.currentTarget;
                    const delta = e.deltaY || e.deltaX;

                    if (delta !== 0) {
                        e.preventDefault();
                        el.scrollLeft += delta;
                    }
                }}
                onMouseDown={(e) => {
                    const el = e.currentTarget;
                    const startX = e.pageX;
                    const startScrollLeft = el.scrollLeft;

                    const onMouseMove = (moveEvent: MouseEvent) => {
                        el.scrollLeft = startScrollLeft - (moveEvent.pageX - startX);
                    };

                    const onMouseUp = () => {
                        document.removeEventListener("mousemove", onMouseMove);
                        document.removeEventListener("mouseup", onMouseUp);
                    };

                    document.addEventListener("mousemove", onMouseMove);
                    document.addEventListener("mouseup", onMouseUp);
                }}
                onTouchStart={(e) => {
                    const el = e.currentTarget;
                    const touch = e.touches[0];
                    const startX = touch.pageX;
                    const startScrollLeft = el.scrollLeft;

                    const onTouchMove = (moveEvent: TouchEvent) => {
                        const currentTouch = moveEvent.touches[0];
                        el.scrollLeft = startScrollLeft - (currentTouch.pageX - startX);
                    };

                    const onTouchEnd = () => {
                        el.removeEventListener("touchmove", onTouchMove);
                        el.removeEventListener("touchend", onTouchEnd);
                    };

                    el.addEventListener("touchmove", onTouchMove, { passive: true });
                    el.addEventListener("touchend", onTouchEnd, { passive: true });
                }}
            >
              <table>
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
                        {(role === "PRIVAT" || role === "FAHRSCHUELER" || role === "FAHRSCHÜLER") && (
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
                        {role === "BERUFSFAHRER" && <th></th>}
                        <th></th><th></th>
                    </tr>
                </thead>

                <tbody>
                    {paginatedTrips.length === 0 ? (
                        <tr>
                            <td colSpan={99} className="page-empty">Keine Fahrten gefunden</td>
                        </tr>
                    ) : paginatedTrips.map(trip => (
                        <Fragment key={trip.id}>
                            <tr
                                onClick={() => !isEditing(trip.id) && navigate(`/trips/${trip.id}`)}
                                style={{ cursor: isEditing(trip.id) ? "default" : "pointer" }}
                            >
                                <td>{new Date(trip.startTime).toLocaleDateString()}</td>

                                <td onClick={e => e.stopPropagation()}>
                                    {isEditing(trip.id) ? (
                                        <input type="datetime-local" value={editValues!.startTime.slice(0, 16)}
                                            onChange={e => setEditValues(prev => ({ ...prev!, startTime: e.target.value }))} />
                                    ) : new Date(trip.startTime).toLocaleTimeString()}
                                </td>

                                <td onClick={e => e.stopPropagation()}>
                                    {isEditing(trip.id) ? (
                                        <input type="datetime-local" value={editValues!.endTime.slice(0, 16)}
                                            onChange={e => setEditValues(prev => ({ ...prev!, endTime: e.target.value }))} />
                                    ) : new Date(trip.endTime).toLocaleTimeString()}
                                </td>

                                <td>{trip.accountFirstName} {trip.accountLastName}</td>

                                <td onClick={e => e.stopPropagation()}>
                                    {isEditing(trip.id) ? (
                                        <select value={editValues!.vehicleId.toString()}
                                            onChange={e => setEditValues(prev => ({ ...prev!, vehicleId: Number(e.target.value) }))}>
                                            {editVehicles.map(v => <option key={v.id} value={v.id.toString()}>{v.model}</option>)}
                                        </select>
                                    ) : trip.vehicleModel}
                                </td>

                                <td>{trip.licensePlate}</td>
                                <td>{trip.distance} km</td>
                                <td>{formatStrecke(trip)}</td>

                                <td onClick={e => e.stopPropagation()}>
                                    {isEditing(trip.id) ? (
                                        <select value={editValues!.protocolId.toString()}
                                            onChange={e => setEditValues(prev => ({ ...prev!, protocolId: Number(e.target.value) }))}>
                                            {protocols.map(p => <option key={p.id} value={p.id.toString()}>{p.name}</option>)}
                                        </select>
                                    ) : (
                                        <span onClick={e => { e.stopPropagation(); navigate(`/protocols/${trip.protocolId}`); }}
                                            style={{ cursor: "pointer", textDecoration: "underline" }}>
                                            {trip.protocolName}
                                        </span>
                                    )}
                                </td>

                                <td>{trip.startMileage} km</td>
                                <td>{trip.endMileage} km</td>

                                {role === "BERUFSFAHRER" && (
                                    <td onClick={e => e.stopPropagation()}>
                                        {isEditing(trip.id) ? (
                                            <input type="text" value={editValues!.type}
                                                onChange={e => setEditValues(prev => ({ ...prev!, type: e.target.value }))} />
                                        ) : trip.type}
                                    </td>
                                )}

                                <td onClick={e => e.stopPropagation()}>
                                    {isEditing(trip.id) ? (
                                        <select value={editValues!.roadSurfaceConditions}
                                            onChange={e => setEditValues(prev => ({ ...prev!, roadSurfaceConditions: e.target.value }))}>
                                            {roadConditions.map(c => <option key={c} value={c}>{c}</option>)}
                                        </select>
                                    ) : trip.roadSurfaceConditions}
                                </td>

                                <td onClick={e => e.stopPropagation()} style={{ display: "flex", gap: "8px" }}>
                                    {isEditing(trip.id) ? (
                                        <>
                                            <Button label={saving ? "Speichern..." : "Speichern"} loading={saving} onClick={() => handleEditSave(trip)} stopPropagation />
                                            <Button label="Abbrechen" onClick={handleEditCancel} stopPropagation />
                                        </>
                                    ) : (
                                        <>
                                            <Button label="Bearbeiten" onClick={() => handleEditStart(trip)} stopPropagation />
                                            <Button label="Löschen" onClick={() => setConfirmDeleteId(trip.id)} stopPropagation />
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
            </div>

            {totalPages > 1 && (
                <div className="pagination">
                    <Button label="← Zurück" onClick={() => handlePageChange(currentPage - 1)} disabled={currentPage === 1} />
                    <span className="pagination-info">{currentPage} / {totalPages}</span>
                    <Button label="Weiter →" onClick={() => handlePageChange(currentPage + 1)} disabled={currentPage === totalPages} />
                </div>
            )}

            <ConfirmationDialog
                open={confirmDeleteId !== null}
                title="Fahrt löschen"
                message="Möchtest du diese Fahrt wirklich unwiderruflich löschen?"
                confirmLabel="Ja, löschen"
                cancelLabel="Abbrechen"
                onConfirm={confirmDelete}
                onCancel={() => setConfirmDeleteId(null)}
            />
        </>
    );
}

export default TripsTable;
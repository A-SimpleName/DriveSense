import { Fragment, type Dispatch, type FormEvent, type SetStateAction, useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { useNavigate } from "react-router-dom";
import { ChevronLeft, ChevronRight, Check, Edit2, Trash2, X } from "lucide-react";
import { useAuth } from "../../context/authContext";
import type { Protocol } from "../../model/protocol";
import type { TripSummary, TripSummaryDto } from "../../model/trip";
import type { Vehicle } from "../../model/vehicle";
import { getAllProtocols } from "../../services/protocolService";
import { deleteTrip, getAllTrips, updateTrip } from "../../services/tripService";
import { getAllVehicles } from "../../services/vehicleService";
import { useDragScroll } from "../../hooks/useDragScroll";
import { Button } from "../button";
import { ConfirmationDialog } from "../ConfirmationDialog";
import { TableSkeleton } from "../loadingSkeleton";
import "../../styles/table.css";
import "../../styles/pageLayout.css";

interface EditValues {
    startTime: string;
    endTime: string;
    vehicleId: number;
    protocolId: number;
    distance: string;
    startMileage: string;
    endMileage: string;
    startPoint: string;
    furthestPoint: string;
    endPoint: string;
    roadSurfaceConditions: string;
    type: string;
}

type ProfileRole = "PRIVAT" | "FAHRSCHUELER" | "BERUFSFAHRER";
type SortField = "date" | "distance";
type SortDir = "asc" | "desc";

const TRIPS_PER_PAGE = 12;

function normalizeRole(role?: string): ProfileRole {
    const normalized = (role ?? "").trim().toUpperCase().replace(/\u00dc/g, "UE");
    if (normalized === "FAHRSCHUELER") return "FAHRSCHUELER";
    if (normalized === "BERUFSFAHRER") return "BERUFSFAHRER";
    return "PRIVAT";
}

function parseDecimal(value: string) {
    return Number.parseFloat(value.trim().replace(",", "."));
}

function formatDateTimeInput(value: string) {
    return value ? value.slice(0, 16) : "";
}

function displayTime(value: string) {
    if (!value) return "-";
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? "-" : date.toLocaleTimeString();
}

function calculateDurationSeconds(startTime: string, endTime: string) {
    const startDate = new Date(startTime);
    const endDate = new Date(endTime);
    if (Number.isNaN(startDate.getTime()) || Number.isNaN(endDate.getTime())) {
        return 0;
    }

    return Math.max(0, Math.round((endDate.getTime() - startDate.getTime()) / 1000));
}

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

    const [showFilters, setShowFilters] = useState(false);
    const [filterFrom, setFilterFrom] = useState("");
    const [filterTo, setFilterTo] = useState("");
    const [filterVehicleId, setFilterVehicleId] = useState<number | "">("");
    const [sortField, setSortField] = useState<SortField>("date");
    const [sortDir, setSortDir] = useState<SortDir>("desc");

    const dragScroll = useDragScroll<HTMLDivElement>();
    const role = normalizeRole(profile?.role);
    const showRoadSurface = role === "FAHRSCHUELER";
    const showType = role === "BERUFSFAHRER";

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
            if (filterVehicleId !== "" && t.vehicleId !== filterVehicleId) {
                return false;
            }
            return true;
        })
        .sort((a, b) => {
            const diff = sortField === "date"
                ? new Date(a.startTime).getTime() - new Date(b.startTime).getTime()
                : (Number(a.distance) || 0) - (Number(b.distance) || 0);
            return sortDir === "asc" ? diff : -diff;
        });

    const totalPages = Math.ceil(filteredAndSorted.length / TRIPS_PER_PAGE);
    const paginatedTrips = filteredAndSorted.slice(
        (currentPage - 1) * TRIPS_PER_PAGE,
        currentPage * TRIPS_PER_PAGE
    );
    const editingTrip = editingTripId === null
        ? null
        : trips.find(trip => trip.id === editingTripId) ?? null;

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
                    distance: String(trip.distance ?? 0),
                    startMileage: String(trip.startMileage ?? 0),
                    endMileage: String(trip.endMileage ?? 0),
                    startPoint: trip.startPoint ?? "",
                    furthestPoint: trip.furthestPoint ?? "",
                    endPoint: trip.endPoint ?? "",
                    roadSurfaceConditions: trip.roadSurfaceConditions ?? "",
                    type: trip.type ?? "",
                });
            })
            .catch(err => setSaveError({
                tripId: trip.id,
                message: err?.message || "Fahrzeuge/Protokolle konnten nicht geladen werden",
            }));
    };

    const handleEditSave = (trip: TripSummaryDto, event?: FormEvent) => {
        event?.preventDefault();
        if (!editValues) return;

        const profileId = profile?.id ?? trip.profileId;
        if (!profileId) {
            setSaveError({ tripId: trip.id, message: "Kein Profil ausgewaehlt" });
            return;
        }

        const distance = parseDecimal(editValues.distance);
        const startMileage = Number.parseInt(editValues.startMileage, 10);
        const endMileage = Number.parseInt(editValues.endMileage, 10);
        const startDate = new Date(editValues.startTime);
        const endDate = new Date(editValues.endTime);

        if (
            Number.isNaN(distance) ||
            Number.isNaN(startMileage) ||
            Number.isNaN(endMileage) ||
            Number.isNaN(startDate.getTime()) ||
            Number.isNaN(endDate.getTime())
        ) {
            setSaveError({ tripId: trip.id, message: "Bitte Zahlen und Zeiten korrekt eingeben." });
            return;
        }

        if (distance < 0 || startMileage < 0 || endMileage < startMileage) {
            setSaveError({ tripId: trip.id, message: "Kilometerwerte sind ungueltig." });
            return;
        }

        if (endDate < startDate) {
            setSaveError({ tripId: trip.id, message: "Endzeit darf nicht vor der Startzeit liegen." });
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
            distance,
            durationSeconds: calculateDurationSeconds(editValues.startTime, editValues.endTime),
            roadSurfaceConditions: showRoadSurface
                ? editValues.roadSurfaceConditions.trim()
                : trip.roadSurfaceConditions,
            type: showType ? editValues.type.trim() : trip.type,
            startPoint: editValues.startPoint.trim(),
            endPoint: editValues.endPoint.trim(),
            furthestPoint: editValues.furthestPoint.trim(),
            startMileage,
            endMileage,
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
                        distance,
                        durationSeconds: updatedTrip.durationSeconds,
                        roadSurfaceConditions: updatedTrip.roadSurfaceConditions,
                        type: updatedTrip.type,
                        startPoint: updatedTrip.startPoint,
                        endPoint: updatedTrip.endPoint,
                        furthestPoint: updatedTrip.furthestPoint,
                        startMileage,
                        endMileage,
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
            .catch(err => setDeleteError(err?.message || "Fahrt konnte nicht geloescht werden"));
    };

    const confirmDelete = () => {
        if (confirmDeleteId === null) return;
        handleDelete(confirmDeleteId);
        setConfirmDeleteId(null);
    };

    const formatStrecke = (trip: TripSummaryDto) => {
        const points = [trip.startPoint, trip.furthestPoint, trip.endPoint]
            .map(point => (point ?? "").trim())
            .filter(point => point && point.toLowerCase() !== "unbekannt");
        return points.length > 0 ? points.join(" - ") : "-";
    };

    if (loading) return <TableSkeleton rows={5} cols={9} />;
    if (loadError) return <p className="error-text">Fehler: {loadError}</p>;

    const hasActiveFilters = filterFrom || filterTo || filterVehicleId !== "";

    return (
        <>
            {deleteError && <p className="error-text" style={{ marginBottom: "12px" }}>{deleteError}</p>}

            <div
                className="page-toolbar"
                style={{
                    marginBottom: 0,
                    borderRadius: "var(--border-radius-lg) var(--border-radius-lg) 0 0",
                    justifyContent: "space-between",
                }}
            >
                <div className="page-toolbar-left">
                    <Button
                        label={`Filter ${hasActiveFilters ? "(Aktiv)" : ""}`}
                        onClick={() => setShowFilters(prev => !prev)}
                    />
                </div>

                <div className="page-toolbar-right">
                    <span style={{ fontSize: "13px", color: "var(--color-text-secondary)" }}>
                        {filteredAndSorted.length} Fahrten
                    </span>
                </div>
            </div>

            {showFilters && (
                <div
                    className="page-toolbar"
                    style={{
                        borderTop: "none",
                        borderRadius: 0,
                        marginBottom: "12px",
                    }}
                >
                    <div className="page-toolbar-left" style={{ flexWrap: "wrap", gap: "8px" }}>
                        <input
                            type="date"
                            value={filterFrom}
                            onChange={e => {
                                setFilterFrom(e.target.value);
                                handleFilterChange();
                            }}
                            title="Von Datum"
                        />

                        <input
                            type="date"
                            value={filterTo}
                            onChange={e => {
                                setFilterTo(e.target.value);
                                handleFilterChange();
                            }}
                            title="Bis Datum"
                        />

                        <select
                            value={filterVehicleId}
                            onChange={e => {
                                setFilterVehicleId(e.target.value === "" ? "" : Number(e.target.value));
                                handleFilterChange();
                            }}
                        >
                            <option value="">Alle Fahrzeuge</option>
                            {allVehicles.map(v => (
                                <option key={v.id} value={v.id}>
                                    {v.model} ({v.licensePlate})
                                </option>
                            ))}
                        </select>

                        {hasActiveFilters && (
                            <Button label="Filter zuruecksetzen" onClick={handleResetFilters} />
                        )}
                    </div>
                </div>
            )}

            <div ref={dragScroll.ref} className="ridesTable" {...dragScroll.handlers}>
                <table>
                    <thead>
                        <tr>
                            <th
                                onClick={() => handleSortChange("date")}
                                style={{ cursor: "pointer", userSelect: "none" }}
                            >
                                <span style={{ whiteSpace: "nowrap" }}>
                                    Datum <span>{sortField === "date" ? (sortDir === "asc" ? "^" : "v") : "<>"}</span>
                                </span>
                            </th>
                            <th>Startzeit</th>
                            <th>Endzeit</th>
                            <th>Fahrer</th>
                            <th>Fahrzeug</th>
                            <th>Kennzeichen</th>
                            <th onClick={() => handleSortChange("distance")} style={{ cursor: "pointer" }}>
                                <span style={{ whiteSpace: "nowrap" }}>
                                    Distanz{" "}
                                    <span>{sortField === "distance" ? (sortDir === "asc" ? "^" : "v") : "<>"}</span>
                                </span>
                            </th>
                            <th>Strecke</th>
                            <th>Protokoll</th>
                            <th>Kilometerstand von</th>
                            <th>Kilometerstand bis</th>
                            {showType && <th>Taetigkeit</th>}
                            {showRoadSurface && <th>Fahrbahnzustand</th>}
                            <th>Aktionen</th>
                        </tr>
                    </thead>

                    <tbody>
                        {paginatedTrips.length === 0 ? (
                            <tr>
                                <td colSpan={99} className="page-empty">Keine Fahrten gefunden</td>
                            </tr>
                        ) : paginatedTrips.map(trip => (
                            <Fragment key={trip.id}>
                                <tr onClick={() => navigate(`/trips/${trip.id}`)} style={{ cursor: "pointer" }}>
                                    <td>{new Date(trip.startTime).toLocaleDateString()}</td>
                                    <td>{displayTime(trip.startTime)}</td>
                                    <td>{displayTime(trip.endTime)}</td>
                                    <td>{trip.accountFirstName} {trip.accountLastName}</td>
                                    <td>{trip.vehicleModel}</td>
                                    <td>{trip.licensePlate}</td>
                                    <td>{trip.distance} km</td>
                                    <td>{formatStrecke(trip)}</td>
                                    <td>
                                        <span
                                            onClick={e => {
                                                e.stopPropagation();
                                                navigate(`/protocols/${trip.protocolId}`);
                                            }}
                                            style={{ cursor: "pointer", textDecoration: "underline" }}
                                        >
                                            {trip.protocolName}
                                        </span>
                                    </td>
                                    <td>{trip.startMileage} km</td>
                                    <td>{trip.endMileage} km</td>
                                    {showType && <td>{trip.type}</td>}
                                    {showRoadSurface && <td>{trip.roadSurfaceConditions}</td>}
                                    <td onClick={e => e.stopPropagation()} style={{ display: "flex", gap: "8px" }}>
                                        <Button
                                            label="Bearbeiten"
                                            onClick={() => handleEditStart(trip)}
                                            stopPropagation
                                            icon={<Edit2 size={18} />}
                                        />
                                        <Button
                                            label="Loeschen"
                                            onClick={() => setConfirmDeleteId(trip.id)}
                                            stopPropagation
                                            icon={<Trash2 size={18} />}
                                        />
                                    </td>
                                </tr>

                                {saveError?.tripId === trip.id && editingTripId !== trip.id && (
                                    <tr>
                                        <td colSpan={99} className="error-text" style={{ fontSize: "0.85rem", padding: "4px 8px" }}>
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
                    <Button
                        label="Zurueck"
                        onClick={() => handlePageChange(currentPage - 1)}
                        disabled={currentPage === 1}
                        icon={<ChevronLeft size={18} />}
                    />
                    <span className="pagination-info">{currentPage} / {totalPages}</span>
                    <Button
                        label="Weiter"
                        onClick={() => handlePageChange(currentPage + 1)}
                        disabled={currentPage === totalPages}
                        icon={<ChevronRight size={18} />}
                        iconPosition="right"
                    />
                </div>
            )}

            {editingTrip && editValues && (
                <TripEditDialog
                    trip={editingTrip}
                    values={editValues}
                    setValues={setEditValues}
                    vehicles={editVehicles}
                    protocols={protocols}
                    role={role}
                    saving={saving}
                    error={saveError?.tripId === editingTrip.id ? saveError.message : null}
                    onSubmit={event => handleEditSave(editingTrip, event)}
                    onCancel={handleEditCancel}
                />
            )}

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

type TripEditDialogProps = {
    trip: TripSummaryDto;
    values: EditValues;
    setValues: Dispatch<SetStateAction<EditValues | null>>;
    vehicles: Vehicle[];
    protocols: Protocol[];
    role: ProfileRole;
    saving: boolean;
    error: string | null;
    onSubmit: (event: FormEvent) => void;
    onCancel: () => void;
};

function TripEditDialog({
    trip,
    values,
    setValues,
    vehicles,
    protocols,
    role,
    saving,
    error,
    onSubmit,
    onCancel,
}: TripEditDialogProps) {
    if (typeof document === "undefined") return null;

    const showRoadSurface = role === "FAHRSCHUELER";
    const showType = role === "BERUFSFAHRER";

    return createPortal(
        <div className="modal-overlay" onClick={onCancel}>
            <form
                className="modal"
                onSubmit={onSubmit}
                onClick={event => event.stopPropagation()}
                style={{
                    width: "min(760px, 94vw)",
                    padding: "24px",
                    borderRadius: "8px",
                    background: "var(--surface)",
                }}
            >
                <div style={{ marginBottom: "18px" }}>
                    <h2 style={{ margin: 0, fontSize: "1.25rem", color: "var(--text)" }}>
                        Fahrt bearbeiten
                    </h2>
                    <p style={{ margin: "8px 0 0", color: "var(--text-secondary)" }}>
                        {trip.accountFirstName} {trip.accountLastName}
                    </p>
                </div>

                <div
                    style={{
                        display: "grid",
                        gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
                        gap: "12px",
                    }}
                >
                    <label>
                        Startzeit
                        <input
                            type="datetime-local"
                            value={formatDateTimeInput(values.startTime)}
                            onChange={e => setValues(prev => ({ ...prev!, startTime: e.target.value }))}
                        />
                    </label>

                    <label>
                        Endzeit
                        <input
                            type="datetime-local"
                            value={formatDateTimeInput(values.endTime)}
                            onChange={e => setValues(prev => ({ ...prev!, endTime: e.target.value }))}
                        />
                    </label>

                    <label>
                        Fahrzeug
                        <select
                            value={values.vehicleId}
                            onChange={e => setValues(prev => ({ ...prev!, vehicleId: Number(e.target.value) }))}
                        >
                            {vehicles.map(vehicle => (
                                <option key={vehicle.id} value={vehicle.id}>
                                    {vehicle.model} ({vehicle.licensePlate})
                                </option>
                            ))}
                        </select>
                    </label>

                    <label>
                        Protokoll
                        <select
                            value={values.protocolId}
                            onChange={e => setValues(prev => ({ ...prev!, protocolId: Number(e.target.value) }))}
                        >
                            {protocols.map(protocol => (
                                <option key={protocol.id} value={protocol.id}>
                                    {protocol.name}
                                </option>
                            ))}
                        </select>
                    </label>

                    <label>
                        Gefahrene km
                        <input
                            type="number"
                            min="0"
                            step="0.01"
                            value={values.distance}
                            onChange={e => setValues(prev => ({ ...prev!, distance: e.target.value }))}
                        />
                    </label>

                    <label>
                        Startkilometer
                        <input
                            type="number"
                            min="0"
                            step="1"
                            value={values.startMileage}
                            onChange={e => setValues(prev => ({ ...prev!, startMileage: e.target.value }))}
                        />
                    </label>

                    <label>
                        Endkilometer
                        <input
                            type="number"
                            min="0"
                            step="1"
                            value={values.endMileage}
                            onChange={e => setValues(prev => ({ ...prev!, endMileage: e.target.value }))}
                        />
                    </label>

                    <label>
                        Startpunkt
                        <input
                            type="text"
                            value={values.startPoint}
                            onChange={e => setValues(prev => ({ ...prev!, startPoint: e.target.value }))}
                        />
                    </label>

                    <label>
                        Wendepunkt
                        <input
                            type="text"
                            value={values.furthestPoint}
                            onChange={e => setValues(prev => ({ ...prev!, furthestPoint: e.target.value }))}
                        />
                    </label>

                    <label>
                        Ziel
                        <input
                            type="text"
                            value={values.endPoint}
                            onChange={e => setValues(prev => ({ ...prev!, endPoint: e.target.value }))}
                        />
                    </label>

                    {showRoadSurface && (
                        <label>
                            Strassenzustand / Witterung
                            <input
                                type="text"
                                value={values.roadSurfaceConditions}
                                onChange={e => setValues(prev => ({ ...prev!, roadSurfaceConditions: e.target.value }))}
                            />
                        </label>
                    )}

                    {showType && (
                        <label>
                            Typ / Zweck
                            <input
                                type="text"
                                value={values.type}
                                onChange={e => setValues(prev => ({ ...prev!, type: e.target.value }))}
                            />
                        </label>
                    )}
                </div>

                {error && (
                    <p className="error-text" style={{ marginTop: "14px", marginBottom: 0 }}>
                        {error}
                    </p>
                )}

                <div style={{ display: "flex", justifyContent: "flex-end", gap: "12px", marginTop: "24px" }}>
                    <Button
                        className="secondary small"
                        label="Abbrechen"
                        onClick={onCancel}
                        disabled={saving}
                        icon={<X size={16} />}
                    />
                    <Button
                        type="submit"
                        label={saving ? "Speichern..." : "Speichern"}
                        loading={saving}
                        icon={<Check size={16} />}
                    />
                </div>
            </form>
        </div>,
        document.body
    );
}

export default TripsTable;

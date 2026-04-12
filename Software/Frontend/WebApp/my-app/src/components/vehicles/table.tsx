import { useEffect, useState } from "react"
import { useNavigate } from "react-router-dom"
import { deleteTrip, getAllTrips } from "../../services/tripService"
import type { TripSummary } from "../../model/trip"
import "../../styles/table.css"
import { Button } from "../button"

function TripsTable() {
    const navigate = useNavigate();
    const [trips, setTrips] = useState<TripSummary[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        setLoading(true);
        getAllTrips()
            .then(data => setTrips(data))
            .catch(err => setError(err.message))
            .finally(() => setLoading(false));
    }, []);

    const handleDelete = (id: number) => {
        deleteTrip(id)
            .then(() => setTrips(prev => prev.filter(t => t.id !== id)))
            .catch(err => setError(err.message));
    };

    if (loading) return <p>Laden...</p>;
    if (error) return <p>Fehler: {error}</p>;

    return (
        <table className="ridesTable">
            <thead>
                <tr>
                    <th>Startzeit</th>
                    <th>Endzeit</th>
                    <th>Fahrer</th>
                    <th>Fahrzeug</th>
                    <th>Distanz</th>
                    <th>Straßenzustand</th>
                    <th>Aktionen</th>
                </tr>
            </thead>
            <tbody>
                {trips.map(trip => (
                    <tr
                        key={trip.id}
                        onClick={() => navigate(`/trips/${trip.id}`)}
                        style={{ cursor: "pointer" }}
                    >
                        <td>{new Date(trip.startTime).toLocaleString()}</td>
                        <td>{trip.endTime ? new Date(trip.endTime).toLocaleString() : "—"}</td>
                        <td>{trip.accountFname} {trip.accountLname}</td>
                        <td>{trip.vehicleModel} ({trip.licensePlate})</td>
                        <td>{trip.distance} km</td>
                        <td>{trip.roadSurfaceConditions}</td>
                        <td>
                            <Button label="Löschen" stopPropagation={true} onClick={() => handleDelete(trip.id)} />
                        </td>
                    </tr>
                ))}
            </tbody>
        </table>
    );
}

export default TripsTable;
import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { getTripById } from "../services/tripService";
import type { Tripdetailed } from "../model/trip";
import MapView from "../components/MapView";

function TripDetailPage() {
    const { id } = useParams();
    const [trip, setTrip] = useState<Tripdetailed | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        if (!id) return;
        getTripById(Number(id))
            .then(data => setTrip(data))
            .catch(err => setError(err.message))
            .finally(() => setLoading(false));
    }, [id]);

    if (loading) return <p>Laden...</p>;
    if (error) return <p>Fehler: {error}</p>;
    if (!trip) return <p>Fahrt nicht gefunden</p>;

    const { tripSummary, trackingpoints } = trip;

    const route = trackingpoints.map(p => ({ lat: p.lat, lng: p.lng }));

    return (
        <div>
            <h1>Fahrt Details</h1>

            <p><strong>Fahrer:</strong> {tripSummary.accountFirstName} {tripSummary.accountLastName}</p>
            <p><strong>Fahrzeug:</strong> {tripSummary.vehicleModel} ({tripSummary.licensePlate})</p>
            <p><strong>Start:</strong> {new Date(tripSummary.startTime).toLocaleString()}</p>
            <p><strong>Ende:</strong> {tripSummary.endTime ? new Date(tripSummary.endTime).toLocaleString() : "—"}</p>
            <p><strong>Distanz:</strong> {tripSummary.distance} km</p>
            <p><strong>Von:</strong> {tripSummary.startPoint}</p>
            <p><strong>Nach:</strong> {tripSummary.endPoint}</p>
            {tripSummary.furthestPoint && (
                <p><strong>Weitester Punkt:</strong> {tripSummary.furthestPoint}</p>
            )}
            <p><strong>Straßenzustand:</strong> {tripSummary.roadSurfaceConditions}</p>

            {route.length > 0 && <MapView route={route} />}
        </div>
    );
}

export default TripDetailPage;

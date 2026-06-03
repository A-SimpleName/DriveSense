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

    const { tripSummaryDto, trackingpoints } = trip;

    const route = trackingpoints.map(p => ({ lat: p.lat, lng: p.lng }));

    return (
        <div>
            <h1>Fahrt Details</h1>

            <p><strong>Fahrer:</strong> {tripSummaryDto.accountFirstName} {tripSummaryDto.accountLastName}</p>
            <p><strong>Fahrzeug:</strong> {tripSummaryDto.vehicleModel} ({tripSummaryDto.licensePlate})</p>
            <p><strong>Start:</strong> {new Date(tripSummaryDto.startTime).toLocaleString()}</p>
            <p><strong>Ende:</strong> {tripSummaryDto.endTime ? new Date(tripSummaryDto.endTime).toLocaleString() : "—"}</p>
            <p><strong>Distanz:</strong> {tripSummaryDto.distance} km</p>
            <p><strong>Von:</strong> {tripSummaryDto.startPoint}</p>
            <p><strong>Nach:</strong> {tripSummaryDto.endPoint}</p>
            {tripSummaryDto.furthestPoint && (
                <p><strong>Weitester Punkt:</strong> {tripSummaryDto.furthestPoint}</p>
            )}
            <p><strong>Straßenzustand:</strong> {tripSummaryDto.roadSurfaceConditions}</p>

            {route.length > 0 && <MapView route={route} />}
        </div>
    );
}

export default TripDetailPage;

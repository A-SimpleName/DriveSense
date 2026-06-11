import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import MapView from "../components/MapView";
import type { Tripdetailed } from "../model/trip";
import { getTripById } from "../services/tripService";
import { TextSkeleton } from "../components/loadingSkeleton";
import StatCard from "../components/statCard";

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

    if (loading) return <TextSkeleton lines={7} />;
    if (error) return <p>Fehler: {error}</p>;
    if (!trip) return <p>Fahrt nicht gefunden</p>;

    const { tripSummaryDto, trackingpoints } = trip;
    const route = trackingpoints.map(p => ({ lat: p.lat, lng: p.lng }));

    return (
        <div>
            <h1>Fahrt Details</h1>

            <StatCard title="Fahrer:" value={`${tripSummaryDto.accountFirstName} ${tripSummaryDto.accountLastName}`} />
            <StatCard title="Fahrzeug:" value={`${tripSummaryDto.vehicleModel} (${tripSummaryDto.licensePlate})`} />
            <StatCard title="Start:" value={new Date(tripSummaryDto.startTime).toLocaleString()} />
            <StatCard title="Ende:" value={tripSummaryDto.endTime ? new Date(tripSummaryDto.endTime).toLocaleString() : "-"} />
            <StatCard title="Distanz:" value={`${tripSummaryDto.distance} km`} />
            <StatCard title="Von:" value={tripSummaryDto.startPoint} />
            <StatCard title="Nach:" value={tripSummaryDto.endPoint} />
            {tripSummaryDto.furthestPoint && (
                <StatCard title="Weitester Punkt:" value={tripSummaryDto.furthestPoint} />
            )}
            <StatCard title="Strassenzustand:" value={tripSummaryDto.roadSurfaceConditions} />

            {route.length > 0 && <MapView route={route} />}
        </div>
    );
}

export default TripDetailPage;

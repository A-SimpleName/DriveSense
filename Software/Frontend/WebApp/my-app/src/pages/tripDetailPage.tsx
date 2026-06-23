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

    console.log(trip);

    const tripSummary = trip.tripSummary;
    const trackingpoints = trip.trackingpoints;

    const route = trackingpoints.map(p => ({ lat: p.lat, lng: p.lng }));

    const fullName = tripSummary.accountFirstName + " " + tripSummary.accountLastName;

    return (
        <div>
            <h1>Fahrt Details</h1>

            <StatCard title="Fahrer:" value={fullName} />
            <StatCard title="Fahrzeug:" value={`${tripSummary.vehicleModel} (${tripSummary.licensePlate})`} />
            <StatCard title="Start:" value={new Date(tripSummary.startTime).toLocaleString()} />
            <StatCard title="Ende:" value={tripSummary.endTime ? new Date(tripSummary.endTime).toLocaleString() : "-"} />
            <StatCard title="Distanz:" value={`${tripSummary.distance} km`} />
            <StatCard title="Von:" value={tripSummary.startPoint} />
            <StatCard title="Nach:" value={tripSummary.endPoint} />
            {tripSummary.furthestPoint && (
                <StatCard title="Weitester Punkt:" value={tripSummary.furthestPoint} />
            )}
            <StatCard title="Strassenzustand:" value={tripSummary.roadSurfaceConditions} />

            {route.length > 0 && <MapView route={route} />}
        </div>
    );
}

export default TripDetailPage;

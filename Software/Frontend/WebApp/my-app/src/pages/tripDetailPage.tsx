import { useParams } from "react-router-dom";
import MapView from "../components/MapView";
import { getTripById } from "../services/tripService";
import { useEffect, useState } from "react";
import type { Tripdetailed } from "../model/trip";

function TripDetailPage() {
    const { id } = useParams();
    const [error, setError] = useState<string | null>(null);
    const [tripDetailed, setTripDetailed] = useState<Tripdetailed | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (!id) return;

        setLoading(true);
        setError(null);

        getTripById(Number(id))
            .then(data => setTripDetailed(data))
            .catch((err) => setError(err?.message || "Fehler beim Laden der Fahrtdetails"))
            .finally(() => setLoading(false));
    }, [id]);

    if (loading) return <p>Laden...</p>;
    if (error) return <p>Fehler: {error}</p>;
    if (!tripDetailed) return <p>Keine Daten verfügbar</p>;

    const route = tripDetailed.trackingPoints?.map(p => ({
        lat: p.lat,
        lng: p.lng
    })) ?? [];

    return (
        <div>
            <h1>Trip Details</h1>
            <MapView route={route} />
        </div>
    );
}

export default TripDetailPage;
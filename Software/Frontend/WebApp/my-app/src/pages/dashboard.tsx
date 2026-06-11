import StatCard from "../components/statCard";
import { Button } from "../components/button";
import { Link } from "react-router-dom";
import MapView from "../components/MapView";
import { getLatestTrip, getTotalKm, getTripById } from "../services/tripService";
import { useEffect, useState } from "react";
import type { Tripdetailed, TripSummary } from "../model/trip";
import { StatSkeleton } from "../components/loadingSkeleton";

function Dashboard() {
    const [lastTrip, setLastTrip] = useState<TripSummary | null>(null);
    const [lastTripDetailed, setLastTripDetailed] = useState<Tripdetailed | null>(null);
    const [totalKm, setTotalKm] = useState<string>("0 km");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        setLoading(true);
        getLatestTrip()
            .then(data => setLastTrip(data ?? null))
            .catch(err => setError(err.message))
            .finally(() => setLoading(false));
    }, []);

    useEffect(() => {
        getTotalKm()
            .then(km => setTotalKm(`${km} km`))
            .catch(err => setError(err.message));
    }, []);

    useEffect(() => {
        if (!lastTrip) return;
        getTripById(lastTrip.id)
            .then(data => setLastTripDetailed(data))
            .catch(err => setError(err.message));
    }, [lastTrip]);

    if (loading) return <StatSkeleton count={2} />;
    if (error) return <p>Fehler: {error}</p>;

    const lastTripText =
    lastTrip
        ? `${lastTrip.distance} km | ${
            new Date(lastTrip.startTime).toLocaleDateString()
        }`
        : "Keine Fahrten";

    const route =
        lastTripDetailed?.trackingpoints?.map(p => ({
            lat: p.lat,
            lng: p.lng
        })) ?? [];

    return (
        <div>
            <article>
                <StatCard title="Letzte Fahrt" value={lastTripText} />
                <StatCard title="Gesamtstrecke" value={totalKm} />
            </article>

            <article>
                <Link to="/trips">
                    <Button label="Fahrten ansehen" />
                </Link>
                <Link to="/vehicles">
                    <Button label="Fahrzeuge ansehen" />
                </Link>
            </article>

            {route.length > 0 && (
                <MapView route={route} />
            )}
        </div>
    );
}

export default Dashboard;

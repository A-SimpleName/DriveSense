import StatCard from "../components/statCard";
import { Button } from "../components/button";
import { Link } from "react-router-dom";
import MapView from "../components/MapView";
import { getAllTrips, getTotalKm, getTripById } from "../services/tripService";
import { useEffect, useState } from "react";
import type { Tripdetailed, TripSummary } from "../model/trip";

function Dashboard() {
    const [trips, setTrips] = useState<TripSummary[]>([]);
    const [lastTripDetailed, setLastTripDetailed] = useState<Tripdetailed | null>(null);
    const [totalKm, setTotalKm] = useState<string>("0 km");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        setLoading(true);
        getAllTrips()
            .then(data => setTrips(data))
            .catch(err => setError(err.message))
            .finally(() => setLoading(false));
    }, []);

    useEffect(() => {
        getTotalKm()
            .then(km => setTotalKm(`${km} km`))
            .catch(err => setError(err.message));
    }, []);

    useEffect(() => {
        if (trips.length === 0) return;
        const lastTrip = trips[trips.length - 1];
        getTripById(lastTrip.id)
            .then(data => setLastTripDetailed(data))
            .catch(err => setError(err.message));
    }, [trips]);

    if (loading) return <p>Laden...</p>;
    if (error) return <p>Fehler: {error}</p>;

    const lastTripText =
    trips.length > 0
        ? `${trips[trips.length - 1].distance} km | ${
            new Date(trips[trips.length - 1].startTime).toLocaleDateString()
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
import StatCard from "../components/statCard";
import { Button } from "../components/button";
import { Link } from "react-router-dom";
import MapView from "../components/MapView";
import { getAllTrips, getTotalKm, getTripById } from "../services/tripService";
import { useEffect, useState } from "react";
import type { Tripdetailed, TripSummary } from "../model/trip";

function Dashboard() {
    const [trips, setTrips] = useState<TripSummary[]>([])
    const [lastTripDetailed, setLastTripDetailed] = useState<Tripdetailed | null>(null)
    const [totalKm, setTotalKm] = useState<string>("0 km")

    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)

    // Trips laden
    useEffect(() => {
        setLoading(true)

        getAllTrips()
            .then(data => setTrips(data))
            .catch(err => setError(err.message))
            .finally(() => setLoading(false))
    }, [])

    // Gesamt-KM laden
    useEffect(() => {
        getTotalKm()
            .then(km => setTotalKm(`${km} km`))
            .catch(err => setError(err.message))
    }, [])

    // Letzte Fahrt im Detail laden
    useEffect(() => {
        if (trips.length === 0) return

        const lastTrip = trips[trips.length - 1]

        getTripById(lastTrip.id)
            .then(data => setLastTripDetailed(data))
            .catch(err => setError(err.message))
    }, [trips])

    if (loading) return <p>Laden...</p>
    if (error) return <p>Fehler: {error}</p>

    const lastTripText =
        trips.length > 0
            ? `${trips[trips.length - 1].distance} km | ${trips[trips.length - 1].startTime.split("T")[0]}`
            : "Keine Fahrten"

    const route =
    lastTripDetailed?.trackingPoints?.map(p => ({
        lat: p.lat,
        lng: p.lng
    })) ?? []

    return (
        <div>
            <article>
                <StatCard title="Letzte Fahrt" value={lastTripText} />
                <StatCard title="Gesamtstrecke" value={totalKm} />
            </article>

            <article>
                <Link to="/fahrten">
                    <Button label="Fahrten ansehen" />
                </Link>
                <Link to="/fahrzeuge">
                    <Button label="Fahrzeuge ansehen" />
                </Link>
            </article>

            {}
            {route.length > 0 && (
                <MapView route={route} />
            )}
        </div>
    )
}


export default Dashboard;
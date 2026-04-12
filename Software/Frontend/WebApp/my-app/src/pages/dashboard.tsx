import StatCard from "../components/statCard";
import { Button } from "../components/button";
import { Link } from "react-router-dom";
import MapView from "../components/MapView";
<<<<<<< HEAD
import { TripsList } from "../components/trips/trip";

export let rides = [
        { id: 1,  name: "Niklas",date: "2024-01-15",km:120, startLat:88.2082, startLng:95.3738, endLat:48.2105, endLng:16.3801, carId:1,time:"Vormittag"},
        { id: 2,  name: "Niklas",date: "2024-02-20", km:85,  startLat:66.2105, startLng:45.3801, endLat:48.2105, endLng:16.3801,carId:2,time:"Abend" },
        { id: 3,  name: "Niklas",date: "2024-03-10",km:95, startLat: 48.2082, startLng: 16.3738, endLat:48.2105, endLng:16.3801,carId:3,time:"Mittag" },
];
=======
import { getAllTrips, getTotalKm, getTripById } from "../services/tripService";
import { useEffect, useState } from "react";
import type { Tripdetailed, TripSummary } from "../model/trip";
>>>>>>> Christof

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
            .catch(err => setError(err?.message || "Fehler beim Laden der Trips"))
            .finally(() => setLoading(false))
    }, [])

    // Gesamt-KM laden
    useEffect(() => {
        getTotalKm()
            .then(km => setTotalKm(`${km} km`))
            .catch(err => setError(err?.message || "Fehler beim Laden der gesamt Kilometer"))
    }, [])

    // Letzte Fahrt im Detail laden
    useEffect(() => {
        if (trips.length === 0) return

        const lastTrip = trips[trips.length - 1]

        getTripById(lastTrip.id)
            .then(data => setLastTripDetailed(data))
            .catch(err => setError(err?.message || "Fehler beim Laden der Fahrtdetails"))
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
<<<<<<< HEAD
            <StatCard title="letzte Fahrt" value={lastRide}/>
            <MapView
                route={[
                { lat: rides[rides.length - 1].startLat, lng: rides[rides.length - 1].startLng },
                { lat: rides[rides.length - 1].endLat, lng: rides[rides.length - 1].endLng },
                ]}
           />
           <h1>Fahrtenübersicht</h1>
           <TripsList/>
=======

            {}
            {route.length > 0 && (
                <MapView route={route} />
            )}
>>>>>>> Christof
        </div>
    )
}

<<<<<<< HEAD
export default Dashboard; 
=======

export default Dashboard;
>>>>>>> Christof

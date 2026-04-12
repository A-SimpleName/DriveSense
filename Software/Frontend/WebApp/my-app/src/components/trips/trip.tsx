import { useEffect, useState } from "react";
import { getAllTrips } from "../../services/tripService";
import type { TripSummary } from "../../model/trip";

export function TripsList() {
    const [trips, setTrips] = useState<TripSummary[]>([]);

    useEffect(() => {
        getAllTrips()
            .then(data => setTrips(data))
            .catch(err => console.error("Fehler:", err));
    }, []);

    return (
        <ul>
            {trips.map(trip => (
                <li key={trip.id}>
                    {trip.id} - {trip.user_id} - {trip.car_id} - {new Date(trip.startTime).toLocaleString()} - {new Date(trip.endTime).toLocaleString()} - {trip.distance} km - {trip.roadSurfaceConditions}
                </li>
            ))}
        </ul>
    );
}
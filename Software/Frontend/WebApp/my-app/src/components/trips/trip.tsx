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
                    {trip.id} - {trip.user_id} - {trip.car_id} - {new Date(trip.starttime).toLocaleString()} - {new Date(trip.endtime).toLocaleString()} - {trip.distance} km - {trip.weather_main}
                </li>
            ))}
        </ul>
    );
}
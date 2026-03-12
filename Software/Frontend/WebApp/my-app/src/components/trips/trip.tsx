import { useEffect, useState } from "react";
import { getAllTrips } from "../../services/tripService";
import type { TripSummary } from "../../model/trip";

export function TripsList() {
    const [trips, setTrips] = useState<TripSummary[]>([]);

    useEffect(() => {
        getAllTrips()
            .then(data => setTrips(data))
            .catch(err => console.error("Fehler beim Laden der Trips:", err));
    }, []);

    return (
        <ul>
            {trips.map(t => (
                <li key={t.id}>
                    {t.user_id} - {t.car_id} - {t.distance} km
                </li>
            ))}
        </ul>
    );
}
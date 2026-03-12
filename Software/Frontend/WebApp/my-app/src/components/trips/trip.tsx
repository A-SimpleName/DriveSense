import { useEffect, useState } from "react";
import { getAllTrips } from "../../services/tripService";
import type { Trip } from "../../model/trip";

export function TripsList() {

    const [trips, setTrips] = useState<Trip[]>([]);

    useEffect(() => {
        getAllTrips()
            .then(data => setTrips(data))
            .catch(err => console.error("Fehler:", err));
    }, []);

    return (
        <ul>
            {trips.map(trip => (
                <li key={trip.protocolId}>
                    {trip.fname} {trip.lname} - {trip.distance} km
                </li>
            ))}
        </ul>
    );
}
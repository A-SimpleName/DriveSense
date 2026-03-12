import { useEffect, useState } from "react";
import { getAllTrips } from "../../services/tripService";
import type { Trip } from "../../model/trip";
import "../../styles/table.css";

function TripsTable() {

    const [trips, setTrips] = useState<Trip[]>([]);

    useEffect(() => {
        getAllTrips()
            .then(data => setTrips(data))
            .catch(err => console.error("Fehler:", err));
    }, []);

    return (
        <table className="ridesTable">

            <thead>
                <tr>
                    <th>Datum</th>
                    <th>Fahrer</th>
                    <th>km</th>
                    <th>Kennzeichen</th>
                    <th>Start</th>
                    <th>Wendepunkt</th>
                    <th>Ende</th>
                    <th>Wetter</th>
                    <th>Straßenzustand</th>
                    <th>Rolle</th>
                </tr>
            </thead>

            <tbody>

                {trips.map(trip => (

                    <tr key={trip.protocolId}>

                        <td>
                            {new Date(trip.starttime).toLocaleDateString()}
                        </td>

                        <td>
                            {trip.fname} {trip.lname}
                        </td>

                        <td>
                            {trip.distance}
                        </td>

                        <td>
                            {trip.licenseplate}
                        </td>

                        <td>
                            {trip.startPoint}
                        </td>

                        <td>
                            {trip.furthestPoint}
                        </td>

                        <td>
                            {trip.endPoint}
                        </td>

                        <td>
                            {trip.weatherMain}
                        </td>

                        <td>
                            {trip.roadSurfaceConditions}
                        </td>

                        <td>
                            {trip.userRole}
                        </td>

                    </tr>

                ))}

            </tbody>

        </table>
    );
}

export default TripsTable;
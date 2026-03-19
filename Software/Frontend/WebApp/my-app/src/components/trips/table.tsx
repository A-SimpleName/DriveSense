import { useEffect, useState } from "react"
import { useNavigate } from "react-router-dom"
import { getAllTrips } from "../../services/tripService"
import type { TripSummary } from "../../model/trip"
import "../../styles/table.css"


function TripsTable() {

    const navigate = useNavigate()
    const [trips, setTrips] = useState<TripSummary[]>([])

    useEffect(() => {
        getAllTrips()
            .then(data => setTrips(data))
            .catch(err => console.error("Fehler:", err));
    }, []);

    return (
        <table className="ridesTable">

            <thead>
                <tr>
                    <th>id</th>
                    <th>user_id</th>
                    <th>car_id</th>
                    <th>starttime</th>
                    <th>endtime</th>
                    <th>distance</th>
                    <th>weather_main</th>
      
                </tr>
            </thead>

            <tbody>

                {trips.map(trip => (

                    <tr key={trip.id}>

                        <td>{trip.id}</td>

                        <td>{trip.user_id}</td>

                        <td>{trip.car_id}</td>

                        <td>{new Date(trip.startTime).toLocaleString()}</td>
                        <td>{new Date(trip.endTime).toLocaleString()}</td>
                        <td>{trip.user_id}</td>
                        <td>{trip.car_id}</td>
                        <td>{trip.distance} km</td>
                        <td>{trip.roadSurfaceConditions}</td>

                        
                        
                        
                    </tr>

                ))}

            </tbody>

        </table>
    );
}

export default TripsTable;
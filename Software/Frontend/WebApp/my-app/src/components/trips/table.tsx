import { useEffect, useState } from "react"
import { useNavigate } from "react-router-dom"
import { getAllTrips } from "../../services/tripService"
import type { TripSummary } from "../../model/trip"
import "../../styles/table.css"
import { Button } from "../button"

function TripsTable() {

    const navigate = useNavigate()
    const [trips, setTrips] = useState<TripSummary[]>([])

    useEffect(() => {
        getAllTrips()
            .then(data => setTrips(data)) 
            .catch(err => console.error("Fehler beim Laden:", err))
    }, [])

    return (
        <table className="ridesTable">

            <thead>
                <tr>
                    <th>Startzeit</th>
                    <th>Endzeit</th>
                    <th>User</th>
                    <th>Car</th>
                    <th>Distanz</th>
                    <th>Wetter</th>
                    <th>Aktionen</th>
                </tr>
            </thead>

            <tbody>

                {trips.map(trip => (

                    <tr
                        key={trip.id}
                        onClick={() => navigate(`/fahrten/${trip.id}`)}
                    >

                        <td>{new Date(trip.starttime).toLocaleString()}</td>
                        <td>{new Date(trip.endtime).toLocaleString()}</td>
                        <td>{trip.user_id}</td>
                        <td>{trip.car_id}</td>
                        <td>{trip.distance} km</td>
                        <td>{trip.weather_main}</td>

                        <td>
                            <Button label="Bearbeiten" stopPropagation={true}/>
                            <Button label="Löschen" stopPropagation={true}/>
                        </td>

                    </tr>

                ))}

            </tbody>

        </table>
    )
}

export default TripsTable
import { useEffect, useState } from "react"
import { useNavigate } from "react-router-dom"
import { deleteTrip, getAllTrips } from "../../services/tripService"
import type { TripSummary } from "../../model/trip"
import "../../styles/table.css"
import { Button } from "../button"

function TripsTable() {
    const navigate = useNavigate()
    const [trips, setTrips] = useState<TripSummary[]>([])
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        setLoading(true)
        getAllTrips()
            .then(data => setTrips(data)) 
            .catch(err => setError(err.message))
            .finally(() => setLoading(false))
    }, [])

    const handleDelete = (id: number) => {
        deleteTrip(id)
            .then(() => setTrips(prev => prev.filter(t => t.id !== id)))
            .catch(err => setError(err.message))
    }

    if (loading) return <p>Laden...</p>
    if (error) return <p>Fehler: {error}</p>

    return (
        <table className="ridesTable">

            <thead>
                <tr>
                    <th>Startzeit</th>
                    <th>Endzeit</th>
                    <th>Fahrer</th>
                    <th>Fahrzeug</th>
                    <th>Kennzeichen</th>
                    <th colSpan={2}>Kilometerstand</th>
                    <th>Distanz</th>
                    <th>Fahrbahnzustand</th>
                    <th>Strecke</th>
                    <th>Aktionen</th>
                </tr>
                <tr>
                    <th></th>
                    <th></th>
                    <th></th>
                    <th></th>
                    <th></th>
                    <th>Von</th>
                    <th>Bis</th>
                    <th></th>
                    <th></th>
                    <th></th>
                    <th></th>
                </tr>
            </thead>

            <tbody>

                {trips.map(trip => (

                    <tr
                        key={trip.id}
                        onClick={() => navigate(`/trips/${trip.id}`)}
                    >

                        <td>{new Date(trip.startTime).toLocaleString()}</td>
                        <td>{new Date(trip.endTime).toLocaleString()}</td>
                        <td>{trip.accountFname} {trip.accountLname}</td>
                        <td>{trip.vehicleModel}</td>
                        <td>{trip.licensePlate}</td>
                        <td>{trip.startMileage} km</td>
                        <td>{trip.endMileage} km</td>
                        <td>{trip.distance} km</td>
                        <td>{trip.roadSurfaceConditions}</td>
                        <td>
                            {trip.furthestPoint && trip.furthestPoint?.toLowerCase() !== trip.endPoint?.toLowerCase()
                                ? `${trip.startPoint} - ${trip.furthestPoint} - ${trip.endPoint}`
                                : `${trip.startPoint} - ${trip.endPoint}`}
                        </td>
                        <td>
                            <Button label="Bearbeiten" stopPropagation={true} />
                            <Button label="Löschen" stopPropagation={true} onClick={() => handleDelete(trip.id)} />
                        </td>

                    </tr>

                ))}

            </tbody>

        </table>
    )
}

export default TripsTable

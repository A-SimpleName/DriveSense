import { useEffect, useState } from "react"
import { getAllVehicles, deleteVehicle, updateVehicle} from "../../services/vehicleService"
import type { Vehicle } from "../../model/vehicle"
import "../../styles/table.css"
import { Button } from "../button"

function VehiclesTable() {
    const [vehicles, setVehicles] = useState<Vehicle[]>([])

    useEffect(() => {
        getAllVehicles()
            .then(data => setVehicles(data))
            .catch(err => console.error("Fehler beim Laden:", err))
    }, [])

    return (
        <table>
            <thead>
                <tr>
                    <th>Model</th>
                    <th>Profil</th>
                    <th>Kennzeichen</th>
                    <th>Kilometerstand</th>
                    <th>Aktionen</th>
                </tr>
            </thead>
            <tbody>
                {vehicles.map(vehicle => (
                    <tr key={vehicle.id}>
                        <td>{vehicle.model}</td>
                        <td>{vehicle.profileName}</td>
                        <td>{vehicle.licensePlate}</td>
                        <td>{vehicle.mileage} km</td>
                        <td>
                            <Button label="Bearbeiten" stopPropagation={true} onClick={() => updateVehicle(vehicle.id, vehicle)}/>
                            <Button label="Löschen" stopPropagation={true} onClick={() => deleteVehicle(vehicle.id)}/>
                        </td>
                    </tr>
                ))}
            </tbody>
        </table>
    )
}

export default VehiclesTable
import { useEffect, useState } from "react";
import { getAllVehicles } from "../../services/vehicleService";
import type { Vehicle } from "../../model/vehicle";
import { Button } from "../button";

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
                    <th>Kennzeichen</th>
                    <th>Kilometerstand</th>
                    <th colSpan={2}>Aktionen</th>
                </tr>
            </thead>

            <tbody>

                {vehicles.map(vehicle => (

                    <tr key={vehicle.id}>

                        <td>{vehicle.model}</td>
                        <td>{vehicle.licenseplate}</td>
                        <td>{vehicle.mileage} km</td>

                        <td>
                            <Button label="Bearbeiten"/>
                        </td>

                        <td>
                            <Button label="Löschen"/>
                        </td>

                    </tr>

                ))}

            </tbody>

        </table>
    );
}

export default VehiclesTable;
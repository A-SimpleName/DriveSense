import { vehicles } from "../../pages/vehicles";
import { Button } from "../button";

function VehiclesTable() {
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
                        <td>{vehicle.name}</td>
                        <td>{vehicle.licensePlate}</td>
                        <td>{vehicle.kilometers}</td>
                        <td><Button label="Bearbeiten"></Button></td>
                        <td><Button label="Löschen"></Button></td>
                    </tr>
                ))}
            </tbody>
        </table>
    );
}

export default VehiclesTable;
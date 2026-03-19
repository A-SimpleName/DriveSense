import { useEffect, useState } from 'react';
import type { Vehicle } from '../../model/vehicle';
import { getAllVehicles } from '../../services/vehicleService';


export function VehicleList() {
    const [vehicles, setVehicles] = useState<Vehicle[]>([]);

    useEffect(() => {
        getAllVehicles()
            .then(data => setVehicles(data))
            .catch(err => console.error("Fehler beim Laden der Fahrzeuge:", err));
    }, []);

    return (
        <ul>
            {vehicles.map(v => (
                <li key={v.id}>
                    {v.id} - {v.model} - {v.profileName} - {v.licencePlate} - {v.mileage}
                </li>
            ))}
        </ul>
    );
}
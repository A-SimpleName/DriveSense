import { useState } from "react"
import { Button } from "../components/button"
import VehiclesTable from "../components/vehicles/table"
import { VehicleAddForm } from "../components/vehicles/vehicleAddForm"

function Vehicles() {
    const [showForm, setShowForm] = useState(false);
    const [reloadKey, setReloadKey] = useState(0);

    return (
        <div>
            <h1>Fahrzeuge</h1>

            <Button
                label="+ Fahrzeug hinzufügen"
                onClick={() => setShowForm(true)}
            />

            {showForm && (
                <VehicleAddForm
                    onClose={() => setShowForm(false)}
                    onSuccess={() => setReloadKey(prev => prev + 1)}
                />
            )}

            <VehiclesTable key={reloadKey} />
        </div>
    )
}

export default Vehicles

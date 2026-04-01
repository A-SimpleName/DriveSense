import { useState } from "react"
import { Button } from "../components/button"
import VehiclesTable from "../components/vehicles/table"
import { VehicleAddForm } from "../components/vehicles/vehicleAddForm"

function Vehicles() {

    const [showForm, setShowForm] = useState(false)

    return (
        <div>
            <h1>Fahrzeuge</h1>

            <Button
                label="+ Fahrzeug hinzufügen"
                onClick={() => setShowForm(true)}
            />

            {showForm && <VehicleAddForm />}

            <VehiclesTable />
        </div>
    )
}

export default Vehicles
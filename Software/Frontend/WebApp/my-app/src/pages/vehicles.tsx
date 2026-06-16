import { useState } from "react"
import { Button } from "../components/button"
import VehiclesTable from "../components/vehicles/table"
import { VehicleAddForm } from "../components/vehicles/vehicleAddForm"
import { VehicleInviteAcceptForm } from "../components/vehicles/VehicleInviteAcceptForm"

function Vehicles() {
    const [showForm, setShowForm] = useState(false);
    const [showInviteAccept, setShowInviteAccept] = useState(false);
    const [reloadKey, setReloadKey] = useState(0);

    return (
        <div>
            <h1>Fahrzeuge</h1>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginBottom: '10px' }}>

                <Button
                    label="Einladung annehmen"
                    className="small"
                    onClick={() => setShowInviteAccept(true)}
                />

                <Button
                    label="+"
                    className="small icon"
                    title="Fahrzeug hinzufügen"
                    onClick={() => setShowForm(true)}
                />
            </div>

            {showInviteAccept && (
                <VehicleInviteAcceptForm
                    onClose={() => setShowInviteAccept(false)}
                    onSuccess={() => {
                        setShowInviteAccept(false);
                        setReloadKey(prev => prev + 1);
                    }}
                />
            )}

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
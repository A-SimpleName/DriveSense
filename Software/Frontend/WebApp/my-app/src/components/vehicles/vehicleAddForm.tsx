import { AddForm } from "../addForm"
import { createVehicle } from "../../services/vehicleService"
 
interface VehicleProps {
    onClose: () => void
    onSuccess: () => void
}
 
export function VehicleAddForm({ onClose, onSuccess }: VehicleProps) {
    return (
        <AddForm
            title="Fahrzeug hinzufügen"
            fields={[
                { type: "text",   key: "model",        label: "Modell" },
                { type: "text",   key: "licensePlate", label: "Kennzeichen" },
                { type: "number", key: "mileage",      label: "Kilometerstand", defaultValue: 0 },
            ]}
            onClose={onClose}
            onSubmit={async ({ model, licensePlate, mileage }) => {
                await createVehicle({ model: String(model), licensePlate: String(licensePlate), mileage: Number(mileage) })
                onSuccess()
            }}
        />
    )
}
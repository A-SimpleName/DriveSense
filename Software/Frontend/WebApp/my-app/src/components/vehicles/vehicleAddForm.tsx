import { useState } from "react"
import "../../styles/addForms.css"
import { createVehicle } from "../../services/vehicleService";

export function VehicleAddForm() {
    console.log("VehicleAddForm gerendert");
    const [model, setModel] = useState("");
    const [licensePlate, setLicensePlate] = useState("");
    const [mileage, setMileage] = useState(0);

    async function handleSubmit(e: React.FormEvent) {
        console.log("vehicle submitted");
        e.preventDefault();

        try {
            const res = await createVehicle({
                model,
                licensePlate,
                mileage
            });

            console.log("Erfolg:", res);

        } catch (err) {
            console.error("Fehler beim Erstellen:", err);
        }
    }

    return (
        <div className="vehicleAddForm">
            <h2>Fahrzeug hinzufügen</h2>

            <form onSubmit={handleSubmit}>
                <table>
                    <tbody>
                        <tr>
                            <td><label>Modell</label></td>
                            <td><input
                                type="text"
                                value={model}
                                onChange={(e) => setModel(e.target.value)}
                            /></td>
                        </tr>
                        <tr>
                            <td><label>Kennzeichen</label></td>
                            <td><input
                                type="text"
                                value={licensePlate}
                                onChange={(e) => setLicensePlate(e.target.value)}
                            /></td>
                        </tr>
                        <tr>
                            <td><label>Kilometerstand</label></td>
                            <td><input
                                type="number"
                                value={mileage}
                                onChange={(e) => setMileage(Number(e.target.value))}
                            /></td>
                        </tr>
                    </tbody>
                </table>
                <button type="submit">Hinzufügen</button>
            </form>
        </div>
    )
}
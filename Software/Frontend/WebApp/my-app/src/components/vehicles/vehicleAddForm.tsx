import { useState } from "react"
import { createVehicle } from "../../services/vehicleService"
import "../../styles/addForms.css"

export function VehicleAddForm() {
    console.log("VehicleAddForm gerendert");
    const [model, setModel] = useState("");
    const [profileName, setProfileName] = useState("");
    const [licencePlate, setLicencePlate] = useState("");
    const [mileage, setMileage] = useState(0);

    function handleSubmit(e: React.FormEvent) {
        e.preventDefault();

        createVehicle({
            model,
            profileName,
            licencePlate,
            mileage
        });
    }

    return (
        <div className="vehicleAddForm">
            <h2>Fahrzeug hinzufügen</h2>

            <form onSubmit={handleSubmit}>
                <table>
                    <tr>
                        <td><label>Modell</label></td>
                        <td><input
                            type="text"
                            value={model}
                            onChange={(e) => setModel(e.target.value)}
                        /></td>
                    </tr>
                    <tr>
                        <td><label>Profilname</label></td>
                        <td><input
                            type="text"
                            value={profileName}
                            onChange={(e) => setProfileName(e.target.value)}
                        /></td>
                    </tr>
                    <tr>
                        <td><label>Kennzeichen</label></td>
                        <td><input
                            type="text"
                            value={licencePlate}
                            onChange={(e) => setLicencePlate(e.target.value)}
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
                </table>
                <button type="submit">Hinzufügen</button>

            </form>
        </div>
    )
}
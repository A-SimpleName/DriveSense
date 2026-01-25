import { Button } from "../components/button";
import VehiclesTable from "../components/vehicles/table";

export let vehicles = [
    { id: 1, name: "Auto A",licensePlate: "AM08092" , kilometers: 97740 },
    { id: 2, name: "Auto B",licensePlate: "PM12345" , kilometers: 45230 },
    { id: 3, name: "Auto C",licensePlate: "LM67890" , kilometers: 12350 },
];

function Vehicles() {
    
    return (
        <div>
            <h1>Fahrzeuge</h1>
            <Button label={"+ Fahrzeuge hinzufügen"}/>
            <VehiclesTable />
        </div>
    );
}

export default Vehicles;
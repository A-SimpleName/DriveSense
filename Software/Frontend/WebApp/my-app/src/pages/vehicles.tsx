import { Button } from "../components/button";
import VehiclesTable from "../components/vehicles/table";

function Vehicles() {

    return (
        <div>

            <h1>Fahrzeuge</h1>

            <Button label="+ Fahrzeug hinzufügen"/>

            <VehiclesTable />

        </div>
    );
}

export default Vehicles;
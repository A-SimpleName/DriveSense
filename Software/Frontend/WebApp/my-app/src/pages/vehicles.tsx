import { Button } from "../components/button";
import VehiclesTable from "../components/vehicles/table";
import { VehicleList } from "../components/vehicles/vehicle";

function Vehicles() {
    
    return (
        <div>
            <h1>Fahrzeuge</h1>
            <Button label={"+ Fahrzeuge hinzufügen"}/>
            <VehiclesTable />
      
            <VehicleList />
        </div>
    );
}

export default Vehicles;
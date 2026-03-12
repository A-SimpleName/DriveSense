import TripsTable from "../components/trips/table";
import { Button } from "../components/button";

function Trips() {

    return (
        <div>

            <h1>Fahrtenprotokoll</h1>

            <Button label="+ Fahrt hinzufügen"/>

            <TripsTable />

        </div>
    );
}

export default Trips;
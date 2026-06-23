import TripsTable from "../components/trips/table";
import "../styles/pageLayout.css";

function Trips() {
    return (
        <div>
            <div className="page-header">
                <h1>Fahrten</h1>
            </div>
            <TripsTable />
        </div>
    );
}

export default Trips;
import { rides } from "../../pages/dashboard";
import { vehicles } from "../../pages/vehicles";
import { useNavigate } from "react-router-dom";
import "../../styles/table.css";
import { Button } from "../button";

function RidesTable() {
    const navigate = useNavigate();

    return (
        <table className="ridesTable">
            <thead>
                <tr>
                    <th rowSpan={2}>Datum</th>
                    <th rowSpan={2}>Name</th>
                    <th rowSpan={2}>Gefahrene Km</th>
                    <th rowSpan={1} colSpan={2}>Kilometerstand</th>
                    <th rowSpan={2}>Kennzeichen</th>
                    <th rowSpan={2}>Tageszeit</th>
                    <th rowSpan={2} colSpan={2}>Aktionen</th>
                </tr>
                <tr>
                    <th>Von</th>
                    <th>Bis</th>
                </tr>
            </thead>
            <tbody>
                {rides.map(ride => (
                    <tr key={ride.id}
                    onClick={() => navigate(`/fahrten/${ride.id}`)}
                    >
                        <td>{ride.date}</td>
                        <td>{ride.name}</td>
                        <td>{ride.km}</td>
                        <td>{vehicles.find(v => v.id === ride.carId)?.kilometers}</td>
                        <td>{(vehicles.find(v => v.id === ride.carId)?.kilometers || 0) + ride.km}</td>
                        <td>{vehicles.find(v => v.id === ride.carId)?.licensePlate}</td>
                        <td>{ride.time}</td> 
                        <td><Button label="Bearbeiten" stopPropagation={true}></Button></td>
                        <td><Button label="Löschen" stopPropagation={true}></Button></td>    
                    </tr>
                ))}
            </tbody>
        </table>
    );
}

export default RidesTable;
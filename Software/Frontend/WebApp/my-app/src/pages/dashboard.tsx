import StatCard from "../components/statCard";
import { Button } from "../components/button";
import { Link } from "react-router-dom";

function Dashboard() {
    let rides = [
        { id: 1,  date: "2024-01-15",km:120 },
        { id: 2,  date: "2024-02-20", km:85 },
        { id: 3,  date: "2024-03-10",km:95 },
    ];
    let lastRide = rides[rides.length - 1].km.toString() + " km | " + rides[rides.length - 1].date;
    let totalKm = rides.reduce((total, ride) => total + ride.km, 0).toString() + " km";
    return (
        <div>
            <article>
                <StatCard title="Letzte Fahrt" value= {lastRide}/>
                <StatCard title="Gesamtstrecke: " value= {totalKm}/>
            </article>
            <article>
                <Link to="/trips"><Button label={"Fahrten ansehen"}/></Link>
                <Link to="/vehicles"><Button label={"Fahrzeuge ansehen"}/></Link>
            </article>
        </div>
    );
}

export default Dashboard;
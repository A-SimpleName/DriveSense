import StatCard from "../components/statCard";
import { Button } from "../components/button";
import { Link } from "react-router-dom";
import MapView from "../components/MapView";
import { TripsList } from "../components/trip";

export let rides = [
        { id: 1,  name: "Niklas",date: "2024-01-15",km:120, startLat:88.2082, startLng:95.3738, endLat:48.2105, endLng:16.3801, carId:1,time:"Vormittag"},
        { id: 2,  name: "Niklas",date: "2024-02-20", km:85,  startLat:66.2105, startLng:45.3801, endLat:48.2105, endLng:16.3801,carId:2,time:"Abend"},
        { id: 3,  name: "Niklas",date: "2024-03-10",km:95, startLat: 48.2082, startLng: 16.3738, endLat:48.2105, endLng:16.3801,carId:3,time:"Mittag" },
];

function Dashboard() {
    let lastRide = rides[rides.length - 1].km.toString() + " km | " + rides[rides.length - 1].date;
    let totalKm = rides.reduce((total, ride) => total + ride.km, 0).toString() + " km";
    
    return (
        <div>
            <article>
                <div>
                    <StatCard title="Letzte Fahrt" value= {lastRide}/>
                </div>
                <div>
                    <StatCard title="Gesamtstrecke: " value= {totalKm}/>
                </div>
            </article>
            <article>
                <Link to="/fahrten"><Button label={"Fahrten ansehen"}/></Link>
                <Link to="/fahrzeuge"><Button label={"Fahrzeuge ansehen"}/></Link>
            </article>
            <StatCard title="letzte Fahrt" value={lastRide}/>
            <MapView
                route={[
                { lat: rides[rides.length - 1].startLat, lng: rides[rides.length - 1].startLng },
                { lat: rides[rides.length - 1].endLat, lng: rides[rides.length - 1].endLng },
                ]}
           />
           <h1>Fahrtenübersicht</h1>
           <TripsList />
        </div>
    );
}

export default Dashboard;
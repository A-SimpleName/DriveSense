import { useParams } from "react-router-dom";
import {rides} from "./dashboard";
import MapView from "../components/MapView";

function RideDetailPage() {
    const { id } = useParams();
    const ride = rides.find(ride => ride.id === Number(id));
    return (  
        <div>
            <h1>Ride Details</h1>  
            <MapView
                route={[
                { lat: ride!.startLat, lng: ride!.startLng },
                { lat: ride!.endLat, lng: ride!.endLng },
                ]}
            />     
        </div>  
    );
}

export default RideDetailPage;
import { GoogleMap,Polyline,Marker,useJsApiLoader } from "@react-google-maps/api";
import "./../styles/map.css";
import { CardSkeleton } from "./loadingSkeleton";
import { snapToRoads } from "../services/roadsApi";
import { useEffect, useState } from "react";

type LatLng = {
    lat: number;
    lng: number;
}

type MapViewProps = {
    route: LatLng[];
}


export default function MapView({ route }: MapViewProps) {
    const [snappedRoute, setSnappedRoute] = useState(route);

    useEffect(() => {
        if (route.length > 1) {
            snapToRoads(route)
                .then(setSnappedRoute)
                .catch(console.error);
        }
    }, [route]);

    const { isLoaded } = useJsApiLoader({
        id: 'google-map-script',
        googleMapsApiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string,
    })
    
    if (!isLoaded) {
    return <CardSkeleton />;
    }
    return (
        <div className="map">
            <GoogleMap
            mapContainerClassName="googleMap"
            center={snappedRoute[0]}
            zoom={12}
            >
                <Polyline path={snappedRoute} />
                <Marker position={snappedRoute[0]} label="Start" />
                <Marker position={snappedRoute[snappedRoute.length - 1]} label="Ziel" />
            </GoogleMap>
        </div>
    )
}
import { GoogleMap,Polyline,Marker,useJsApiLoader } from "@react-google-maps/api";
import "./../styles/map.css";

type LatLng = {
    lat: number;
    lng: number;
}

type MapViewProps = {
    route: LatLng[];
}


export default function MapView({ route }: MapViewProps) {
    const { isLoaded } = useJsApiLoader({
        id: 'google-map-script',
        googleMapsApiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string,
    })
    
    if (!isLoaded) {
        return <p>Karte lädt...</p>
    }
    return (
        <div className="map">
            <GoogleMap
            mapContainerClassName="googleMap"
            center={route[0]}
            zoom={12}
            >
                <Polyline path={route} />
                <Marker position={route[0]} label="Start" />
                <Marker position={route[route.length - 1]} label="Ziel" />
            </GoogleMap>
        </div>
    )
}
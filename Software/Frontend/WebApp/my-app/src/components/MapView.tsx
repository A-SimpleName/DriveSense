import { GoogleMap,Polyline,Marker,useJsApiLoader } from "@react-google-maps/api";

type LatLng = {
    lat: number;
    lng: number;
}

type MapViewProps = {
    route: LatLng[];
}

const conainerStyle: React.CSSProperties = {
    width: '100%',
    height: '400px'
};

export default function MapView({ route }: MapViewProps) {
    const { isLoaded } = useJsApiLoader({
        id: 'google-map-script',
        googleMapsApiKey: import.meta.env.REACT_APP_GOOGLE_MAPS_API_KEY as string,
    })
    
    if (!isLoaded) {
        return <p>Karte lädt...</p>
    }
    return (
        <GoogleMap
        mapContainerStyle={conainerStyle}
        center={route[0]}
        zoom={12}
        >
            <Polyline path={route} />
            <Marker position={route[0]} label="Start" />
            <Marker position={route[route.length - 1]} label="Ziel" />
        </GoogleMap>
    )
}
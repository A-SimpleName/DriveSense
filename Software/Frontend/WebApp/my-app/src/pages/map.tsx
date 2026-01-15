import MapView from "../components/MapView";

function Map() {
  return (
    <div>
      <h1>Map</h1>
      <p>
        Demo MAP: CORDS: lat: 48.2082, lng: 16.3738; lat: 48.2105, lng: 16.3801
      </p>

      <MapView
        route={[
          { lat: 48.2082, lng: 16.3738 },
          { lat: 48.2105, lng: 16.3801 },
        ]}
      />
    </div>
  );
}

export default Map;
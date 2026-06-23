type LatLng = {
    lat: number;
    lng: number;
};

async function snapChunk(points: LatLng[]) {
    const path = points
        .map(p => `${p.lat},${p.lng}`)
        .join("|");

    const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;

    const response = await fetch(
        `https://roads.googleapis.com/v1/snapToRoads?path=${path}&interpolate=true&key=${apiKey}`
    );

    if (!response.ok) {
        throw new Error("Snap to Roads API Fehler");
    }

    const data = await response.json();

    return (
        data.snappedPoints?.map((p: any) => ({
            lat: p.location.latitude,
            lng: p.location.longitude,
        })) ?? []
    );
}

export async function snapToRoads(route: LatLng[]) {
    const MAX_POINTS = 100;

    if (route.length <= MAX_POINTS) {
        return snapChunk(route);
    }

    const result: LatLng[] = [];

    for (let i = 0; i < route.length; i += MAX_POINTS - 1) {
        const chunk = route.slice(i, i + MAX_POINTS);

        const snapped = await snapChunk(chunk);

        // Doppelte Übergangspunkte vermeiden
        if (result.length > 0 && snapped.length > 0) {
            snapped.shift();
        }

        result.push(...snapped);
    }

    return result;
}
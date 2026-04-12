import http from "../api/httpService"
import { getErrorMessage } from "../errorHandling/getErrorMessage";
import type { Tripdetailed, TripSummary } from "../model/trip"

<<<<<<< HEAD
export const getAllTrips = () => http.get<TripSummary[]>("/trips");
export const getTripById = (id: number) => http.get<TripSummary>(`/trips/${id}`);
export const getTotalKm = (id: number) => http.get<{ totalKm: number }>(`/trips/${id}/totalKm`);
export const createTrip = (trip: Omit<TripSummary, "id">) => http.post("/trips", trip);
export const updateTrip = (id: number, trip: Omit<TripSummary, "id">) => http.put(`/trips/${id}`, trip);
export const deleteTrip = (id: number) => http.delete(`/trips/${id}`);
export const getTripsByProfile = async (profileId: number) => {
    const res = await http.get(`/trips?profile_id=${profileId}`);
    return res; // hier anpassen, falls nötig, je nachdem wie die API antwortet
};
=======
async function handleRequest<T>(request: Promise<T>): Promise<T> {
    try {
        const res = await request;
        return res;
    } catch (err: any) {
        throw {
            message: getErrorMessage(err),
            fieldErrors: err?.errors || null
        };
    }
}

export const getAllTrips = () =>
    handleRequest<TripSummary[]>(http.get("/trips"));

export const getTripById = (id: number) =>
    handleRequest<Tripdetailed>(http.get(`/trips/${id}`));

export const getTotalKm = () =>
    handleRequest<number>(http.get("/totalKm"));

export const createTrip = (trip: Omit<TripSummary, "id">) =>
    handleRequest<TripSummary>(http.post("/trips", trip));

export const updateTrip = (id: number, trip: Omit<TripSummary, "id">) =>
    handleRequest<TripSummary>(http.put(`/trips/${id}`, trip));

export const deleteTrip = (id: number) =>
    handleRequest<void>(http.delete(`/trips/${id}`));
>>>>>>> Christof

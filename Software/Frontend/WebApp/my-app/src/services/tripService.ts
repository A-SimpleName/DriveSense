import http from "../api/httpService"
import type { Tripdetailed, TripSummary } from "../model/trip"

export const getAllTrips = () => http.get<TripSummary[]>("/trips");
export const getTripById = (id: number) => http.get<Tripdetailed>(`/trips/${id}`);
export const getTotalKm = () => http.get<{ totalKm: number }>(`/totalKm`);
export const createTrip = (trip: Omit<TripSummary, "id">) => http.post("/trips", trip);
export const updateTrip = (id: number, trip: Omit<TripSummary, "id">) => http.put(`/trips/${id}`, trip);
export const deleteTrip = (id: number) => http.delete(`/trips/${id}`);

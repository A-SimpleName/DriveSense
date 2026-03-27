import http from "../api/httpService"
import type { TripSummary } from "../model/trip"

export const getAllTrips = () => http.get<TripSummary[]>("/trips");
export const getTripById = (id: number) => http.get<TripSummary>(`/trips/${id}`);
export const getTotalKm = (id: number) => http.get<{ totalKm: number }>(`/trips/${id}/totalKm`);
export const createTrip = (trip: Omit<TripSummary, "id">) => http.post("/trips", trip);
export const updateTrip = (id: number, trip: Omit<TripSummary, "id">) => http.put(`/trips/${id}`, trip);
export const deleteTrip = (id: number) => http.delete(`/trips/${id}`);

import http from "../api/httpService"
import type { Trip } from "../model/trip"

export const getAllTrips = () => http.get<Trip[]>("/trips");
export const getTripById = (id: number) => http.get<Trip>(`/trips/${id}`);
export const createTrip = (trip: Omit<Trip, "id">) => http.post("/trips", trip);
export const updateTrip = (id: number, trip: Omit<Trip, "id">) => http.put(`/trips/${id}`, trip);
export const deleteTrip = (id: number) => http.delete(`/trips/${id}`);

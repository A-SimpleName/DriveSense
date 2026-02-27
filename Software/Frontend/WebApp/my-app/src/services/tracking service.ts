import http from "./httpService"
import type { Trip } from "../model/trip"

export const getAllTrackings = () => http.get<Trip[]>("/trips")
export const getTrackingById = (id: number) => http.get<Trip>(`/trips/${id}`);
export const createTracking = (tracking: Omit<Trip, "id">) => http.post("/trips", tracking);
export const updateTracking = (id: number, tracking: Omit<Trip, "id">) => http.put(`/trips/${id}`, tracking);
export const deleteTracking = (id: number) => http.delete(`/trips/${id}`);

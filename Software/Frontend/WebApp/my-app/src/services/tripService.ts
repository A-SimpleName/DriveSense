import http from "../api/httpService"
import { getErrorMessage } from "../errorHandling/getErrorMessage";
import type { Tripdetailed, TripSummary } from "../model/trip"

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

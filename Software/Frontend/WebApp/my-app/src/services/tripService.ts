import http from "../api/httpService"
import type { Tripdetailed, TripSummary } from "../model/trip"
import { getErrorMessage } from "../errorHandling/getErrorMessage"

// auslagern in die HTTP methdode am besten
async function handleRequest<T>(request: Promise<T>): Promise<T> {
    try {
        return await request;
    } catch (err: any) {
        throw {
            message: getErrorMessage(err),
            fieldErrors: err?.errors || null
        };
    }
}

export const getAllTrips = () =>
    handleRequest<TripSummary[]>(http.get<TripSummary[]>("/trips"));

export const getTripById = (id: number) =>
    handleRequest<Tripdetailed>(http.get<Tripdetailed>(`/trips/${id}`));

export const getTotalKm = () =>
    handleRequest<number>(http.get<number>("/trips/totalKm"));

export const createTrip = (trip: Omit<TripSummary, "id">) =>
    handleRequest<void>(http.post("/trips", trip));

export const updateTrip = (id: number, trip: Omit<TripSummary, "id">) =>
    handleRequest<void>(http.put(`/trips/${id}`, trip));

export const deleteTrip = (id: number) =>
    handleRequest<void>(http.delete(`/trips/${id}`));
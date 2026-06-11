import http from "../api/httpService"
import type { Tripdetailed, TripSummary, TripSummaryDto } from "../model/trip"
import { toAppError } from "../errorHandling/errorHandling";

// auslagern in die HTTP methdode am besten
async function handleRequest<T>(request: Promise<T>): Promise<T> {
    try {
        return await request;
    } catch (err: any) {
        throw toAppError(err);
    }
}

export const getAllTrips = () =>
    handleRequest<TripSummaryDto[]>(http.get<TripSummaryDto[]>("/trips"));

export const getLatestTrip = () =>
    handleRequest<TripSummary | undefined>(http.get<TripSummary | undefined>("/trips/latest"));

export const getTripById = (id: number) =>
    handleRequest<Tripdetailed>(http.get<Tripdetailed>(`/trips/${id}`));

export const getTotalKm = () =>
    handleRequest<number>(http.get<number>("/trips/totalKm"));

export const getTotalDuration = () =>
    handleRequest<number>(http.get<number>("/trips/totalDuration"));

export const createTrip = (trip: Omit<TripSummary, "id">) =>
    handleRequest<void>(http.post("/trips", trip));

export const updateTrip = (id: number, trip: Omit<TripSummary, "id">) =>
    handleRequest<void>(http.put(`/trips/${id}`, trip));

export const deleteTrip = (id: number) =>
    handleRequest<void>(http.delete(`/trips/${id}`));

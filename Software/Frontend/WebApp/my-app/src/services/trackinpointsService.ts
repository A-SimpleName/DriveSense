import http from "../api/httpService"
import { toAppError } from "../errorHandling/errorHandling";
import type { Trackingpoint } from "../model/trackingpoint"

async function handleRequest<T>(request: Promise<T>): Promise<T> {
    try {
        return await request;
    } catch (err: any) {
        throw toAppError(err);
    }
}

export const getAllTrackingpoints = () => handleRequest(http.get<Trackingpoint[]>("/trackingpoints"))
export const getTrackingpointById = (id: number) => handleRequest(http.get<Trackingpoint>(`/trackingpoints/${id}`))
export const createTrackingpoint = (trackingpoint: Omit<Trackingpoint, "id">) => handleRequest(http.post("/trackingpoints", trackingpoint))
export const updateTrackingpoint = (id: number, trackingpoint: Omit<Trackingpoint, "id">) => handleRequest(http.put(`/trackingpoints/${id}`, trackingpoint))
export const deleteTrackingpoint = (id: number) => handleRequest(http.delete(`/trackingpoints/${id}`));


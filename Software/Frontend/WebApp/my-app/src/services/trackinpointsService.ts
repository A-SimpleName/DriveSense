import http from "./httpService"
import type { Trackingpoint } from "../model/trackingpoint"

export const getAllTrackingpoints = () => http.get<Trackingpoint[]>("/trackingpoints")
export const getTrackingpointById = (id: number) => http.get<Trackingpoint>(`/trackingpoints/${id}`);
export const createTrackingpoint = (trackingpoint: Omit<Trackingpoint, "id">) => http.post("/trackingpoints", trackingpoint);
export const updateTrackingpoint = (id: number, trackingpoint: Omit<Trackingpoint, "id">) => http.put(`/trackingpoints/${id}`, trackingpoint);
export const deleteTrackingpoint = (id: number) => http.delete(`/trackingpoints/${id}`);
import type { Vehicle } from "../model/vehicle";
import http from "../api/httpService";  
import type { CreateVehicle } from "../model/vehicle";
import { toAppError } from "../errorHandling/errorHandling";

async function handleRequest<T>(request: Promise<T>): Promise<T> {
    try {
        return await request;
    } catch (err: any) {
        throw toAppError(err);
    }
}


export const getAllVehicles = () =>
    handleRequest<Vehicle[]>(http.get<Vehicle[]>("/vehicles/account"));

export const getVehicleById = (id: number) =>
    handleRequest<Vehicle>(http.get<Vehicle>(`/vehicles/${id}`));

export const createVehicle = (vehicle: CreateVehicle) =>
    handleRequest<Vehicle>(http.post<Vehicle>("/vehicles", vehicle));

export const updateVehicle = (id: number, vehicle: CreateVehicle) =>
    handleRequest<Vehicle>(http.put<Vehicle>(`/vehicles/${id}`, vehicle));

export const deleteVehicle = (id: number) =>
    handleRequest<void>(http.delete(`/vehicles/${id}`));
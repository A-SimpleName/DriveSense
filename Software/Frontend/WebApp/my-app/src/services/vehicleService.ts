import type { Vehicle } from "../model/vehicle";
import http from "../api/httpService";  
import type { CreateVehicle } from "../model/vehicle";
import { getErrorMessage } from "../errorHandling/getErrorMessage";

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
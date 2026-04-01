import type { Vehicle } from "../model/vehicle";
import http from "../api/httpService";  
import type { CreateVehicle } from "../model/vehicle";

export const getAllVehicles = () => http.get<Vehicle[]>("/vehicles/account");

export const getVehicleById = (id: number) =>
    http.get<Vehicle>(`/vehicles/${id}`);

export const createVehicle = (vehicle: CreateVehicle) =>
    http.post<Vehicle>("/vehicles", vehicle);

export const updateVehicle = (id: number, vehicle: CreateVehicle) =>
    http.put<Vehicle>(`/vehicles/${id}`, vehicle);

export const deleteVehicle = (id: number) =>
    http.delete(`/vehicles/${id}`);
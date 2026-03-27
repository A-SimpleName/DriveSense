import http from "../api/httpService"
import type { Vehicle } from "../model/vehicle";

export const getAllVehicles = () => http.get<Vehicle[]>("/vehicles/");
export const getVehicleById = (id: number) => http.get<Vehicle>(`/vehicles/${id}`);
export const createVehicle = (vehicle: Omit<Vehicle, "id">) => http.post("/vehicles", vehicle);
export const updateVehicle = (id: number, vehicle: Omit<Vehicle, "id">) => http.put(`/vehicles/${id}`, vehicle);
export const deleteVehicle = (id: number) => http.delete(`/vehicles/${id}`);
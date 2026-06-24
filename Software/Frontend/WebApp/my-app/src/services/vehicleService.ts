import type { Vehicle, VehicleMember } from "../model/vehicle";
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
    handleRequest<Vehicle[]>(http.get<Vehicle[]>("/vehicles"));

export const getVehicleById = (id: number) =>
    handleRequest<Vehicle>(http.get<Vehicle>(`/vehicles/${id}`));

export const createVehicle = (vehicle: CreateVehicle) =>
    handleRequest<Vehicle>(http.post<Vehicle>("/vehicles", vehicle));

export const updateVehicle = (id: number, vehicle: CreateVehicle) =>
    handleRequest<Vehicle>(http.put<Vehicle>(`/vehicles/${id}`, vehicle));

export const deleteVehicle = (id: number) =>
    handleRequest<void>(http.delete(`/vehicles/${id}`));

// Mitglieder eines Fahrzeugs laden
export const getVehicleMembers = (vehicleId: number) =>
    handleRequest<VehicleMember[]>(http.get<VehicleMember[]>(`/vehicles/${vehicleId}/members`));

// Mitglied entfernen: OWNER entfernt CO_OWNER/DRIVER, CO_OWNER entfernt nur DRIVER.
// Self-Removal ist hier vom Backend explizit gesperrt – zum Verlassen eines
// Fahrzeugs muss deleteVehicle() genutzt werden (siehe unten).
export const removeVehicleMember = (vehicleId: number, targetProfileId: number) =>
    handleRequest<void>(http.delete(`/vehicles/${vehicleId}/members/${targetProfileId}`));

// Mitgliedsrolle ändern, z.B. DRIVER zu CO_OWNER befördern (nur OWNER darf das).
// Analog zu updateMemberRole bei Gruppen (PUT .../members/{id}/role).
export const updateVehicleMemberRole = (vehicleId: number, targetProfileId: number, newRole: "CO_OWNER" | "DRIVER") =>
    handleRequest<void>(http.put(`/vehicles/${vehicleId}/members/${targetProfileId}/role`, { role: newRole }));

// Einladung per E-Mail verschicken
// role: "CO_OWNER" | "DRIVER" – wird vom Backend gegen die Rolle des Einladers geprüft
export const inviteToVehicle = (vehicleId: number, email: string, role: "CO_OWNER" | "DRIVER") =>
    handleRequest<void>(
        http.post(`/vehicles/${vehicleId}/invitations`, { email, role })
    );

// Einladung annehmen – nur Code nötig, Profil wird automatisch gewählt (wie Group-Flow)
export const acceptVehicleInvite = (code: string) =>
    handleRequest<void>(
        http.post(`/vehicles/invitations/accept`, { code })
    );

// Wird vom Backend zurückgegeben
export interface Vehicle {
    id: number;
    model: string;
    profileName: string;
    licensePlate: string;
    mileage: number;
}

// Wird zum Backend geschickt
export interface CreateVehicle {
    model: string;
    licensePlate: string;
    mileage: number;
}
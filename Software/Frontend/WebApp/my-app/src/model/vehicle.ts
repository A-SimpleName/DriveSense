export interface Vehicle {
    id: number;
    model: string;
    licensePlate: string;
    mileage: number;

    ownerAccountName: string;
    ownerProfileName: string;

    myRole: "OWNER" | "CO_OWNER" | "DRIVER";
}

export interface CreateVehicle {
    model: string;
    licensePlate: string;
    mileage: number;
}
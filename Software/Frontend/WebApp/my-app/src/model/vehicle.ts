export interface Vehicle {
    id: number
    model: string
    licensePlate: string
    mileage: number
    ownerProfileName: string
    ownerAccountName: string
    myRole: "OWNER" | "CO_OWNER" | "DRIVER"
}

export interface CreateVehicle {
    model: string
    licensePlate: string
    mileage: number
}

export interface VehicleMember {
    profileId: number
    profileName: string
    profileRole: string
    accountName: string
    accountEmail: string
    vehicleRole: "OWNER" | "CO_OWNER" | "DRIVER"
}
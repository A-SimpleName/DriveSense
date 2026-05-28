import type { Trackingpoint } from "./trackingpoint";

export interface TripSummary {
    id: number;
    startTime: string; 
    endTime: string;
    distance: number;
    startMileage: number;
    endMileage: number;
    accountFirstName: string;
    accountLastName: string;
    vehicleModel: string;
    licensePlate: string;
    roadSurfaceConditions: string;
    type?: string | null;
    startPoint: string;
    furthestPoint?: string | null;
    endPoint: string;
}

export interface Tripdetailed {
    tripSummary: TripSummary;
    trackingpoints: Trackingpoint[];
}

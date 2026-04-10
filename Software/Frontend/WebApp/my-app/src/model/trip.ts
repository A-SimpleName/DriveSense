import type { Trackingpoint } from "./trackingpoint";

export interface TripSummary {
    id: number;
    startTime: string; 
    endTime: string;
    distance: number;
    startMileage: number;
    endMileage: number;
    accountFname: string;
    accountLname: string;
    licensePlate: string;
    roadSurfaceConditions: string;
    type?: string | null;
    startPoint: string;
    furthestPoint?: string | null;
    endPoint: string;
}

export interface Tripdetailed {
    tripSummary: TripSummary;
    trackingPoints: Trackingpoint[];
}
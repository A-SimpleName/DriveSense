import type { Trackingpoint } from "./trackingpoint";

export interface TripSummaryDto {
    id: number;
    profileId: number;
    vehicleId: number;
    protocolId: number;
    protocolName: string;
    startTime: string; 
    endTime: string;
    accountFname: string;
    accountLname: string;
    vehicleModel: string;
    licensePlate: string;
    distance: number;
    roadSurfaceConditions: string;
    type: string;
    startPoint: string;
    endPoint: string;
    furthestPoint: string;
    startMileage: number;
    endMileage: number;
}


export interface TripSummary {
    id: number;
    profileId: number;
    vehicleId: number;
    protocolId: number;
    startTime: string; 
    endTime: string;
    distance: number;
    roadSurfaceConditions: string;
    type: string;
    startPoint: string;
    endPoint: string;
    furthestPoint: string;
    startMileage: number;
    endMileage: number;
}

export interface Tripdetailed {
    tripSummaryDto: TripSummaryDto;
    trackingpoints: Trackingpoint[];
}
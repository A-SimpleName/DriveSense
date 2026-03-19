export interface TripSummary {
    id: number;
    user_id: number;
    car_id: number;
    startTime: string; 
    endTime: string;
    distance: number;
    roadSurfaceConditions: string;
    type: string;
    startPoint?: string | null;
    endPoint?: string | null;
    furthestPoint?: string | null;
}
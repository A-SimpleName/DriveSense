export interface Trackingpoint {
    id: number;
    tracking_id:number;
    lat: number;
    lng: number;
    accuracy: number;
    speed: number;
    bearing: number;
    timestamp: Date;
}
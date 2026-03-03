export interface  Trip {
    id: number
    user_id: number;
    car_id: number;
    starttime: Date;
    endtime: Date;
    distance: number;
    weather_main: string;
}
export interface Trip {

    protocolId: number;

    roadSurfaceConditions: string;

    // tracking
    starttime: string;
    endtime: string;
    distance: number;
    weatherMain: string;
    type: string;

    // vehicle
    licenseplate: string;

    // driver
    fname: string;
    lname: string;

    // role
    userRole: string;

    // route
    startPoint: string;
    furthestPoint: string;
    endPoint: string;
}
import type { TripSummary } from "./trip";

export interface Protocol {
    id: number;
    created_by_profile_id: number;
    usergroup_id: number;
    created_at: string;
    name: string;
    trips: TripSummary[];
}
import type { AccountResponse } from "./account";
import type { TripSummary } from "./trip";
import type { UserGroup } from "./usergroup";

export interface Protocol {
    id: number;
    created_by_account: AccountResponse;
    usergroup: UserGroup;
    created_at: string;
    name: string;
    protocolRole: string;
    trips: TripSummary[];
}

export interface ProtocolCreateRequest {
    name: string;
}
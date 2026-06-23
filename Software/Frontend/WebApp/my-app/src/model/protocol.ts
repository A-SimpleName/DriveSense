import type { AccountResponse } from "./account";
import type { TripSummaryDto } from "./trip";
import type { UserGroup } from "./usergroup";

export interface ProtocolDetail {
    id: number;
    created_by_account: AccountResponse;
    usergroup: UserGroup | null;
    created_at: string;
    name: string;
    protocolRole: string;
    trips: TripSummaryDto[];
}

export interface Protocol {
    id: number;
    created_by_profileId: number;
    usergroupId: number | null;
    created_at: string;
    name: string;
}

export interface ProtocolCreateRequest {
    name: string;
    usergroupId: number | null;
}

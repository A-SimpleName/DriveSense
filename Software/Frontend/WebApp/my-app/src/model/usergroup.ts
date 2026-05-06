export interface UserGroup {
    id: number;
    name: string;
    owner : string;
    ownerId: number;
}
export interface GroupMember {
    profileId: number;
    name: string;
    groupRole: "OWNER" | "ADMIN" | "MEMBER";
}
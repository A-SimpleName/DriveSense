export interface UserGroup {
    id: number;
    name: string;
    Owner: string;
}
export interface GroupMember {
    profileId: number;
    name: string;
    groupRole: "OWNER" | "MEMBER";
}
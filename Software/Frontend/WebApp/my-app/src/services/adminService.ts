import http from "../api/httpService";
import { toAppError } from "../errorHandling/errorHandling";
import type { AccountResponse } from "../model/account";
import type { Profile } from "../model/profile";
import type { UserGroup, GroupMember } from "../model/usergroup";

async function handleRequest<T>(request: Promise<T>): Promise<T> {
    try {
        return await request;
    } catch (err: any) {
        throw toAppError(err);
    }
}

export const adminGetAllAccounts = () => handleRequest(http.get<AccountResponse[]>("/admin/accounts"));
export const adminDeleteAccount = (id: number) => handleRequest(http.delete(`/admin/accounts/${id}`));

export const adminGetAllProfiles = () => handleRequest(http.get<Profile[]>("/admin/profiles"));
export const adminDeleteProfile = (id: number) => handleRequest(http.delete(`/admin/profiles/${id}`));

export const adminGetAllGroups = () => handleRequest(http.get<UserGroup[]>("/admin/groups"));
export const adminDeleteGroup = (id: number) => handleRequest(http.delete(`/admin/groups/${id}`));
export const adminGetGroupMembers = (groupId: number) => handleRequest(http.get<GroupMember[]>(`/admin/groups/${groupId}/members`));
export const adminRemoveMember = (groupId: number, profileId: number) => handleRequest(http.delete(`/admin/groups/${groupId}/members/${profileId}`));
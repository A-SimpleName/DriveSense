import http from "../api/httpService";
import type { AccountResponse } from "../model/account";
import type { Profile } from "../model/profile";
import type { UserGroup, GroupMember } from "../model/usergroup";

export const adminGetAllAccounts = () => http.get<AccountResponse[]>("/admin/accounts");
export const adminDeleteAccount = (id: number) => http.delete(`/admin/accounts/${id}`);

export const adminGetAllProfiles = () => http.get<Profile[]>("/admin/profiles");
export const adminDeleteProfile = (id: number) => http.delete(`/admin/profiles/${id}`);

export const adminGetAllGroups = () => http.get<UserGroup[]>("/admin/groups");
export const adminDeleteGroup = (id: number) => http.delete(`/admin/groups/${id}`);
export const adminGetGroupMembers = (groupId: number) => http.get<GroupMember[]>(`/admin/groups/${groupId}/members`);
export const adminRemoveMember = (groupId: number, profileId: number) => http.delete(`/admin/groups/${groupId}/members/${profileId}`);
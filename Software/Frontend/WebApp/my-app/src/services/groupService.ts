import http from "../api/httpService";
import type { GroupMember, UserGroup } from "../model/usergroup";

export const getGroups = () => http.get<UserGroup[]>("/groups");
export const getGroupById = (id: number) => http.get<UserGroup>(`/groups/${id}`);
export const getGroupMembers = (id: number) => http.get<GroupMember[]>(`/groups/${id}/members`);
export const deleteMember = (groupId: number, profileId: number) => http.delete(`/groups/${groupId}/members/${profileId}`);
export const updateMemberRole = (groupId: number, profileId: number, newRole: string) => http.put(`/groups/${groupId}/members/${profileId}/role`, { groupRole: newRole });
export const createGroup = (name: string) => http.post<UserGroup>("/groups", { name });
export const updateGroup = (id: number, name: string) => http.put(`/groups/${id}`, { name });
export const deleteGroup = (id: number) => http.delete(`/groups/${id}`);
export const inviteMember = (groupId: number, email: string) => http.post(`/groups/${groupId}/invite`, { email });
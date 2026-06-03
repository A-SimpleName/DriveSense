import http from "../api/httpService";
import { toAppError } from "../errorHandling/errorHandling";
import type { Profile } from "../model/profile";
import type { GroupMember, UserGroup } from "../model/usergroup";

async function handleRequest<T>(request: Promise<T>): Promise<T> {
    try {
        return await request;
    } catch (err: any) {
        throw toAppError(err);
    }
}

export const getGroups = () => handleRequest(http.get<UserGroup[]>("/groups"));
export const getGroupById = (id: number) => handleRequest(http.get<UserGroup>(`/groups/${id}`));
export const getGroupMembers = (id: number) => handleRequest(http.get<GroupMember[]>(`/groups/${id}/members`));
export const deleteMember = (groupId: number, profileId: number) => handleRequest(http.delete(`/groups/${groupId}/members/${profileId}`));
export const updateMemberRole = (groupId: number, profileId: number, newRole: string) => handleRequest(http.put(`/groups/${groupId}/members/${profileId}/role`, { role: newRole }));
export const createGroup = (name: string) => handleRequest(http.post<UserGroup>("/groups", { name }));
export const updateGroup = (id: number, name: string) => handleRequest(http.put(`/groups/${id}`, { name }));
export const deleteGroup = (id: number) => handleRequest(http.delete(`/groups/${id}`));
export const inviteMember = (groupId: number, email: string) => handleRequest(http.post(`/groups/${groupId}/invite`, { email }));
export const verifyInvite = (code: string) => handleRequest(http.post<Profile[]>(`/groups/verify-invite`, { code }));
export const acceptInvite = (code: string, profileId: number) => handleRequest(http.post<void>(`/groups/accept-invite`, { code, profileId }));
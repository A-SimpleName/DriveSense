import http from "../api/httpService";
import type { GroupMember, UserGroup } from "../model/usergroup";

export const getGroups = () => http.get<UserGroup[]>("/groups");
export const getGroupById = (id: number) => http.get<UserGroup>(`/groups/${id}`);
export const getGroupMembers = (id: number) => http.get<GroupMember[]>(`/groups/${id}/members`);
export const createGroup = (group: Omit<UserGroup, "id">) => http.post("/groups", group);
export const updateGroup = (id: number, group: Omit<UserGroup, "id">) => http.put(`/groups/${id}`, group);
export const deleteGroup = (id: number) => http.delete(`/groups/${id}`);


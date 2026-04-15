import http from "../api/httpService";
import type { UserGroup } from "../model/usergroup";

export const getGroups = () => http.get<UserGroup[]>("/groups");
export const getGroupById = (id: number) => http.get<UserGroup>(`/groups/${id}`);
export const createGroup = (group: Omit<UserGroup, "id">) => http.post("/groups", group);
export const updateGroup = (id: number, group: Omit<UserGroup, "id">) => http.put(`/groups/${id}`, group);
export const deleteGroup = (id: number) => http.delete(`/groups/${id}`);


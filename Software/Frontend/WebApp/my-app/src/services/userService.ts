import http from "../api/httpService";
import type { Profile } from "../model/profile";

export const getAllProfiles = () => http.get<Profile[]>("/profiles");
export const getProfileById = (id: number) => http.get<Profile>(`/profiles/${id}`);
export const createProfile = (profile: Omit<Profile, "id">) => http.post("/profiles", profile);
export const updateProfile = (id: number, profile: Omit<Profile, "id">) => http.put(`/profiles/${id}`, profile);
export const deleteProfile = (id: number) => http.delete(`/profiles/${id}`);

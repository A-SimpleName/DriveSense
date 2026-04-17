import http from "../api/httpService";
import type { Profile } from "../model/profile";

export const getCurrentProfile = async (): Promise<Profile> => {
  return await http.get<Profile>("/profiles/me")
};

export const getProfilesByAccount = async (): Promise<Profile[]> => {
  return await http.get<Profile[]>("/profiles/byAccount");
};

export const createProfile = (profile: Omit<Profile, "id" | "account_id">) =>
  http.post<Profile>("/profiles", profile);

export const updateProfile = (id: number, profile: Omit<Profile, "id" | "account_id">) =>
  http.put<Profile>(`/profiles/${id}`, profile);

export const deleteProfile = (id: number) =>
  http.delete<void>(`/profiles/${id}`);

export const getProfileById = (id: number) =>
  http.get<Profile>(`/profiles/${id}`);
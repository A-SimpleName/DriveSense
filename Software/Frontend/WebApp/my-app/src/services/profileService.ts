
import http from "../api/httpService";
import { tokenService } from "./tokenService";
import type { Profile } from "../model/profile";

const getAuthHeader = () => ({
  Authorization: `Bearer ${tokenService.getAccountToken()}`,
  "Content-Type": "application/json",
});

export const getProfilesByAccount = () =>
  http.get<Profile[]>("/profiles/byAccount", getAuthHeader());

export const createProfile = (profile: Omit<Profile, "id" | "account_id">) =>
  http.post<Profile>("/profiles", profile, getAuthHeader());

export const updateProfile = (id: number, profile: Omit<Profile, "id" | "account_id">) =>
  http.put<Profile>(`/profiles/${id}`, profile, getAuthHeader());

export const deleteProfile = (id: number) =>
  http.delete<void>(`/profiles/${id}`, getAuthHeader());

export const getProfileById = (id: number) =>
  http.get<Profile>(`/profiles/${id}`, getAuthHeader());
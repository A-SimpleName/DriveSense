import http from "../api/httpService";
import { toAppError } from "../errorHandling/errorHandling";
import type { Profile } from "../model/profile";

async function handleRequest<T>(request: Promise<T>): Promise<T> {
    try {
        return await request;
    } catch (err: any) {
        throw toAppError(err);
    }
}


export const getCurrentProfile = async (): Promise<Profile> => {
  return await handleRequest<Profile>(http.get<Profile>("/profiles/me"));
};

export const getProfilesByAccount = async (): Promise<Profile[]> => {
  return await handleRequest<Profile[]>(http.get<Profile[]>("/profiles/byAccount"));
};

export const createProfile = (profile: Omit<Profile, "id" | "account_id">) =>
  handleRequest<Profile>(http.post<Profile>("/profiles", profile));

export const updateProfile = (id: number, profile: Omit<Profile, "id" | "account_id">) =>
  handleRequest<Profile>(http.put<Profile>(`/profiles/${id}`, profile));

export const deleteProfile = (id: number) =>
  handleRequest<void>(http.delete<void>(`/profiles/${id}`));

export const getProfileById = (id: number) =>
  handleRequest<Profile>(http.get<Profile>(`/profiles/${id}`));
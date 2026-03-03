import http from "../api/httpService";
import type { User } from "../model/user";

export const getAllUsers = () => http.get<User[]>("/users");
export const getUserById = (id: number) => http.get<User>(`/users/${id}`);
export const createUser = (user: Omit<User, "id">) => http.post("/users", user);
export const updateUser = (id: number, user: Omit<User, "id">) => http.put(`/users/${id}`, user);
export const deleteUser = (id: number) => http.delete(`/users/${id}`);
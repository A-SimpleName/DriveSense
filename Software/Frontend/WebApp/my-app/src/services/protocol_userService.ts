import http from "./httpService";
import type { Protocol_user } from "../model/protocol_user";

export const getAllProtocolUsers = () => http.get<Protocol_user[]>("/protocol_users");
export const getProtocolUserById = (protocol_id: number, user_id: number) => http.get<Protocol_user>(`/protocol_users/${protocol_id}/${user_id}`);
export const createProtocolUser = (protocolUser: Protocol_user) => http.post("/protocol_users", protocolUser);
export const updateProtocolUser = (protocol_id: number, user_id: number, protocolUser: Protocol_user) => http.put(`/protocol_users/${protocol_id}/${user_id}`, protocolUser);
export const deleteProtocolUser = (protocol_id: number, user_id: number) => http.delete(`/protocol_users/${protocol_id}/${user_id}`);
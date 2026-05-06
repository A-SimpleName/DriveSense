import http from "../api/httpService"
import type { Protocol, ProtocolCreateRequest, ProtocolDetail } from "../model/protocol"

export const getAllProtocols = () => http.get<Protocol[]>("/protocols");
export const exportProtocol = (id: number) =>
  http.getBlob<{ blob: Blob; filename?: string }>(`/export/${id}`);
export const getProtocolById = (id: number) => http.get<Protocol>(`/protocols/${id}`);
export const getProtocolByIdWithTrips = (id: number) => http.get<ProtocolDetail>(`/protocols/${id}/with-trips`);
export const createProtocol = (protocol: ProtocolCreateRequest) => http.post("/protocols", protocol);
export const updateProtocol = (id: number, protocol: Omit<Protocol, "id">) => http.put(`/protocols/${id}`, protocol);
export const deleteProtocol = (id: number) => http.delete(`/protocols/${id}`);
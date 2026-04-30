import http from "../api/httpService"
import type { Protocol } from "../model/protocol"

export const getAllProtocols = () => http.get<Protocol[]>("/protocols");
export const exportProtocol = (id: number) =>
  http.getBlob<{ blob: Blob; filename?: string }>(`/export/${id}`);
export const getProtocolById = (id: number) => http.get<Protocol>(`/protocols/${id}`);
export const createProtocol = (protocol: Omit<Protocol, "id">) => http.post("/protocols", protocol);
export const updateProtocol = (id: number, protocol: Omit<Protocol, "id">) => http.put(`/protocols/${id}`, protocol);
export const deleteProtocol = (id: number) => http.delete(`/protocols/${id}`);
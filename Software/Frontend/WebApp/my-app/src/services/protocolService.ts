import http from "../api/httpService"
import { toAppError } from "../errorHandling/errorHandling";
import type { Protocol, ProtocolCreateRequest, ProtocolDetail } from "../model/protocol"

async function handleRequest<T>(request: Promise<T>): Promise<T> {
    try {
        return await request;
    } catch (err: any) {
        throw toAppError(err);
    }
}

export const getAllProtocols = () => handleRequest<Protocol[]>(http.get<Protocol[]>("/protocols"));
export const exportProtocol = (id: number) =>
  handleRequest<{ blob: Blob; filename?: string }>(http.getBlob<{ blob: Blob; filename?: string }>(`/export/${id}`));
export const getProtocolById = (id: number) => handleRequest<Protocol>(http.get<Protocol>(`/protocols/${id}`));
export const getProtocolByIdWithTrips = (id: number) => handleRequest<ProtocolDetail>(http.get<ProtocolDetail>(`/protocols/${id}/with-trips`));
export const createProtocol = (protocol: ProtocolCreateRequest) => handleRequest<Protocol>(http.post("/protocols", protocol));
export const updateProtocol = (id: number, protocol: Omit<Protocol, "id">) => handleRequest<Protocol>(http.put(`/protocols/${id}`, protocol));
export const deleteProtocol = (id: number) => handleRequest<void>(http.delete(`/protocols/${id}`));

import { apiFetch } from "./api-token";

export const BASE_URL = "/api";

type ResponseType = "json" | "blob";

export type BlobResponse = {
  blob: Blob;
  filename?: string;
};

async function request<T>(
  endpoint: string,
  method: string = "GET",
  data?: any,
  responseType: ResponseType = "json"
): Promise<T> {
  const options: RequestInit = {
    method,
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
    },
  };

  if (data) {
    options.body = JSON.stringify(data);
  }

  const response = await apiFetch(`${BASE_URL}${endpoint}`, options);

  if (!response.ok) {
    const errorBody = await response.json().catch(() => ({}));
    const err: any = new Error(errorBody?.message || "HTTP error");
    err.errors = errorBody?.errors || null;
    throw err;
  }

  if (responseType === "blob") {
    const blob = await response.blob();

    const contentDisposition = response.headers.get("content-disposition");

    let filename: string | undefined;

    if (contentDisposition) {
      const match = contentDisposition.match(/filename="(.+)"/);
      if (match?.[1]) filename = match[1];
    }

    return {
      blob,
      filename,
    } as unknown as T;
  }

  const contentLength = response.headers.get("content-length");
  const contentType = response.headers.get("content-type") || "";

  if (contentLength === "0" || !contentType.includes("application/json")) {
    return undefined as unknown as T;
  }

  return (await response.json()) as T;
}

export default {
  get: <T>(endpoint: string) =>
    request<T>(endpoint, "GET"),

  post: <T>(endpoint: string, data: any) =>
    request<T>(endpoint, "POST", data),

  put: <T>(endpoint: string, data: any) =>
    request<T>(endpoint, "PUT", data),

  delete: <T>(endpoint: string) =>
    request<T>(endpoint, "DELETE"),

  getBlob: <T = BlobResponse>(endpoint: string) =>
    request<T>(endpoint, "GET", undefined, "blob"),
};
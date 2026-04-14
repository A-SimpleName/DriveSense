import { apiFetch } from "./api-token";

const BASE_URL = "http://localhost:8080/api";

async function request<T>(
  endpoint: string,
  method: string = "GET",
  data?: any
): Promise<T> {
  const options: RequestInit = {
    method,
    headers: {
      "Content-Type": "application/json",
    }
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

  const contentLength = response.headers.get("content-length");
  const contentType = response.headers.get("content-type") || "";
  if (contentLength === "0" || !contentType.includes("application/json")) {
    return undefined as unknown as T;
  }

  return response.json() as Promise<T>;
}

export default {
  get: <T>(endpoint: string) => request<T>(endpoint, "GET"),
  post: <T>(endpoint: string, data: any) => request<T>(endpoint, "POST", data),
  put: <T>(endpoint: string, data: any) => request<T>(endpoint, "PUT", data),
  delete: <T>(endpoint: string) => request<T>(endpoint, "DELETE"),
};
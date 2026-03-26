const BASE_URL = "http://localhost:8080/api";

async function request<T>(endpoint: string, method: string = "GET", data?: any, headers?: Record<string, string>): Promise<T> {
    const options: RequestInit = { method, headers: { "Content-Type": "application/json", ...headers } };
    if (data) options.body = JSON.stringify(data);

    const response = await fetch(`${BASE_URL}${endpoint}`, options);
    if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
    return response.json() as Promise<T>;
}

export default {
    get: <T>(endpoint: string, headers?: Record<string, string>) => request<T>(endpoint, "GET", undefined, headers),
    post: <T>(endpoint: string, data: any, headers?: Record<string, string>) => request<T>(endpoint, "POST", data, headers),
    put: <T>(endpoint: string, data: any, headers?: Record<string, string>) => request<T>(endpoint, "PUT", data, headers),
    delete: <T>(endpoint: string, headers?: Record<string, string>) => request<T>(endpoint, "DELETE", undefined, headers),
};
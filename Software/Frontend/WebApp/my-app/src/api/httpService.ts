const BASE_URL = "http://localhost:8080/api";

async function request<T>(
  endpoint: string,
  method: string = "GET",
  data?: any
): Promise<T> {
  const options: RequestInit = {
    method,
    credentials: "include",
    headers: {
      "Content-Type": "application/json"
    }
  };

  if (data) {
    options.body = JSON.stringify(data);
  }

  const response = await fetch(`${BASE_URL}${endpoint}`, options);

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  return response.json() as Promise<T>;
}

export default {
  get: <T>(endpoint: string) => request<T>(endpoint, "GET"),
  post: <T>(endpoint: string, data: any) => request<T>(endpoint, "POST", data),
  put: <T>(endpoint: string, data: any) => request<T>(endpoint, "PUT", data),
  delete: <T>(endpoint: string) => request<T>(endpoint, "DELETE"),
};
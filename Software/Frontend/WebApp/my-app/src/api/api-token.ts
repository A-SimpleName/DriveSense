import { BASE_URL } from "./httpService";
export async function apiFetch(url: string, options: RequestInit = {}) {
  const headers = {
    ... (options.headers || {}),
    "X-Client-Type": "web"
  } as Record<string, string>;

  let res = await fetch(url, {
    ...options,
    headers,
    credentials: "include"
  });
 
  if (res.status === 401) {
     const refreshRes = await fetch(
      `${BASE_URL}/account/refresh`,
      {
        method: "POST",
        credentials: "include",
      }
    );
 
    if (!refreshRes.ok) {
      throw new Error("Session abgelaufen");
    }
 
    // Retry mit neuem Cookie
    res = await fetch(url, {
      ...options,
      credentials: "include"
    });
  }
 
  return res;
}
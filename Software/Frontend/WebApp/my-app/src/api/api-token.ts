export async function apiFetch(url: string, options: RequestInit = {}) {
  let res = await fetch(url, {
    ...options,
    credentials: "include"
  });

  if (res.status === 401 || res.status === 403 || res.status === 500) {
    const refreshRes = await fetch("http://localhost:8080/api/account/refresh", {
      method: "POST",
      credentials: "include"
    });

    if (!refreshRes.ok) {
      throw new Error("Session abgelaufen");
    }

    res = await fetch(url, {
      ...options,
      credentials: "include"
    });
  }

  return res;
}
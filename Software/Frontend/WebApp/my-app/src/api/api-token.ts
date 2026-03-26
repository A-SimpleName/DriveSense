import { tokenService } from "../services/tokenService";
import { refresh,logout } from "../services/auth";

export async function apiFetch(url: string, options: RequestInit = {}) {
  let token = tokenService.getAccessToken();

  let res = await fetch(url, {
    ...options,
    headers: {
      ...(options.headers || {}),
      Authorization: `Bearer ${token}`
    }
  });

  // 🔁 AUTO REFRESH
  if (res.status === 401) {
    try {
      await refresh();

      token = tokenService.getAccessToken();

      res = await fetch(url, {
        ...options,
        headers: {
          ...(options.headers || {}),
          Authorization: `Bearer ${token}`
        }
      });
    } catch (e) {
      logout();
      throw e;
    }
  }

  return res;
}
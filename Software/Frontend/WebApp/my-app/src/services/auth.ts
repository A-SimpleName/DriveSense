import { tokenService } from "./tokenService";

const BASE_URL = "http://localhost:8080/api";

export async function login(email: string, password: string) {
  const res = await fetch(`${BASE_URL}/account/login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ email, password })
  });

  if (!res.ok) throw new Error("Login fehlgeschlagen");

  const data = await res.json();

  tokenService.setTokens({
    accountToken: data.accountToken,
    refreshToken: data.refreshToken
  });

  return data;
}

export async function selectProfile(profileId: number) {
  const token = tokenService.getAccountToken();

  const res = await fetch(
    `${BASE_URL}/account/select-profile?profileId=${profileId}`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`
      }
    }
  );

  if (!res.ok) throw new Error("Profil Auswahl fehlgeschlagen");

  const data = await res.json();

  tokenService.setTokens({
    profileToken: data.profileToken
  });

  return data;
}

export async function signUp(fname: string, lname: string, email: string, password: string) {
  const res = await fetch(`${BASE_URL}/account/register`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ fname, lname, email, password })
  });

  if (!res.ok) throw new Error("Registrierung fehlgeschlagen");

  return await res.json();
}

export async function refresh() {
  const refreshToken = tokenService.getRefreshToken();

  if (!refreshToken) {
    tokenService.clear();
    throw new Error("Kein Refresh Token");
  }

  const res = await fetch(`${BASE_URL}/account/refresh`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ refreshToken })
  });

  if (!res.ok) {
    tokenService.clear();
    throw new Error("Session abgelaufen");
  }

  const data = await res.json();

  tokenService.setTokens({
    accountToken: data.accountToken,
    profileToken: data.profileToken,
    refreshToken: data.refreshToken
  });

  return data;
}

export function logout() {
  tokenService.clear();
}

export function hasProfile() {
  return !!localStorage.getItem("profileToken");
}

export function isAuthenticated() {
  return !!localStorage.getItem("accountToken");
}
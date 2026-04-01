import { tokenService } from "./tokenService";

const BASE_URL = "http://localhost:8080/api";

export async function login(email: string, password: string) {
  const res = await fetch("http://localhost:8080/api/account/login", {
    method: "POST",
    credentials: "include",
    headers: {
      "Content-Type": "application/json"
      
    },
    body: JSON.stringify({ email, password })
  });
  console.log("Login Response:", res);
  if (!res.ok) throw new Error("Login fehlgeschlagen");

  return res.json();
}

export async function selectProfile(profileId: number) {
  const token = tokenService.getAccountToken();
  console.log("Account Token:", token);

  const res = await fetch(
    `${BASE_URL}/account/select-profile?profileId=${profileId}`,
    {
      method: "POST",
      credentials: "include",
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
  console.log(tokenService.getAccessToken());
  return data;
}

export async function signUp(fname: string, lname: string, email: string, password: string, birthdate: string) {
  const res = await fetch(`${BASE_URL}/account/signUp`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ fname, lname, email, password, birthdate })
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
    credentials: "include", // 🔥 HIER HINZUFÜGEN
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